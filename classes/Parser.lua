--parser class

Parser = {}
Parser.__index = Parser

--constructor
function Parser:new()
   local o = {
      numAttributes = 0,
      attributeNames = {},
      decisionName = "none",
      words = {},
      cases = {},
      needsDescritization = {},
      
      wordIndex = 2,
      filePath = "datasets/normal/trip.txt"
      --filePath = "datasets/normal/iris-49-aca.txt"
   }
   setmetatable(o, self)
   return o
end

function Parser:parse()
   --open the file to parse
   local f = assert(io.open(self.filePath, "r"))
   
   --read the file contents into a buffer variable
   local buffer = f:read("*a")
   --print(buffer)
   --close the file
   f:close()
   
   --remove comments from the buffer before processing the 
   --rest of the file using a regular expression for pattern matching
   buffer = buffer:gsub("!.-\n", "")
   
   --split the rest of the buffer into words 
   --seperated by spaces, tabs and newline characters
   for w in buffer:gmatch("%S+") do   
      table.insert(self.words, w)
   end
   
   --parse the words table to populate the parser variables
   self:parseWords()
end

function Parser:parseWords()
   --count the number of attributes
   while(true) do
      
      if(self.words[self.wordIndex] == 'a' or 
            self.words[self.wordIndex] == 'x') then
         self.numAttributes = self.numAttributes + 1
         self.wordIndex = self.wordIndex + 1
      elseif(self.words[self.wordIndex] == '>') then
         self.wordIndex = self.wordIndex + 1
         break
      else
         self.wordIndex = self.wordIndex + 1
      end
   end
   
   --initialize the needsDescritization table
   for i = 1, self.numAttributes do
      self.needsDescritization[i] = false
   end
   
   --skip the "[" for the attribute list
   self.wordIndex = self.wordIndex + 1
   
   --add each attribute name to the attributeNames table
   for i = 1, self.numAttributes do
      self.attributeNames[i] = self.words[self.wordIndex]
      self.wordIndex = self.wordIndex + 1
   end

   --the next word will be the decision name so enter it
   self.decisionName = self.words[self.wordIndex]
   self.wordIndex = self.wordIndex + 1
   
   --skip the "]" for the attribute list
   self.wordIndex = self.wordIndex + 1
   
   --fill each case with its values 
   local caseIndex = 1
   while(self.wordIndex < #self.words) do
      --make a new case
      self.cases[caseIndex] = {}
      
      --fill the case with its attributes and decision
      for i = 1, self.numAttributes + 1 do
         self.cases[caseIndex][i] = self.words[self.wordIndex]
         
         --disregard processing on descision values
         if(i ~= self.numAttributes + 1) then
            --if the case value is a number, match it with regex
            local initialStr = self.cases[caseIndex][i]
            local matched = initialStr:match("[%-]?%d*['.']?%d+")
            if(matched == initialStr) then
               --the value is a number, convert it to a number
               self.cases[caseIndex][i] = tonumber(matched)
               --print for DEBUG
               print(matched)
               self.needsDescritization[caseIndex] = true
            end
         end
         
         --increment the word index
         self.wordIndex = self.wordIndex + 1
      end
      
      --increment the caseIndex
      caseIndex = caseIndex + 1
   end
end

