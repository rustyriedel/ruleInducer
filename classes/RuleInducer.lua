--RuleInducer class

RuleInducer = {}
RuleInducer.__index = RuleInducer

--constructor
function RuleInducer:new()
   local o = {
      numAttributes = 0,
      numCases = 0,
      cases = {},
      attributeNames = {},
      decisionName = "none",

      av = {},
      concepts = {},
      Dstar = {},
      Astar = {}, 
      avBlocks = {},

      coverage = {},
      needsDescritization = {},
      ranges = {},
      
      kSets = {},
      
      outputFile = "",
      ruleType = 0,
      hasMissingValues = false
   }
   setmetatable(o, self)
   return o
end

function RuleInducer:run()
   self:getAttributeValues()
   
   self:calcAstar()
   self:calcDstar()
   
   self:calcAVBlocks()   
   self:calcCharacteristicSets()
   
   
   --if hasMissingValues flag is false, no need to do
   --an approx if the data set is consistant
   local con = self:isDataSetConsistant()
   if(self.hasMissingValues == true or con == false) then
      --compute certain or possible rules based on input
      if(self.ruleType == '1') then
         --calculate lower approximations for certain rues
         self:calcLowerConceptApprox()
      else
         --calculate upper approximations for possible rules
         self:calcUpperConceptApprox()
      end
   end
   
   --run the LEM2 algorithm to induce rules and output them to a file
   self:induceRules()
end

function RuleInducer:parseData()
   local fileParser = Parser:new()
   fileParser:parse()
   
   --add the needed values from the parser to the RuleInducer class
   self.numAttributes = fileParser.numAttributes
   self.numCases = #fileParser.cases
   self.attributeNames = fileParser.attributeNames
   self.decisionName = fileParser.decisionName
   self.cases = fileParser.cases
   self.needsDescritization = fileParser.needsDescritization
   self.outputFile = fileParser.outputFilePath
   self.ruleType = fileParser.ruleType
   self.hasMissingValues = fileParser.hasMissingValues
   
   --descritize the data set if needed
   self:descritize()
end

function RuleInducer:getAttributeValues()
   --add each attribute
   for k, v in pairs(self.attributeNames) do
      --add a subtable for each attribute
      self.av[v] = {}

      --add ranges as a,v pairs if the attribute was descritized
      if(self.needsDescritization[k]) then
         for m, n in pairs(self.ranges) do
            if(n.attr == k) then
               self.av[v][m] = true
            end
         end
      else
         --enter each value for its respective attribute
         for i = 1, self.numCases do
            local temp = self.cases[i][k]
            if(temp ~= "*" and temp ~= "?" and temp ~= "-") then
               self.av[v][temp] = true
            end
         end
      end
   end

   --add all the concepts to the concept table
   for i = 1, self.numCases do
      local temp = self.cases[i][self.numAttributes + 1]
      self.concepts[temp] = true
   end
end

--only needs to be computed if the data set is inconsistant
function RuleInducer:calcCharacteristicSets()
   --create a universal set
   local U = Set:new()
   for i = 1, self.numCases do
      U:insert(i)
   end
   
   --compute a characteristic set for each case
   for k, v in ipairs(self.cases) do
      local toIntersect = {}
      for i = 1, self.numAttributes do
         if(v[i] == "?" or v[i] == "*") then
            --for ? and * k(x,a) = U
            table.insert(toIntersect, U)
         elseif(v[i] == "-") then
            --if V(x,a) = empty set, insert U, otherwise U[(a,v)]
            local V = self:calcValue(k, i)
            --calcValue returns a ? if the set is empty, so insert U
            if(V == "?") then
               table.insert(toIntersect, U)
            else
               --U[(a,v)] in the table V
               local result = Set:new()
               for m, n in pairs(V) do
                  if(type(n) == "number") then
                     --get the ranges each number is in an U[(a,v)]
                     local attr = self.attributeNames[i]
                     for o, p in pairs(self.avBlocks[attr]) do
                        local range = self.ranges[o]
                        if(n >= range.low and n <= range.high) then
                           result = result:union(self.avBlocks[attr][o])
                        end
                     end
                  else
                     local set = self.avBlocks[self.attributeNames[i]][n]
                     result = result:union(set)
                  end
               end
               table.insert(toIntersect, result)
            end
         elseif(type(v[i]) == "number") then
            --find all the [(a,v)] block ranges that it fits in
            local attr = self.attributeNames[i]
            local set = Set:new()
            for m, n in pairs(self.avBlocks[attr]) do
               local range = self.ranges[m]
               if(v[i] >= range.low and v[i] <= range.high) then
                  if(set:cardinality() == 0) then
                     set = set:union(self.avBlocks[attr][m])
                  else
                     set = set:intersect(self.avBlocks[attr][m])
                  end
               end
            end
            table.insert(toIntersect, set)
         else
            --non missing value, just add the [(a,v)] to the table
            local attr = self.attributeNames[i]
            table.insert(toIntersect, self.avBlocks[attr][v[i]])
         end
      end
      
      --compute the k set intersections
      self.kSets[k] = Set:new()
      self.kSets[k] = self.kSets[k]:union(toIntersect[1])
      for i = 2, self.numAttributes do
         self.kSets[k] = self.kSets[k]:intersect(toIntersect[i])
      end
   end
