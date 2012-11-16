
	JEFRi.Runtime:: <<<<
		store: (store)->
			if store
				@_store = new store runtime: @
				@
			else
				@_store ?= new JEFRi.ObjectStore
				@_store
	
		# Save all the new entities.
		save_new: (store = @store!)->
			transaction = new JEFRi.Transaction!
			@saving <: {}

			#Add all new entities to the transaction
			transaction.add(@_new)

			return @_save(transaction, store)

		# Save all entities with changes, including new entities.
		save_all: (store = @store!) ->
			transaction = new JEFRi.Transaction!
			@saving <: {}

			#Add all new entities to the transaction
			# Modified is keyed by type...
			for t, modified of @_modified
				# ...and each key contains an object of entity instances
				for k, entity of modified
					entity._persist(transaction)

			for neu in @_new
				@persist neu

			@_save transaction, store

		_save: (transaction) ->
			return @store!execute('persist', transaction).then _.bind(@expand, @)


