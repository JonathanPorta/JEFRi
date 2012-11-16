/*global QUnit:false, module:false, test:false, asyncTest:false, expect:false*/
/*global start:false, stop:false ok:false, equal:false, notEqual:false, deepEqual:false*/
/*global notDeepEqual:false, strictEqual:false, notStrictEqual:false, raises:false*/

_jQuery document .ready !->
	runtime = null
	module do
		"Object Storage"
		setup: !->
			# Clear localStorage
			for o of localStorage
				delete localStorage[o]

			# Global in testing environment.
			runtime := new JEFRi.Runtime "/test/qunit/min/context/user.json", store: JEFRi.ObjectStore

	asyncTest "ObjectStore minimal save", !->
		expect 3
		runtime.ready.done !->
			user = runtime.build "User", {name: "southerd", address: "davidsouther@gmail.com"}
			user.authinfo runtime.build 'Authinfo', {}
			authinfo = user.authinfo 

			runtime.save_new!then !(transaction)->
				ok transaction.entities && transaction.attributes, "Transaction entities and attributes."
				equal transaction.entities.length, 2, "Transaction should only have 2 entities."
				nkeys = _.keys transaction.entities[0]
				deepEqual nkeys.sort!, <[ _id _fields _relationships _modified _new _runtime modified persisted ]>.sort!, "Entity has expected keys."
				# This is a really bad assertion...
				# equal _.symmetricDifference _.keys transaction.entities[0]._fields), ["user_id", "name", "address"]).length, 0, "Entity has unexpected fields."
				start!

	users = [
		["David Souther", "davidsouther@gmail.com", {username: "southerd", activated: "true", created: new Date(2011, 1, 15, 15, 34, 5).toJSON!, last_ip: "192.168.2.79"}],
		["JPorta", "jporta@example.com", {username: "portaj", activated: "true", created: new Date(2012, 1, 15, 15, 34, 5).toJSON!, last_ip: "192.168.2.80"}],
		["Niemants", "andrew@example.com", {username: "andrew", activated: "false", created: new Date(2012, 1, 17, 15, 34, 5).toJSON!, last_ip: "80.234.2.79"}]
	];

	asyncTest "ObjectStore", !->
		expect 5
		runtime.ready.done !->
			for u in users
				user = runtime.build "User", {name: u[0], address: u[1]}
				authinfo = runtime.build "Authinfo", _.extend({authinfo_id: user.id!}, u[2])
				user.authinfo authinfo

			runtime.save_new!then !->
				_.when(
					runtime.get {_type: "User"} .then (results)->
						equal results.User.length, 3, "Find users."

					runtime.get {_type: "Authinfo", username: "southerd"} .then (results)->
						equal results.Authinfo.length, 1, "Find southerd."
					runtime.get {_type: "User", authinfo: {}} .then (results)->
						equal results.Authinfo.length, 3, "Included authinfo relations."
						# Check that users and authinfos point to eachother...
					runtime.get {_type: "User", authinfo: {created: [">", new Date(2012, 1, 1).toJSON!]}} .then (results)->
						equal results.Authinfo.length, 2, "Included and filtered authinfo relations."
						equal results.User.length, 2, "Only included filtered relations."
				).done !->
					start!
