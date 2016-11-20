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
      filePath = "datasets/normal/test.txt"
   }
   setmetatable(o, self)
   return o
end

function Parser:parse()
   --open the file to parse
   local f = assert(io.open(self.filePath, "r"))
   
   --read the file contents into a buffer variable
   local buffer = f:read("*a")
   
   --remove comments from the buffer before processing the 
   --rest of the file using a regular expression for pattern matching
   local removeStr = buffer:match("[!]+[^\n]*[\n]")
   while(removeStr ~= nil) do
      buffer = buffer:gsub(removeStr, "")
      removeStr = buffer:match("[!]+[^\n]*[\n]")
   end
   
   --split the rest of the buffer into words 
   --seperated by spaces, tabs and newline characters
   for w in buffer:gmatch("%S+") do   
      table.insert(self.words, w)
   end
   
   --parse the words table to populate the parser variables
   self:parseWords()
   
   --close the input file
   f:close()
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
         local temp = self.cases[caseIndex][i]
         print(temp:match("%d+[^'..']*%d*"))
--         if(self.cases[caseIndex][i].type()) then
--            self.needsDescritization[caseIndex] = true
--         end
         self.wordIndex = self.wordIndex + 1
      end
      
      --increment the caseIndex
      caseIndex = caseIndex + 1
   end
end







