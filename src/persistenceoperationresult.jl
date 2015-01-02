type PersistenceOperationResult{T}
	# the result of a persistence operation
	issuccessful::Bool
	errorencountered::Bool

	successfulset::Set{T}
	failedset::Set{T}

	errormessage::String

	function PersistenceOperationResult()
		r = new()

		r.issuccessful = false
		r.errorencountered = false

		r.successfulset = Set{T}()
		r.failedset = Set{T}()

		return r
	end
end
