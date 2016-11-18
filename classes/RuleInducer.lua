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

      coverage = {}
   }
   setmetatable(o, self)
   return o
end

function RuleInducer:fillTestData()
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
         return self.Dstar[k]
      end
   end

   --all concepts are covered return coverage complete signal
   return 0
end

function RuleInducer:run()
   --get the goal
   local G = self:getNextGoal()
   --G = Set:new()
   --G:insert(3)
   
   --if G = 0, coverage has been provided for all concepts in {d}*
   if(G == 0) then
      --FINISHED INDUCING RULES!!
      --TODO print out the rules
      print("FINISHED INDUCING RULES!!")
   end
   
   --print the goal for debugging
   io.write("G = ")
   G:printSet()

   --calculate the intersections of avBlocks with G
   local i = 1
   local col = {}
   for k, v in pairs(self.avBlocks) do
      for m, n in pairs(self.av[k]) do
         --fill each column with its relevance data
         col[i] = {}
         col[i].attr = k
         col[i].val = m
         col[i].set = Set:new()
         col[i].set = self.avBlocks[k][m]:intersect(G)
         col[i].size = col[i].set:cardinality()
         i = i + 1
      end
   end

   --pick the best a,v pair
   local pickAttr, pickVal = self:pickAVpair(col)
   local pick = self.avBlocks[pickAttr][pickVal]
   
   --check if the a,v pair is a subset of G, if not compute new G
   --and continue adding a,v pairs until it is a subset
   print(pick:subset(G))
   
   --try dropping conditions
   
   
   --check for coverage of the concept, if covered,
   --mark if off the coverage table

   print("done with iteration!")
end

function RuleInducer:pickAVpair(pPairs)
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
