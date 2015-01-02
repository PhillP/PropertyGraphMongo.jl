# define custom types required for the test
type TestCustomPersonType
	firstname::String
	lastname::String
end

type TestKnowsType
	someproperty::String
end

function savetest()
	# create a graph
	g = Graph()
	g.tracker = ChangeTracker()

	# create a vertex and add it to the graph
	fred = add!(g, Vertex("Person", @compat Dict{String,Any}("name"=>"Fred","age"=>45)))

	# make some more vertices
	sally = add!(g, Vertex("Person", @compat Dict{String,Any}("name"=>"Sally","age"=>25)))

	johanobject = TestCustomPersonType("Johan", "Smith")
	johan = vertexforobject("Person", johanobject,  @compat Dict{String,Any}("name"=>"Johan","age"=>28))
	add!(g, johan)

	# create some edges
	e = Edge(fred,sally)
	e2 = Edge("knows", fred, sally, @compat Dict{String,Any}("since"=>2004))

	#including one with an associated object
	fredknowsjohanobject = TestKnowsType("SomeValue")
	e3 = edgeforobject("knows", fredknowsjohanobject, fred,johan)

	# add the edges to the graph
	add!(g, e)
	add!(g, e2)
	add!(g, e3)

	s = MongoStore(g)

	return persist(s)
end
result = savetest()
@test result.issuccessful == true

