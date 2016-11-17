--set test file
--only include if you want to test the set operations
--useful for refrencing the Set API

print("Starting Set test!")

--build set 1 
v1 = Set:new()
v1:insert(1)
v1:insert(2)
v1:insert(3)
v1:insert(5)
v1:insert(9)

--res = v1:cardinality()
--output set 1 info
io.write("v1\t")
v1:printSet()
io.write("|v1| = " .. v1:cardinality() .. "\n")

--build set 2
v2 = Set:new()
v2:insert(3)
v2:insert(1)
v2:insert(5)
v2:remove(8)
v2:remove(3)
v2:insert(3)
v2:insert(7)

--output set 2 info
io.write("v2\t")
v2:printSet()
io.write("|v2| = " .. v2:cardinality() .. "\n")

--compute difference
io.write("v1 - v2\n")
temp1 = v1:difference(v2)
temp1:printSet()
io.write("v2 - v1\n")
temp2 = v2:difference(v1)
temp2:printSet()

--calculate the intersection and union of sets 1 and 2
re1 = v1:intersect(v2)
re2 = v1:union(v2)

--output the results of the operations
io.write("intersection of v1 and v2 = re1\n")
io.write("re1\t")
re1:printSet()
io.write("|r1| = " .. re1:cardinality() .. "\n")
io.write("union of v1 and v2 = re2\n")
io.write("re2\t")
re2:printSet()
io.write("|r2| = " .. re2:cardinality() .. "\n")

--calculate and output subset results
io.write("v1 subset v2?\t")
print(v1:subset(v2))
io.write("v2 subset v1?\t")
print(v2:subset(v1))

print("Set testing done!\n")