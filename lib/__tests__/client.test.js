var github = require('../octonode')
var client = github.client()
var nock = require('nock')

describe('ErrorHandle works with cb and with promise', function() {
  var statusCode200 = 200
  var statusCode400 = 404
  var statusCode500 = 500
  var headers = 'headers'
  var body = {message: 'message'}
  var resolve = () => 'resolve'
  var reject = () => 'reject'
  var cb = () => 'callback'

  test('returns reject function with 404 error without callback', function() {
    var response = client.errorHandle({statusCode: statusCode400, headers}, body, resolve, reject)
    expect(response).toEqual('reject')
  })

  test('returns reject function with 500 error without callback', function() {
    var response = client.errorHandle({statusCode: statusCode500, headers}, body, resolve, reject)
    expect(response).toEqual('reject')
  })

  test('returns resolve function with 200 response without callback', function() {
    var response = client.errorHandle({statusCode: statusCode200, headers}, body, resolve, reject)
    expect(response).toEqual('resolve')
  })

  test('returns callback function with any status', function() {
    var response = client.errorHandle({statusCode: 1234, headers}, body, resolve, reject, cb)
    expect(response).toEqual('callback')
  })
})

describe('GET followers with promise', function() {
  beforeEach(function() {
    var usersResponsePromise = {
      err: null,
      statusCode: 200,
      body:
       { login: 'krewllobster',
         id: 9201597,
         avatar_url: 'https://avatars2.githubusercontent.com/u/9201597?v=4',
         gravatar_id: '',
         url: 'https://api.github.com/users/krewllobster',
         html_url: 'https://github.com/krewllobster',
         followers_url: 'https://api.github.com/users/krewllobster/followers',
         following_url: 'https://api.github.com/users/krewllobster/following{/other_user}',
         gists_url: 'https://api.github.com/users/krewllobster/gists{/gist_id}',
         starred_url: 'https://api.github.com/users/krewllobster/starred{/owner}{/repo}',
         subscriptions_url: 'https://api.github.com/users/krewllobster/subscriptions',
         organizations_url: 'https://api.github.com/users/krewllobster/orgs',
         repos_url: 'https://api.github.com/users/krewllobster/repos',
         events_url: 'https://api.github.com/users/krewllobster/events{/privacy}',
         received_events_url: 'https://api.github.com/users/krewllobster/received_events',
         type: 'User',
         site_admin: false,
         name: null,
         company: null,
         blog: '',
         location: null,
         email: null,
         hireable: null,
         bio: null,
         public_repos: 23,
         public_gists: 5,
         followers: 2,
         following: 1,
         created_at: '2014-10-13T18:17:45Z',
         updated_at: '2017-07-10T21:28:08Z' },
      headers:
       { server: 'GitHub.com',
         date: 'Thu, 20 Jul 2017 18:50:41 GMT',
         'content-type': 'application/json; charset=utf-8',
         'content-length': '1149',
         connection: 'close',
         status: '200 OK',
         'x-ratelimit-limit': '60',
         'x-ratelimit-remaining': '17',
         'x-ratelimit-reset': '1500576917',
         'cache-control': 'public, max-age=60, s-maxage=60',
         vary: 'Accept',
         etag: '"3546268426ebbf1ad84710a20f00dd2d"',
         'last-modified': 'Mon, 10 Jul 2017 21:28:08 GMT',
         'x-github-media-type': 'github.v3',
         'access-control-expose-headers': 'ETag, Link, X-GitHub-OTP, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset, X-OAuth-Scopes, X-Accepted-OAuth-Scopes, X-Poll-Interval',
         'access-control-allow-origin': '*',
         'content-security-policy': 'default-src \'none\'',
         'strict-transport-security': 'max-age=31536000; includeSubdomains; preload',
         'x-content-type-options': 'nosniff',
         'x-frame-options': 'deny',
         'x-xss-protection': '1; mode=block',
         'x-runtime-rack': '0.031067',
         'x-github-request-id': 'D854:1082:15DBFB:2FF91F:5970FB81' } }

    nock('https://api.github.com')
      .get('/users/krewllobster')
      .reply(200, usersResponsePromise)

    nock('https://api.github.com')
      .get('/users/undefined')
      .replyWithError({code: 'ETIMEDOUT'})
  })

  afterEach(function() {
    nock.cleanAll()
  })

  test('Get: returns object with statusCode, body, and headers on success', () => {
    expect.assertions(5)
    return client.get('/users/krewllobster')
    .then(data => {
      expect(data).toBeDefined()
      expect(typeof data).toEqual('object')
      expect(data.statusCode).toEqual(200)
      expect(data.body).toBeDefined()
      expect(data.headers).toBeDefined()
    })
  })

  test('Get: returns object with err on networkError through catch block', () => {
    expect.assertions(3)
    return client.get('/users/undefined')
      .then(data => {
        expect(data).not.toBeDefined()
      })
      .catch(err => {
        expect(err).toBeDefined()
        expect(typeof err).toBe('object')
        expect(err.err.code).toEqual('ETIMEDOUT')
      })
  })

  test('getNoFollow: returns object with statusCode, body, and headers on success', () => {
    expect.assertions(5)
    return client.getNoFollow('/users/krewllobster')
    .then(data => {
      expect(data).toBeDefined()
      expect(typeof data).toEqual('object')
      expect(data.statusCode).toEqual(200)
      expect(data.body).toBeDefined()
      expect(data.headers).toBeDefined()
    })
  })

  test('getOptions: returns undefined if no options passed', () => {
    expect(client.getOptions('/users/krewllobster')).toBe(undefined)
  })

  test('getOptions: returns object with statusCode, body, and headers on success', () => {
    expect.assertions(5)
    return client.getOptions('/users/krewllobster', {})
    .then(data => {
      expect(data).toBeDefined()
      expect(typeof data).toEqual('object')
      expect(data.statusCode).toEqual(200)
      expect(data.body).toBeDefined()
      expect(data.headers).toBeDefined()
    })
  })
})
