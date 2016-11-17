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
      attributeValues = {},
      concepts = {},
      Dstar = {},
      Astar = {}
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
      self.attributeValues[v] = {}
      
      --enter each value for its respective attribute
      for i = 1, self.numCases do
         local temp = self.cases[i][k]
         self.attributeValues[v][temp] = true
      end
   end
   
   --add all the concepts to the concept table
   for i = 1, self.numCases do
      local temp = self.cases[i][self.numAttributes + 1]
      self.concepts[temp] = true
   end
end

function RuleInducer:calcAstar()
   --create the partitions for each concept in A*
   self.Astar[1] = Set:new()
   
   --insert the first case
   self.Astar[1]:insert(1)
   
   --check if any other cases are in the same set
   for i = 1, self.numCases do
      --check if each case is the same and add it to the set
   end
   ---------------------------------------
   --[[for k, v in pairs(self.attributeValues) do
      self.Astar[k] = Set:new()   
   end
   --]]
   
      
   --[[   
      --add each case to A*
      for i = 1, self.numCases do
         if(self.cases[i][self.numAttributes + 1] == k) then
            self.Dstar[k]:insert(i)
         end
      end
   end
   --]]
end

function RuleInducer:calcDstar()
   --create the partitions for each concept in {d}*
   for k, v in pairs(self.concepts) do
      self.Dstar[k] = Set:new()
      
      --add each case to {d}*
      for i = 1, self.numCases do
         if(self.cases[i][self.numAttributes + 1] == k) then
            self.Dstar[k]:insert(i)
         end
      end
   end
end

function RuleInducer:printAttributeValues()
   --print out the set of values for each attribute
   for k, v in pairs(self.attributeValues) do
      io.write(k .. " { ")
      for m, n in pairs(self.attributeValues[k]) do
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




