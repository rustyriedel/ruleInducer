--Set class
--used logic from this repository to create my methods
--https://github.com/dufferzafar/Lua-Scripts/blob/master/Miscellaneous/Set.lua

Set = {}
Set.__index = Set

--constructor
function Set:new()
   local o = {
      data = {},
      size = 0
   }
   setmetatable(o, self)
   return o
end

function Set:insert(pData)
   if(self.data[pData] ~= true) then
      self.data[pData] = true
      self.size = self.size + 1
   end
end

function Set:remove(pData)
   if(self.data[pData] ~= nil) then
      self.data[pData] = nil
      self.size = self.size - 1
   end
end

function Set:cardinality()
   return self.size
end

function Set:union(pSet)
   --resulting set to return
   local result = Set:new()
   
   --build the resulting set
   for k, v in pairs(self.data) do
      result:insert(k)
   end
   for k, v in pairs(pSet.data) do
      result:insert(k)
   end
   
   --return the resulting set
   return result
end

function Set:intersect(pSet)
   local result = Set:new()
   
   --build the resulting set
	for i in pairs(self.data) do 
      if(pSet.data[i] == true) then 
         result:insert(i)
      end
   end

   --return the resulting set
   return result
end

function Set:difference(pSet)
   local result = Set:new()
   
   --calculate the difference
   for i in pairs(self.data) do
      if(pSet.data[i] ~= true) then
         result:insert(i)
      end
   end
   
   --return the resulting set
   return result
end

function Set:subset(pSet)
   --check if left is larger than right, if so
   --left cannot be a subset
   if self:cardinality() > pSet:cardinality() then
      return false
   end
   
   --make sure each element in left is in the right set
   --otherwise return false
   for i in pairs(self.data) do
      if not pSet.data[i] then
         return false
      end
   end
   
   --the left set is indeed a subset
   return true
end

function Set:printSet()
   for k, v in pairs(self.data) do
      io.write(k .. " ")
   end
   io.write("\n")
end


