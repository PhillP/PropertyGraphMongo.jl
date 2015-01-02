type MongoStore

	graph::Any

	uri::String

	function MongoStore(g::Graph, uri::String)
		# Construct an edge from a pair of vertices with a set of property values

		ms = new()
		ms.graph = g
		ms.uri = uri

		return ms
	end

	MongoStore(g::Graph, host::String, port::Int) = MongoStore(g, "mongodb://$host:$port/")
    MongoStore(g::Graph) = MongoStore(g, "localhost", 27017)
end

function buildcollectionkey(id::UUID.Uuid, prefix::String, suffix::String = "")
	return "$asString(id)_$prefix_$suffix"
end

function getorbuildcollection(client::MongoClient, collectiondict::Dict{String, MongoCollection}, g::Graph, collectionkey::String, collectiontype::String)
	if haskey(collectionkey, collectiondict)
		return collectiondict[collectionkey]
	else
		collection = MongoCollection(client, "@pg_$asString(g.id)", collectionkey)

		# ensure indexes
		ensureindex(collection, Set{String}("@pg_id"), Dict{String, String}("unique"=>"true"))
		ensureindex(collection, Set{String}("@pg_typelabel"), Dict{String, String}("unique"=>"false"))

		if collectiontype == "edge"
			ensureindex(collection, Set{String}("@pg_head_id"), Dict{String, String}("unique"=>"false"))

			ensureindex(collection, Set{String}("@pg_head_typelabel"), Dict{String, String}("unique"=>"false"))

			ensureindex(collection, Set{String}("@pg_tail_id"), Dict{String, String}("unique"=>"false"))

			ensureindex(collection, Set{String}("@pg_tail_typelabel"), Dict{String, String}("unique"=>"false"))
		end

		collectiondict[collectionkey] = collection
			return collection
	end
end

function persistnewvertices(client::MongoClient, newvertices::Dict{UUID.Uuid, Vertex}, graph::Graph, collectiondict::Dict{String, MongoCollection})

	result = PersistenceOperationResult{Vertex}()

	lastitemattempted = UnspecifiedValue

	try
		for (k,v) in newvertices
			lastitemattempted = v

			collectionkey = buildcollectionkey(graph.id, "vertex", v.typelabel)
			collection = getorbuildcollection(client, collectiondict, graph, collectionkey, "vertex")

			oid = BSONOID()
			props = Dict{String,Any}("_id"=>oid,
									 "@pg_id"=>v.id,
									 "@pg_typelabel"=>v.typelabel)

			merge!(props, v.attachedproperties)
			insertresult = insert(collection, props)

			if insertresult == 0
				push!(result.successfulset, v)
			else
				error("Insert operation was unsuccessful. Result code: $insertresult")
			end
		end
	catch
		result.errorencountered = true

		if lastitemattempted != UnspecifiedValue
			push!(result.failedset, lastitemattempted)
		end
	end

	return result
end

function persistnewedges(client::MongoClient, newedges::Dict{UUID.Uuid, Edge}, graph::Graph, collectiondict::Dict{String, MongoCollection})

	result = PersistenceOperationResult{Edge}()

	lastitemattempted = UnspecifiedValue

	try
		for (k,v) in newedges

			lastitemattempted = v

			collectionkey = buildcollectionkey(graph.id, "edge", v.typelabel)
			collection = getorbuildcollection(client, collectiondict, graph, collectionkey,"edge")
			oid = BSONOID()
			props = Dict{String,Any}("_id"=>oid,
									 "@pg_id"=>v.id,
									 "@pg_typelabel"=>v.typelabel,
									 "@pg_head_id"=>v.head.id,
									 "@pg_head_typelabel"=>v.head.typelabel,
									 "@pg_tail_id"=>v.tail.id,
									 "@pg_tail_typelabel"=>v.tail.typelabel)
			merge!(props, v.attachedproperties)

			insertresult = insert(collection, props)

			if insertresult == 0
				push!(result.successfulset, v)
			else
				error("Insert operation was unsuccessful. Result code: $insertresult")
			end
		end
	catch
		result.errorencountered = true

		if lastitemattempted != UnspecifiedValue
			push!(result.failedset, lastitemattempted)
		end
	end

	return result
end

function persistchangededges(client::MongoClient, changededges::Dict{UUID.Uuid, Edge}, graph::Graph, collectiondict::Dict{String, MongoCollection})

	result = PersistenceOperationResult{Edge}()

	lastitemattempted = UnspecifiedValue

	try
		for (k,v) in changededges

			lastitemattempted = v

			collectionkey = buildcollectionkey(graph.id, "edge")
			collection = getorbuildcollection(client, collectiondict, graph, collectionkey,"edge")

			oid = BSONOID()
			props = Dict{String,Any}("_id"=>oid,
									 "@pg_id"=>v.id,
									 "@pg_typelabel"=>v.typelabel,
									 "@pg_head_id"=>v.head.id,
									 "@pg_head_typelabel"=>v.head.typelabel,
									 "@pg_tail_id"=>v.tail.id,
									 "@pg_tail_typelabel"=>v.tail.typelabel)
			merge!(props, v.attachedproperties)

			updateresult = update(collection,
				   {"pg_id"=>v.id},
				   {"\$set"=>props}
				   )

			if updateresult == 0
				push!(result.successfulset, v)
			else
				error("Update operation was unsuccessful. Result code: $updateresult")
			end
		end
	catch
		result.errorencountered = true

		if lastitemattempted != UnspecifiedValue
			push!(result.failedset, lastitemattempted)
		end
	end

	return result
