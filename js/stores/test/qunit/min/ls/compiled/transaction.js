_jQuery(document).ready(function(){
  var runtime;
  runtime = null;
  module("Transaction", {
    setup: function(){
      runtime = new JEFRi.Runtime("/test/qunit/min/context/user.json", {
        storeURI: "/test/"
      });
    }
  });
  asyncTest("Transaction Basics", function(){
    expect(1);
    runtime.ready.done(function(){
      var user, authinfo, transaction;
      user = runtime.build("User", {
        name: "southerd",
        address: "davidsouther@gmail.com"
      });
      user.authinfo(runtime.build('Authinfo', {}));
      authinfo = user.authinfo();
      transaction = runtime.transaction();
      transaction.add(runtime._new);
      equal(transaction.entities.length, 2, "Has both entities.");
      start();
    });
  });
});