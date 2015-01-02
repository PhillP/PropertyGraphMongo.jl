using Mongo
using PropertyGraph
using PropertyGraphMongo

using LibBSON
using Base.Test
using UUID
using Compat

mongoDBDir = "/tmp/Mongo.jl-test.db"
mkpath(mongoDBDir)
mongod = spawn(`mongod --dbpath $mongoDBDir`)
sleep(1) # wait for listen on port

try
	testfiles = [
				"testsavechanges",
				"testquery",
				]

	println("Running tests:")

	for t in testfiles
		testfilepath = joinpath(Pkg.dir("PropertyGraphMongo"),"test","$(t).jl")
		println("running $(testfilepath) ...")
		include(testfilepath)
	end
finally
	kill(mongod)
	rm(mongoDBDir, recursive=true)
end
