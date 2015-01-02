type PersistenceBatchResult
	# the result of a persistence operation
	issuccessful::Bool
	errorencountered::Bool

	insertverticesresult::PersistenceOperationResult{Vertex}
	insertedgesresult::PersistenceOperationResult{Edge}

	updateverticesresult::PersistenceOperationResult{Vertex}
	updateedgesresult::PersistenceOperationResult{Edge}

	removeverticesresult::PersistenceOperationResult{Vertex}
	removeedgesresult::PersistenceOperationResult{Edge}

	errormessage::String

	function PersistenceBatchResult()
		r = new()

		r.issuccessful = false
		r.errorencountered = false

		r.insertverticesresult = PersistenceOperationResult{Vertex}()
		r.insertedgesresult = PersistenceOperationResult{Edge}()

		r.updateverticesresult = PersistenceOperationResult{Vertex}()
		r.updateedgesresult = PersistenceOperationResult{Edge}()

		r.removeverticesresult = PersistenceOperationResult{Vertex}()
		r.removeedgesresult = PersistenceOperationResult{Edge}()

		return r
	end
end

function updatebatchstatus!(result::PersistenceBatchResult)

	subresults = Set{Any}()

	push!(subresults, result.insertverticesresult)
	push!(subresults, result.insertedgesresult)
	push!(subresults, result.updateverticesresult)
	push!(subresults, result.updateedgesresult)
	push!(subresults, result.removeverticesresult)
	push!(subresults, result.removeedgesresult)

	errorencountered = false
	allsuccessful = true
	errormessage = ""

	for sr in subresults
		errorencountered = errorencountered || sr.errorencountered
		allsuccessful = allsuccessful && sr.issuccessful

		if errormessage == "" && isdefined(sr, :errormessage) && sr.errormessage != ""
			errormessage = sr.errormessage
		end
	end

	result.errorencountered = errorencountered
	result.issuccessful = allsuccessful
	result.errormessage = errormessage
end
