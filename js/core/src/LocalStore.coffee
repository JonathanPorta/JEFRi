#     JEFRi LocalStore.coffee 0.1.0
#     (c) 2011-2012 David Souther
#     JEFRi is freely distributable under the MIT license.
#     For full details and documentation:
#     http://jefri.org

do ->
	root = @

	`root.JEFRi = root.JEFRi ? root.JEFRi : {}`

	class LocalStore
		constructor: (options) ->
			@settings = { version: "1.0", size: Math.pow(2, 16) }
			_.extend(@settings, options)
			if not @settings.runtime
				throw {message: "LocalStore instantiated without runtime to reference."}

		# ### execute*(type, transaction)*
		# Run the transaction.
		execute: (type, transaction) ->
			transactionEvent = JSON.parse(transaction.toString())
			_(@).trigger('sending', type, 'localStorage:', transactionEvent, @)
			if (type == "persist")
				@persist(transaction)
			else if (type == "get")
				@get(transaction)
			_.Deferred().resolve(transaction);

		# ### persist*(transction)*
		# Treat the transaction as a persistence call. Save the data.
		persist: (transaction) ->
			transaction.entities = (@_save(entity) for entity in transaction.entities)

		# #### _save*(entity)*
		# Save the data in the browser's localStorage.
		_save: (entity) ->
			# Merge the new data over the old data.
			entity = _.extend({}, @_find(entity), entity)
			# Store the JSON of the entity.
			localStorage[_key(entity)] = JSON.stringify(entity)
			# Register the entity with the type map.
			_type(entity._type(), entity.id());
			# Return the bare encoded object.
			entity._encode()

		# ### get*(transaction)*
		# Treat the transaction as a lookup. Find all data matching the specs.
		get: (transaction) ->
			# Let _lookup handle the actual lookups. Each spec is an `or` op, so flatten then remove duplicates.
			transaction.entities = _.uniq(
				# The lookup
				_.flatten((@_lookup(entity) for entity in transaction.entities)),
				false,
				# Uniq based on type.id
				(e) => e._type + '.' + e[@settings.runtime.definition(e._type).key]
			)
			# Put the entities back in the runtime
			@settings.runtime.expand(transaction, "gotten")
			# Fire events
			_.trigger(transaction, 'gotten')
			transaction

		# #### _find*(entity)*
		# Return an entity directly, or pass a spec to _lookup.
		_find: (entity) ->
			if _.isEntity(entity)
				JSON.parse(localStorage[_key(entity)] || "{}")
			else
				@_lookup(entity)

		# #### _lookup*(spec)*
		# Given a transaction spec, pull all entities (including relationships) that match.
		# See JEFRi Core documentation 5.1.1 Gory Get Details for rules.
		_lookup: (spec) ->
			# Need the key, properties, and relationships details
			def = @settings.runtime.definition(spec._type)
			# Get everything for this type
			results = (JSON.parse(localStorage[spec._type + "." + id]) for id in _.keys(_type(spec._type)))

			# Start immediately with the key to pear down results quickly. Rule 1.
			if def.key of spec
				results = [results[spec[key]]]

			# Filter based on property specifications
			for name, property of def.properties
				if name of spec and name isnt def.key
					results = _(results).filter(_sieve(name, property, spec[name]))

			# Include relationships
			for name, relationship of def.relationships
				if name of spec
					# For all the entities found so far, include their relationships as well
					give = []
					take = []
					for entity, i in results
						related = ( =>
							relspec = _.extend({}, spec[name], {_type: relationship.to.type})
							relspec[relationship.to.property] = entity[relationship.property]
							# Just going to use 
							@_lookup(relspec)
						)()
						# Giveth, or taketh away
						if related.length
							give.push(related)
						else
							take.push(i)
					# Remove the indicies which didn't have a relation.
					take.reverse()
					# 
					for i in take
						end = results[i+1...]
						results = results[...i]
						[].push.apply(results, end)
					[].push.apply(results, give)

			# Return the filtered results.
			results

		# #### _type*(type[, id])*
		# Get a set of stored IDs for a particular type. If an ID is passed in, add it to the set.
		_type = (type, id=null) ->
			# Get the current set
			list = JSON.parse(localStorage[type] || "{}");
			if id
				# Indexed by ID, so just need an empty set.
				list[id] = ""
				# Restringify. Silly localStorage being string => string
				localStorage[type] = JSON.stringify(list)
			# Return the list.
			list

		# #### _key*(entity)*
		# Return the full key type/id string for an entity, since this is the bare entity with no methods.
		_key = (entity) ->
			entity._type() + "." + entity.id()

		# ### _sieve*(name, property, spec)*
		# Return a function to use to filter on a particular spec field. These functions implement
		# the logic described in JEFRi Core docs 5.1.1
		_sieve = (name, property, spec) ->
			# Normalize rules 2 and 3 to operator array
			if _.isNumber(spec)
				if spec % 1 is 0
					spec = ['=', spec]
				else
					spec = [spec, 8]

			# Rule 4, string behaves as SQL "Like"
			if _.isString(spec)
				spec = ['REGEX', '.*' + spec + '.*']

			# Spec should be an array by now, if it isn't, there's a problem.
			if not _.isArray(spec)
				throw { message: "Specification is invalid.", name: name, property: property, spec: spec}

			# Rule 3, only floats are allowed in operator position
			if _.isNumber(spec[0])
				return (entity) ->
					Math.abs(entity[name] - spec[0]) < Math.pow(2, -spec[1])

			# Rule 8, AND specs.
			if _.isArray(spec[0])
				spec[i] = _sieve(name, property, spec[i]) for s, i in spec
				return (entity) ->
					for filter in spec
						if not filter(entity)
							return false
					return true

			# Rule 6, several valid operators.
			switch spec[0]
				when "="  then return (entity) -> entity[name] == spec[1]
				when "<=" then return (entity) -> entity[name] <= spec[1]
				when ">=" then return (entity) -> entity[name] >= spec[1]
				when "<"  then return (entity) -> entity[name] <  spec[1]
				when ">"  then return (entity) -> entity[name] >  spec[1]
				when "REGEX" then return (entity) -> ("" + entity[name]).match(spec[1])
				# Rule 7, IN list
				else return (entity) ->
					while field = spec.shift
						if entity[name] is field
							return true
					return false

	root.JEFRi.LocalStore = LocalStore