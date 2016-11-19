--parser class

Parser = {}
Parser.__index = Parser

--state 1 = get number of attributes between < >
--state 2 = get the attribute names and decision name
--state 3 = create cases

--constructor
function Parser:new()
   local o = {
      numAttributes = 0,
      count = 1,
      attributeNames = {},
      decisionName = "none",
      words = {},
      
      state = 1,
      filePath = "datasets/normal/attractive.txt"
   }
   setmetatable(o, self)
   return o
end

function Parser:parse()
   --open the file to parse
   local f = assert(io.open(self.filePath, "r"))
   
   --read the file line by line and parse it
   for _ in io.lines(self.filePath) do
      local lineBuffer = f:read("*l")
      
      --check if line is a comment, if so disregard
      if string.sub(lineBuffer, 1, 1) == "!" then
         print(lineBuffer)
      --check if the first line of the file
      elseif (self.state == 1) then
         self:countAttributes(lineBuffer)
      elseif(self.state == 2) then
         self:getAttributeNames(lineBuffer)
      --make the substring into words delemited by spaces
      else
         self.words = lineBuffer:split(' ')
      end
      
      --[[ --print out the words table for debugging
      for i = 1, #words do
         print(words[i])
      end
      --]]
   end
   
   --close the input file
   f:close()
end

function Parser:countAttributes(pLineBuffer)
   --split the first line
   self.words = pLineBuffer:split(' ')
   
   --count the number of 'a's in the file = number of attributes
   for i = 1, #self.words do
      if(self.words[i] == 'a') then
         self.numAttributes = self.numAttributes  + 1
      elseif (self.words[i] == '>') then
         self.state = 2
          print("number of attributes: " .. self.numAttributes)
      end
   end
end

function Parser:getAttributeNames(pLineBuffer)
   --split the first line
   self.words = pLineBuffer:split(' ')
   
   --add each name to the 
   for i = 1, #self.words do
      if(self.words[i] == ('[' or '')) then
         --disregard
      elseif(self.count <= self.numAttributes) then
         table.insert(self.attributeNames, self.words[i])
         self.count = self.count + 1
      elseif(self.count == self.numAttributes + 1)then
         self.decisionName = self.words[i]
         self.count = self.count + 1
      elseif(self.words[i] == ']') then
         self.state = 3
      end
   end
end






