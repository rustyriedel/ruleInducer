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

--got this function to check if a file exists from stack overflow
--http://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists
function fileExists(name)
   local f=io.open(name,"r")
   if f~=nil then 
      io.close(f) 
      return true
   else 
      return false 
   end
end