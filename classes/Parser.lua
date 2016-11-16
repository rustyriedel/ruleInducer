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
      
      filePath = "datasets/normal/attractive.txt"
   }
   setmetatable(o, self)
   return o
end

function Parser:parse()
   --open the file to parse
   local f = assert(io.open(self.filePath, "r"))
   
   --read the file line by line and parse it
   for _ in io.lines("datasets/normal/attractive.txt") do
      local lineBuffer = f:read("*l")
      
      --check if line is a comment, if so disregard
      if string.sub(lineBuffer, 1, 1) == "!" then
         print(lineBuffer)
      --check if the first line of the file
      elseif (string.sub(lineBuffer, 1, 1) == '<') then
         self:countAttributes(lineBuffer)
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

--split string helper function, splits string into words.
function string:split(splitPattern, startIndex, resultTable)

   if not resultTable then
      resultTable = { }
   end
   if not startIndex then
      theStart = 1
   else
      theStart = startIndex
   end
   
   local theSplitStart, theSplitEnd = string.find( self, splitPattern, theStart )
   while theSplitStart do
      table.insert( resultTable, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, splitPattern, theStart )
   end
   table.insert( resultTable, string.sub( self, theStart ) )
   return resultTable
end

function Parser:countAttributes(pLineBuffer)
   --split the first line
   self.words = pLineBuffer:split(' ')
   
   --count the number of 'a's in the file = number of attributes
   for i = 1, #self.words do
      if(self.words[i] == 'a') then
         self.numAttributes = self.numAttributes  + 1
      end
   end
   
   print("number of attributes: " .. self.numAttributes)
end





