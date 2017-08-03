// var assert = require('assert'),
//       vows = require('vows'),
//     github = require('../../src/octonode');
//
// vows.describe('client').addBatch({
//   'get a user via url': {
//     topic: function() {
//       var client = github.client();
//       client.get('/users/kmanzana')
//       .then(function(data) {
//         this.callback(data);
//       });
//     },
//     'should be a 200': function(user) {
//       assert(user.statusCode).is(200);
//     },
//   }
// }).export(module);
