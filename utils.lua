--utility functions

--clones a table (deep table copy, including meta tables)
--https://gist.github.com/MihailJP/3931841
function clone (t) -- deep-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            target[k] = clone(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
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