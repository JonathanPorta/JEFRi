/*global QUnit:false, module:false, test:false, asyncTest:false, expect:false*/
/*global start:false, stop:false ok:false, equal:false, notEqual:false, deepEqual:false*/
/*global notDeepEqual:false, strictEqual:false, notStrictEqual:false, raises:false*/
/*global jQuery:false, JEFRi:false, isLocal:false*/

(function($){

var testDone = function(){
	var tests = 3;
	return function(){
		test--;
		if(test <= 0){

		}
	};
};

module("JEFRi Runtime", {
	teardown: function(){
		testDone();
	}
});

test("Underscore utils", function(){
	ok(_.on && _.once && _.off && _.trigger, "Underscore has additional pubsub?");
	ok(_.ajax && _.get && _.post, "Does Underscore have additional ajax?");
});

test("Runtime Prototype", function() {
	ok(JEFRi.Runtime, "JEFRi Runtime is available.");
	var runtime = new JEFRi.Runtime();
	ok(runtime.definition, "JEFRi.Runtime::definition");
	ok(runtime.build, "JEFRi.Runtime::build");
	ok(runtime.intern, "JEFRi.Runtime::intern");
	ok(runtime.expand, "JEFRi.Runtime::expand");
	ok(runtime.save_new, "JEFRi.Runtime::save_new");
	ok(runtime.save_all, "JEFRi.Runtime::save_all");
});

asyncTest("Instantiate Runtime", function() {
	var runtime = new JEFRi.Runtime("testContext.json", {storeURI: "/test/"});
	runtime.ready.done(function(){
		ok(runtime, "Could not load runtime.");
		ok(!!runtime.definition('Authinfo') && !!runtime.definition('User'), "Runtime has the correct entities.");

		var user = runtime.build("User", {name: "southerd", address: "davidsouther@gmail.com"});
		var id = user.id();
		equal(user._status(), "NEW", "Built user should be New");
		ok(user.id().match(/[a-f0-9\-]{36}/i), "User should have a valid id.");
		equal(user.id(), user.user_id(), "User id() and user_id properties must match.");

		user.authinfo(runtime.build('Authinfo', {}));
		var authinfo = user.authinfo();
		equal(authinfo._status(), "NEW", "Built authinfo should be New");
		ok(authinfo.id().match(/[a-f0-9\-]{36}/i), "Authinfo should have a valid id.");
		ok(authinfo.id(true).match(/[a-zA-Z_\-]+\/[a-f0-9\-]{36}/i), "id(true) returns full path.");
		equal(authinfo.user_id(), user.id(), "Authinfo refers to correct user.");
		equal(id, user.id(), "ID not overwritten on entity set.");

		var user2 = runtime.build("User", {name: "portaj", address: "rurd4me@example.com"});
		var authinfo2 = user2.authinfo();
		ok(authinfo2, "Default relationship created.");
		ok(authinfo2.id().match(/[a-f0-9\-]{36}/i), "Authinfo2 should have a valid id.");
		equal(authinfo2.user_id(), user2.id(), "Authinfo2 refers to correct user.");
		equal(authinfo2.user().id(), user2.id(), "Authinfo2 returns correct user.");

		start();
	});
});

test("Transaction Prototype", function(){
	ok(JEFRi.Transaction, "JEFRi Transaction is available.");
	var t = new JEFRi.Transaction();
	ok(t, "Created Transaction");
	ok(t.add, "JEFRi.Transaction::add");
	ok(t.attributes, "JEFRi.Transaction::attributes");
	ok(t.get, "JEFRi.Transaction::get");
	ok(t.persist, "JEFRi.Transaction::persist");
});


asyncTest("Exceptional cases", function(){
	var runtime = new JEFRi.Runtime("testContext.json", {storeURI: "/test/"});
	runtime.ready.done(function(){
		ok(runtime, "Could not load runtime.");

		function badType(){
			var foo = runtime.build("foo");
		}
		checkBadTypeException = function(ex){
			if (ex.match && ex.match(/JEFRi::Runtime::build 'foo' is not a defined type in this context./)) {
				return true;
			}
			return false;
		}
		// checkBadTypeException = "JEFRi::runtime::build 'foo' is not a defined type in the context.";
		raises(badType, checkBadTypeException, "Create bad type generates exception.");

		start();
	});
});

}(_jQuery));