end

--creates lower concept approximations for certain rules
function RuleInducer:calcLowerConceptApprox()
   --save the concepts for the approximations
   local oldGoals = clone(self.Dstar)
   
   --clear the Dstar table
   self.Dstar = {}
   
   --compute lower concept approximations 
   for k, v in pairs(oldGoals) do
      local goal = Set:new()
      
      --compute the lower approximations from the characteristic sets
      --if KA(x) is a subset of the concept, U[KA(x)] = lower approx
      for m, n in ipairs(self.kSets) do
         if(n:subset(v)) then
            goal = goal:union(n)
         end
      end
      
      --insert the approximations into Dstar
      self.Dstar[k] = goal
   end
end

function RuleInducer:calcUpperConceptApprox()
   --save the concepts for the approximations
   local oldGoals = clone(self.Dstar)
   
   --clear the Dstar table
   self.Dstar = {}

   --compute upper concept approximations 
   for k, v in pairs(oldGoals) do
      local goal = Set:new()
      
      --compute the lower approximations from the characteristic sets
      --for each element x in the set goal = U[KA(x)]
      for m, n in pairs(v.data) do
         goal = goal:union(self.kSets[m])
      end
      
      --insert the approximations into Dstar
      self.Dstar[k] = goal
   end
   
end

function RuleInducer:calcAstar()
   local countedCase = {}
   local currCase = 1
   local equalFlag = true

   --create the partitions for each concept in A*
   while currCase <= self.numCases do
      self.Astar[currCase] = Set:new()

      --insert the first case
      self.Astar[currCase]:insert(currCase)
      countedCase[currCase] = true

      --check if any other cases are in the same set
      for i = currCase, self.numCases do

         --check if each case is the same and add it to the set
         --check if case i has already been added
         if(countedCase[i] ~= true) then
            --i not added, check for equality with currCase
            for j = 1, self.numAttributes do
               if(self.cases[i][j] ~= self.cases[currCase][j]) then
                  equalFlag = false
                  break
               end
            end

            --if the flag is true then the cases matched, add i
            if(equalFlag == true) then
               self.Astar[currCase]:insert(i)
               countedCase[i] = true
            else
               equalFlag = true
            end
         end

      end

      --get the next case that is not already in a set
      for k,v in ipairs(countedCase) do
         currCase = k + 1
      end

   end--end while
end

function RuleInducer:calcDstar()
   --create the partitions for each concept in {d}*
   for k, v in pairs(self.concepts) do
      self.Dstar[k] = Set:new()
      self.coverage[k] = false

      --add each case to {d}*
      for i = 1, self.numCases do
         if(self.cases[i][self.numAttributes + 1] == k) then
            self.Dstar[k]:insert(i)
         end
      end
   end
end

function RuleInducer:isDataSetConsistant()
   for k, v in pairs(self.Astar) do
      local flag = false
      for m, n in pairs(self.Dstar) do
         if(v:subset(n)) then
            flag = true
         end
      end
      
      --check if the current partition of A* is a 
      --subset of a partition in {d}*
      if(flag == false) then
         return false
      end
   end
   
   return true
end

