--builds the automated file to test my EECS 690 data mining project
--LERS data sets using possible, and certain rules as well as running
--them in lua and luaJIT for each data set provided.

files = {
   "attr",
   "attractive",
   "bank-35",
   "echo-35",
   "echo-40",
   "image-35",
   "iris-49-aca",
   "test",
   "trip",
   "austr",
   "common_combined_lers",
   "keller-train-ca"
}
local count = 1

for k,v in pairs(files) do
   print("echo \""..count.." - "..v..".txt certain noJit\"")
   print("time lua main.lua <<EOF")
   print("datasets/normal/"..v..".txt")
   print("1")
   print("ruleSets/"..count..".txt")
   print("EOF\n")
   count = count + 1

   print("echo \""..count.." - "..v..".txt possible noJit\"")
   print("time lua main.lua <<EOF")
   print("datasets/normal/"..v..".txt")
   print("2")
   print("ruleSets/"..count..".txt")
   print("EOF\n")
   count = count + 1

   print("echo \""..count.." - "..v..".txt certain JIT\"")
   print("time luajit main.lua <<EOF")
   print("datasets/normal/"..v..".txt")
   print("1")
   print("ruleSets/"..count..".txt")
   print("EOF\n")
   count = count + 1

   print("echo \""..count.." - "..v..".txt possible JIT\"")
   print("time luajit main.lua <<EOF")
   print("datasets/normal/"..v..".txt")
   print("2")
   print("ruleSets/"..count..".txt")
   print("EOF\n")
   count = count + 1
   
end
