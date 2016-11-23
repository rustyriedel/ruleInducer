--MLEM2 algorithm for EECS 690 - Data Mining Project 01
--@Author Rusty Riedel
--@Date 11/22/2016
--KUID# 2474883

require "utils"
require "classes/Set"
require "classes/Parser"
require "classes/RuleInducer"

inducer = RuleInducer:new()
inducer:parseData()
inducer:run()

io.write("Your rule set is finished!\n")