function RuleInducer:calcAVBlocks()
   --build avBlocks sets for the each av pair
   for k, v in pairs(self.av) do
      self.avBlocks[k] = {}
      for m, n in pairs(self.av[k]) do
         self.avBlocks[k][m] = Set:new()
      end
   end

   --fill each av block
   for i = 1, self.numCases do
      for j = 1, self.numAttributes do
         local attr = self.attributeNames[j]
         --local val = self.cases[i][j]
         local val = self:calcValue(i, j)
         
         --if the value is a number, insert it into each appropriate
         --[(a,v)] block if it fits into the range
         if(type(val) == "number") then
            --get a range
            for k, v in pairs(self.ranges) do
               --check if that range is for the current attribute
               if(v.attr == j) then
                  --check if the value fits in the range
                  if(val >= v.low and val <= v.high) then
                     self.avBlocks[attr][k]:insert(i)
                  end
               end
            end
         elseif(type(val) == "table") then
            --* and - values will return a table, so add each
            --value in the table to its appropriate set
            for k, v in pairs(val) do
               if(type(v) == "number") then
                  --get a range
                  for m, n in pairs(self.ranges) do
                     --check if that range is for the current attribute
                     if(n.attr == j) then
                        --check if the value fits in the range
                        if(v >= n.low and v <= n.high) then
                           self.avBlocks[attr][m]:insert(i)
                        end
                     end
                  end
               else
                  self.avBlocks[attr][v]:insert(i)
               end
            end
         elseif(val == "?") then
            --lost data so disregard, dont enter it anywhere.
         else
            --symbolic value so enter it into the appropriate set
            self.avBlocks[attr][val]:insert(i)
         end
      end
   end
end

function RuleInducer:calcValue(pCase, pAttribute)
   local value = self.cases[pCase][pAttribute]
   if(value ~= "*" and value ~= "-") then
      --if symbolic, numeric, or lost data (?) simply return value
      return value
   elseif(value == "*") then
      --dont care value, return a table of all values in the attribute
      local dontCare = {}
      local attr = self.attributeNames[pAttribute]
      for k, v in pairs(self.av[attr]) do
         table.insert(dontCare, k)
      end
      return dontCare
   else
      --attibute concept value (-), must vote on what the proper
      --value(s) to return in a table
      local attributeConcept = {}
      local votes = {}
      local concept = self.cases[pCase][self.numAttributes + 1]
      
      for k, v in pairs(self.Dstar[concept].data) do
         -- k = case in the concept
         local vote = self.cases[k][pAttribute]
         if(vote ~= "-" and vote ~= "?") then
            if(votes[vote] == nil) then
               votes[vote] = 1
            else
               votes[vote] = votes[vote] + 1
            end
         end
      end
      
      --check which vote wins, if multiple tie, add the ties
      --find the most popular vote
      local popular = 0
      for k, v in pairs(votes) do
         if(v > popular) then
            popular = v
         end
      end
      
      --nobody voted (- is the only value in the concept)
      --return a ? so it is not added
      if(popular == 0) then
         return "?"
      end
      
      --fill the attributeConcept table with the popular values
      for k, v in pairs(votes) do
         if(v == popular) then
            --if * is a popular value, enter all values and break
            if(k == "*") then
               local attr = self.attributeNames[pAttribute]
               for m, n in pairs(self.av[attr]) do
                  table.insert(attributeConcept, m)
               end
               break
            end
            --enter all the popular values
            table.insert(attributeConcept, k)
         end
      end
      
      --return the values for -
      return attributeConcept
   end
end

function RuleInducer:printAttributeValues()
   --print out the set of values for each attribute
   for k, v in pairs(self.av) do
      io.write(k .. " { ")
      for m, n in pairs(self.av[k]) do
         io.write(m .. ", ")
      end
      io.write("}\n")
   end

   --print out the set of concepts
   io.write(self.decisionName .. " { ")
   for k, v in pairs(self.concepts) do
      io.write(k .. ", ")
   end
   io.write("}\n")
end

function RuleInducer:printAVBlocks()
   --print out the set of values for each attribute
   for k, v in pairs(self.avBlocks) do
      for m, n in pairs(self.av[k]) do
         io.write("[(" .. k .. ", " .. m .. ")] = ")
         self.avBlocks[k][m]:printSet()
      end
   end
end

