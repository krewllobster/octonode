var github = require('../octonode')
var client = github.client()

var nock = require('nock')
var http = require('http')

describe('client.GET using promises', () => {
  test('returns an array of length 4', () => {
    expect.assertions(3)
    return client.get('/users/kmanzana')
      .then(data => {
        expect(data).toBeDefined()
        expect(Array.isArray(data)).toBe(true)
        expect(data.length).toEqual(4)
      })
  })
})
