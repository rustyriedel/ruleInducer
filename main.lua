--MLEM2 algorithm for EECS 690 - Data Mining Project 01

require "utils"
require "classes/Set"
require "classes/Parser"
require "classes/RuleInducer"
--require "tests/setTest"

inducer = RuleInducer:new()
inducer:parseData()
inducer:run()



--TODO
--upper and lower approximations
--input interface
--test several data sets