function RuleInducer:getNextGoal()
   --check what goal is not covered
   for k, v in pairs(self.coverage) do
      if( v ~= true) then
         return clone(self.Dstar[k]), k
      end
   end

   --all concepts are covered return coverage complete signal
   return 0
end

function RuleInducer:induceRules()
   local finished = false
   local ruleSet = {}
   
   local rule = {}
   local ruleIndex = 1
   local avBlocks = clone(self.avBlocks)
   
   --get the first goal 
   local G, conceptName = self:getNextGoal()
   local initialG = clone(G)
   local remainingG = clone(G)

   --induce rules for to cover the dataset via LEM2
   while(finished == false) do
      --calculate the intersections of avBlocks with G
      local col = self:calcCol(avBlocks, G)
      
      --pick the best a,v pair
      local pickAttr, pickVal = self:pickAVpair(col)
      local pick = avBlocks[pickAttr][pickVal]
      
      --check if the a,v pair is a subset of G, if not compute new G
      --and continue adding a,v pairs until it is a subset
      --add the condition to the rule table
      rule[ruleIndex] = {}
      rule[ruleIndex].attr = pickAttr
      rule[ruleIndex].val = pickVal
      rule[ruleIndex].set = pick
      ruleIndex = ruleIndex + 1
         
      --check if the rule is consistant with G
      local isConsistant = self:isRuleConsistant(rule, G)
      --if consistant, add the rule to the ruleset and compute new G
      if(isConsistant) then
         --try dropping conditions
         local finalRule = self:reduceRule(rule, initialG)
         
         --add the rule to the ruleset
         local ruleStr = self:getRuleString(finalRule, conceptName)
         table.insert(ruleSet, ruleStr)
         
         --clear the rule
         rule = {}
         ruleIndex = 1
         
         --check if G is covered
         local ruleCover = self:ruleCoverage(finalRule)
         remainingG = remainingG:difference(ruleCover)
         if(remainingG:cardinality() == 0) then
            --the concept is covered, mark it on the table
            self.coverage[conceptName] = true
            
            --reset the [(a,v)] pairs available
            avBlocks = clone(self.avBlocks)
            
            --get new concept for G, if new G = 0, end loop
            G, conceptName = self:getNextGoal()
            initialG = clone(G)
            remainingG = clone(G)
            
            if(G == 0) then
               finished = true
            end
         else
            --reset the [(a,v)] pairs available
            avBlocks = clone(self.avBlocks)
            
            --next G = remaining cases to cover
            G = remainingG
         end
      else
         --otherwise compute new G and add more conditions to rule
         local ruleCover = self:ruleCoverage(rule)
         G = G:intersect(ruleCover)
         
         --remove the condition from the local avBlocks table
         avBlocks[pickAttr][pickVal] = nil
      end
   end
   
   --print the rules set
   self:writeRuleSetToFile(ruleSet)
end

