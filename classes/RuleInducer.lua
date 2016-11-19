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
      
      outputFile = "ruleSet.txt"
   }
   setmetatable(o, self)
   return o
end

function RuleInducer:run()
   self:fillTestData()
   self:getAttributeValues()
   --self:printAttributeValues()
   self:calcAstar()
   self:calcDstar()
   self:calcAVBlocks()
   self:induceRules()
end

function RuleInducer:parseData()
   local fileParser = Parser:new()
   fileParser:parse()
   
   self.numAttributes = fileParser.numAttributes
   self.numCases = #fileParser.cases
   self.attributeNames = fileParser.attributeNames
   self.decisionName = fileParser.decisionName
   self.cases = fileParser.cases
   
   --print for DEBUG
   print("!!DONE PARSING!!")
end

function RuleInducer:fillTestData()
   --[[
   self.numAttributes = 3
   self.numCases = 8
   self.attributeNames = {"Height", "Hair", "Eyes"}
   self.decisionName = "Attractive"

   self.cases[1] = {"short", "blonde",   "blue",  "+"}
   self.cases[2] = {"tall",  "blonde",   "brown", "-"}
   --self.cases[2] = {"short", "blonde",   "blue",  "-"}
   self.cases[3] = {"tall",  "red",      "blue",  "+"}
   self.cases[4] = {"short", "dark",     "blue",  "-"}
   self.cases[5] = {"tall",  "dark",     "blue",  "-"}
   self.cases[6] = {"tall",  "blonde",   "blue",  "+"}
   self.cases[7] = {"tall",  "dark",     "brown", "-"}
   self.cases[8] = {"short", "blonde",   "brown", "-"}
   --]]
   --[[
   self.numAttributes = 3
   self.numCases = 8
   self.attributeNames = {"Wind", "Humidity", "Temperature"}
   self.decisionName = "Trip"

   self.cases[1] = {"low",    "low",      "medium",   "yes"}
   self.cases[2] = {"low",    "low",      "low",      "yes"}
   self.cases[3] = {"low",    "medium",   "medium",   "yes"}
   self.cases[4] = {"low",    "medium",   "high",     "maybe"}
   self.cases[5] = {"medium", "low",      "medium",   "maybe"}
   self.cases[6] = {"medium", "high",     "low",      "no"}
   self.cases[7] = {"high",   "high",     "high",     "no"}
   self.cases[8] = {"medium", "high",     "high",     "no"}
   --]]
   --[[--INCONSISTANT DATA SET FROM HOMEWORK #2
   self.numAttributes = 4
   self.numCases = 8
   self.attributeNames = {"Size", "Color", "Feel", "Temperature"}
   self.decisionName = "Attitude"

   self.cases[1] = {"big", "yellow", "soft", "low", "positive"}
   self.cases[2] = {"big", "yellow", "hard", "high", "negative"}
   self.cases[3] = {"medium", "yellow", "soft", "high", "positive"}
   self.cases[4] = {"medium", "blue", "hard", "high", "so-so"}
   self.cases[5] = {"medium", "blue", "hard", "high", "so-so"}
   self.cases[6] = {"medium", "blue", "soft", "low", "negative"}
   self.cases[7] = {"big", "blue", "hard", "low", "so-so"}
   self.cases[8] = {"big", "blue", "hard", "high", "so-so"}
   --]]
end

function RuleInducer:getAttributeValues()
   --add each attribute
   for k, v in pairs(self.attributeNames) do
      --add a subtable for each attribute
      self.av[v] = {}

      --enter each value for its respective attribute
      for i = 1, self.numCases do
         local temp = self.cases[i][k]
         self.av[v][temp] = true
      end
   end

   --add all the concepts to the concept table
   for i = 1, self.numCases do
      local temp = self.cases[i][self.numAttributes + 1]
      self.concepts[temp] = true
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
         local val = self.cases[i][j]
         local value = self:calcValue(i, j)
         self.avBlocks[attr][value]:insert(i)
      end
   end
end

function RuleInducer:calcValue(pCase, pAttribute)
   return self.cases[pCase][pAttribute]
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

function RuleInducer:calcCutpoints()
   local numCases = 8
   local data = {4, 8, 4, 8, 12, 16, 30, 12}

   --sort the data
   table.sort(data)
   local smallest = data[1]
   local largest = data[#data]

   --create cutpoints
   for k,v in pairs(data) do
      if(data[k + 1] ~= nil) then
         local curr = v
         local nxt = data[k + 1]

         --if curr = next dont make a cutpoint,
         --else find the average and store it
         if(curr ~= nxt) then
            local cutpoint = ((curr + nxt) / 2)
            io.write(smallest .. ".." .. cutpoint .. " , ")
            io.write(cutpoint .. ".." .. largest .. "\n")
         end
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
      --print the goal for debugging
      io.write("G = ")
      G:printSet()
      
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
               print("FINISHED INDUCING RULES!!")
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
         print("!NEED ANOTHER CONDITION!")
         local ruleCover = self:ruleCoverage(rule)
         G = G:intersect(ruleCover)
         
         --remove the condition from the local avBlocks table
         avBlocks[pickAttr][pickVal] = nil
      end
      
      print("done with iteration!")
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
   
   --print for DEBUG
   print("largest size")
   for k,v in pairs(max) do
      print(pPairs[v].attr, pPairs[v].val)
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
   
   --print for DEBUG
   print("most relevant")
   print(pPairs[smallestIndex].attr, pPairs[smallestIndex].val)
   
   --return smallestIndex, it will be of the smallest size because
   --it is checked against all other a,v blocks, and if there are
   --multiple with the same size, the top one is our heuristic pick
   return pPairs[smallestIndex].attr, pPairs[smallestIndex].val
   
end

function RuleInducer:reduceRule(pRule, pG)
   local result = clone(pRule)
   --return rule if only 1 condition
   if(#result > 1) then
      --try dropping conditions
      --mark a rule to drop with droppedIndex
      for droppedIndex = 1, #result do
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
         --col[i].set = Set:new()
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
      print(v)
      f:write(v .. "\n")
   end
   
   f.close()
end