end

function persistchangedvertices(client::MongoClient, changedvertices::Dict{UUID.Uuid, Vertex}, graph::Graph, collectiondict::Dict{String, MongoCollection})
	result = PersistenceOperationResult{Vertex}()

	lastitemattempted = UnspecifiedValue

	try
		for (k,v) in changedvertices

			lastitemattempted = v

			collectionkey = buildcollectionkey(graph.id, "vertex", v.typelabel)
			collection = getorbuildcollection(client, collectiondict, graph, collectionkey,"vertex")
			oid = BSONOID()
			props = Dict{String,Any}("_id"=>oid, "@pg_id"=>v.id, "@pg_typelabel"=>v.typelabel)

			merge!(props, v.attachedproperties)

			updateresult = update(collection,
				   {"pg_id"=>v.id},
				   {"\$set"=>props}
				   )

			if updateresult == 0
				push!(result.successfulset, v)
			else
				error("Update operation was unsuccessful. Result code: $updateresult")
			end
		end
	catch
		result.errorencountered = true

		if lastitemattempted != UnspecifiedValue
			push!(result.failedset, lastitemattempted)
		end
	end

	return result
end

function processremovededges(client::MongoClient, removededges::Dict{UUID.Uuid, Edge}, graph::Graph, collectiondict::Dict{String, MongoCollection})
	result = PersistenceOperationResult{Edge}()

	lastitemattempted = UnspecifiedValue

	try
		for (k,v) in removededges

			lastitemattempted = v
			collectionkey = buildcollectionkey(graph.id, "edge")
			collection = getorbuildcollection(client, collectiondict, graph, collectionkey,"vertex")
			deleteresult = delete(
				collection,
				{"@pg_id"=>v.id}
			)

			if deleteresult == 0
				push!(result.successfulset, v)
			else
				error("Delete operation was unsuccessful. Result code: $deleteresult")
			end
		end
	catch
		result.errorencountered = true

		if lastitemattempted != UnspecifiedValue
			push!(result.failedset, lastitemattempted)
		end
	end

	return result
end

function processremovedvertices(client::MongoClient, removedvertices::Dict{UUID.Uuid, Vertex}, graph::Graph, collectiondict::Dict{String, MongoCollection})
	result = PersistenceOperationResult{Vertex}()

	lastitemattempted = UnspecifiedValue

	try
		for (k,v) in removedvertices

			lastitemattempted = v
			collectionkey = buildcollectionkey(graph.id, "vertex")
			collection = getorbuildcollection(client, collectiondict, graph, collectionkey,"vertex")
			deleteresult = delete(
				collection,
				{"@pg_id"=>v.id}
			)

			if deleteresult == 0
				push!(result.successfulset, v)
			else
				error("Delete operation was unsuccessful. Result code: $deleteresult")
			end
		end
	catch
		result.errorencountered = true

		if lastitemattempted != UnspecifiedValue
			push!(result.failedset, lastitemattempted)
		end
	end

	return result
end

function persist(store::MongoStore)

	result = PersistenceBatchResult()

	if !isdefined(store.graph, :tracker)
		throw(ChangeTrackerNotDefinedException())
	end

	if !store.graph.tracker.ischanged
		# if nothing changed, nothing to persist
		return false
	end

	client = MongoClient(store.uri)

	# a dictionary used to store references to MongoCollections by key
	collectiondict = Dict{String, MongoCollection}()

	try
		# process new vertices
		result.insertverticesresult = persistnewvertices(client, store.graph.tracker.newvertices, store.graph, collectiondict)

		# process new edges
		result.insertedgesresult = persistnewedges(client, store.graph.tracker.newedges, store.graph, collectiondict)

		# process changed vertices
		result.updateverticesresult = persistchangedvertices(client, store.graph.tracker.changedvertices, store.graph, collectiondict)

		# process changed edges
		result.updateedgesresult = persistchangededges(client, store.graph.tracker.changededges, store.graph, collectiondict)

		# process removed edges
		result.removeedgesresult = processremovededges(client, store.graph.tracker.removededges, store.graph, collectiondict)

		# process removed vertices
		result.removeverticesresult = processremovedvertices(client, store.graph.tracker.removedvertices, store.graph, collectiondict)

	finally
		updatebatchstatus!(result)

		if result.issuccessful
			# mark the graph as unchanged as the change has been processed
			clearchanges(store.graph.tracker)
		else
			# more selectively remove record of changes
			for item in result.insertverticesresult.successfulset
				clearnewvertex(store.graph.tracker, item)
			end
			for item in result.insertedgesresult.successfulset
				clearnewedge(store.graph.tracker, item)
			end
			for item in result.updateverticesresult.successfulset
				clearchangedvertex(store.graph.tracker, item)
			end
			for item in result.updateedgesresult.successfulset
				clearchangededge(store.graph.tracker, item)
			end
			for item in result.removeverticesresult.successfulset
				clearremovedvertex(store.graph.tracker, item)
			end
			for item in result.removeedgesresult.successfulset
				clearremovededge(store.graph.tracker, item)
			end
		end
	end

	return result
end