function RuleInducer:pickAVpair(pPairs, pG)
   --pick the a,v pair with largest size, if tie continue on
   --add each size to the ordered table to sort
   local ordered = {}
   for k, v in pairs(pPairs) do
      ordered[k] = pPairs[k].size
   end

   --sort the ordered table of sizes
   table.sort(ordered)

   --add the indicies of the largest values to the max table
   local maxVal = ordered[#ordered]   
   local max = {}
   for i = 1, #pPairs do
      if(pPairs[i].size == maxVal) then
         table.insert(max, i)
      end
   end
   
   --if only one a,v pair is the largest, return that, otherwise
   --we must check the cardinality of each set in max
   if(#max == 1)then
      return pPairs[max[1]].attr, pPairs[max[1]].val
   end
   
   --pick a,v pair with lowest cardinality, if tie, pick 
   --the lowest indexed a,v pair
   local attr = pPairs[max[1]].attr
   local val = pPairs[max[1]].val
   local smallestSize = self.avBlocks[attr][val]:cardinality()
   local smallestIndex = max[1]
   
   --find the a,v block with the smallest number of elements
   for k, v in pairs(max) do
      attr = pPairs[v].attr
      val = pPairs[v].val
      local size = self.avBlocks[attr][val]:cardinality()
      if(size < smallestSize) then
         smallestSize = size
         smallestIndex = v
      end
   end
   
   --return smallestIndex, it will be of the smallest size because
   --it is checked against all other a,v blocks, and if there are
   --multiple with the same size, the top one is our heuristic pick
   return pPairs[smallestIndex].attr, pPairs[smallestIndex].val
end

function RuleInducer:reduceRule(pRule, pG)
   local result = clone(pRule)
   local numConditions = #result
   --return rule if only 1 condition
   if(#result > 1) then
      --try dropping conditions
      --mark a rule to drop with droppedIndex
      for droppedIndex = 1, #result do
         --if only one condition left, return the rule
         if(numConditions == 1) then
            break
         end
         
         local testRule = {}
         for k, v in pairs(result) do
            if(k ~= droppedIndex) then
               --add to test rule
               table.insert(testRule, result[k])
            end
         end
         
         --check if testRule is consistant with G,
         --if so drop the rule at droppedIndex
         if(self:isRuleConsistant(testRule, pG)) then
            --drop the condition
            result[droppedIndex] = nil
            numConditions = numConditions - 1
         end
      end
      
      --make a contiguous 1 indexed table to return
      local final = {}
      for k, v in pairs(result) do
         table.insert(final, result[k])
      end
      return final
   end
   return result
end

function RuleInducer:ruleCoverage(pRule)
  --compute intersection of each rule
   local result = pRule[1].set
   if(#pRule > 1) then
      for i = 2, #pRule do
         result = result:intersect(pRule[i].set)
      end
   end
   
   return result
end

function RuleInducer:isRuleConsistant(pRule, pG)
   --compute intersection of each rule
   local result = self:ruleCoverage(pRule)
   
   --check if the intersection of the conditions is a subset of pG
   if(result:subset(pG)) then
      return true
   else
      return false
   end
end

--calculates the intersection of [(a,v)] with G
function RuleInducer:calcCol(pAvBlocks, pG)
   local i = 1
   local col = {}
   for k, v in pairs(pAvBlocks) do
      for m, n in pairs(pAvBlocks[k]) do
         --fill each column with its relevance data
         col[i] = {}
         col[i].attr = k
         col[i].val = m
         col[i].set = n:intersect(pG)
         col[i].size = col[i].set:cardinality()
         i = i + 1
      end
   end
   
   return col
end
   
function RuleInducer:getRuleString(pRule, pConcept)
   local str = ""
   for k, v in pairs(pRule) do
      str = str .. "(" .. v.attr .. ", " .. v.val .. ")"
      if(pRule[k+1] ~= nil) then
         str = str .. " & "
      end
   end
   
   str = str .. " -> (" .. self.decisionName .. ", " .. pConcept .. ")"
   
   return str
end

function RuleInducer:writeRuleSetToFile(pRuleSet)
   local f = io.open(self.outputFile, "w+")
   for k, v in pairs(pRuleSet) do
      f:write(v .. "\n")
   end
   
   f.close()
end

function RuleInducer:descritize()
   --check if data set needs descritization
   --calculate for each attribute that needs descritization
   for k, v in pairs(self.needsDescritization) do
      if(v) then
         local values = {}

         --add every numerical attribute the the values table
         for i = 1, self.numCases do
            local val = self.cases[i][k]
            --if(val ~= "?" or val ~= "*" or val ~= "-") then
            if(type(val) == "number") then
               table.insert(values, val)
            end
         end

         --sort the data
         table.sort(values)
         local smallest = values[1]
         local largest = values[#values]

         --create cutpoints
         for m, n in pairs(values) do
            if(values[m + 1] ~= nil) then
               local curr = n
               local nxt = values[ m+ 1]

               --if curr = next dont make a cutpoint,
               --else find the average and store it
               if(curr ~= nxt) then
                  local cutpoint = ((curr + nxt) / 2)
                  local lower = (smallest .. ".." .. cutpoint)
                  local upper = (cutpoint .. ".." .. largest)
                  
                  --add the cutpoint data to the ranges table
                  self.ranges[lower] = {}
                  self.ranges[lower].attr = k
                  self.ranges[lower].low = smallest
                  self.ranges[lower].high = cutpoint
                  self.ranges[upper] = {}
                  self.ranges[upper].attr = k
                  self.ranges[upper].low = cutpoint
                  self.ranges[upper].high = largest
               end
            end
         end
      end
   end
end


