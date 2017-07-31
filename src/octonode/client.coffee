#
# client.coffee: A client for github
#
# Copyright © 2011 Pavan Kumar Sunkara. All rights reserved
#

# Requiring modules
request = require 'request'
rp = require 'request-promise-native'
url = require 'url'
global.Promise = require 'bluebird'

Me           = require './me'
User         = require './user'
Repo         = require './repo'
Org          = require './org'
Gist         = require './gist'
Team         = require './team'
Pr           = require './pr'
Release      = require './release'
Issue        = require './issue'
Milestone    = require './milestone'
Label        = require './label'
Notification = require './notification'
extend       = require 'deep-extend'

Search = require './search'

# Specialized error
class HttpError extends Error
  constructor: (@message, @statusCode, @headers, @body) ->

# Initiate class
class Client

  constructor: (@token, @options) ->
    @request = @options and @options.request or request
    @rp = @options and @options.request or request
    @requestDefaults =
      headers:
        'User-Agent': 'octonode/0.3 (https://github.com/pksunkara/octonode) terminal/0.0'
      json: true
      resolveWithFullResponse: true

    if @token and typeof @token == 'string'
      @requestDefaults.headers.Authorization = "token " + @token

  # Get authenticated user instance for client
  me: ->
    Promise.promisifyAll(new Me(@), {multiArgs: true})

  # Get user instance for client
  user: (name) ->
    Promise.promisifyAll(new User(name, @), {multiArgs: true})

  # Get repository instance for client
  repo: (name) ->
    Promise.promisifyAll(new Repo(name, @), {multiArgs: true})

  # Get organization instance for client
  org: (name) ->
    Promise.promisifyAll(new Org(name, @), {multiArgs: true})

  # Get gist instance for client
  gist: ->
    Promise.promisifyAll(new Gist(@), {multiArgs: true})

  # Get team instance for client
  team: (id) ->
    Promise.promisifyAll(new Team(id, @), {multiArgs: true})

  # Get pull request instance for client
  pr: (repo, number) ->
    Promise.promisifyAll(new Pr(repo, number, @), {multiArgs: true})

  release: (repo, number) ->
    Promise.promisifyAll(new Release(repo, number, @), {multiArgs: true})

  # Get search instance for client
  search: ->
    Promise.promisifyAll(new Search(@), {multiArgs: true})

  issue: (repo, number) ->
    Promise.promisifyAll(new Issue(repo, number, @), {multiArgs: true})

  project: (repo, number) ->
    Promise.promisifyAll(new Project(repo, number, @), {multiArgs: true})

  milestone: (repo, number) ->
    Promise.promisifyAll(new Milestone(repo, number, @), {multiArgs: true})

  label: (repo, name) ->
    Promise.promisifyAll(new Label(repo, name, @), {multiArgs: true})

  notification: (id) ->
    Promise.promisifyAll(new Notification(id, @), {multiArgs: true})

  requestOptions: (params1, params2) =>
    return extend @requestDefaults, params1, params2

  # Github api URL builder
  buildUrl: (path = '/', pageOrQuery = null, per_page = null, since = null) ->
    if pageOrQuery? and typeof pageOrQuery == 'object'
      query = pageOrQuery
    else
      query = {}
      if pageOrQuery?
        if since? and since == true
          query.since = pageOrQuery
        else
          query.page = pageOrQuery
      query.per_page = per_page if per_page?
    if @token and typeof @token == 'object' and @token.id
        query.client_id = @token.id
        query.client_secret = @token.secret

    # https://github.com/pksunkara/octonode/issues/87
    if query.q
      q = query.q
      delete query.q
      if Object.keys(query).length
        separator = '&'
      else
        separator = '?'

    urlFromPath = url.parse path

    _url = url.format
      protocol: urlFromPath.protocol or @options and @options.protocol or "https:"
      auth: urlFromPath.auth or if @token and @token.username and @token.password then "#{@token.username}:#{@token.password}" else ''
      hostname: urlFromPath.hostname or @options and @options.hostname or "api.github.com"
      port: urlFromPath.port or @options and @options.port
      pathname: urlFromPath.pathname
      query: query

    if q
      _url += "#{separator}q=#{q}"
      query.q = q

    return _url

  errorHandle: ({statusCode, headers, message, error}, body, cb) ->
    fiveHundredError = new HttpError('Error ' + statusCode, headers, error)
    fourHundredError = new HttpError(message, statusCode, headers, error)
    debugger
    if Math.floor(statusCode/100) is 5
      return cb(fiveHundredError) if cb
      return Promise.reject(fiveHundredError)
    if Math.floor(statusCode/100) is 4
      return cb(fourHundredError) if cb
      return Promise.reject(fourHundredError)
    return cb(null, res.statusCode, body, res.headers) if cb
    return Promise.resolve([null, res.statusCode, body, res.headers])

  # Github api GET request

  get: (path, params..., cb) =>

    options = @requestOptions(
      uri: @buildUrl path, params...
      method: 'GET')

    @request options, (err, res, body) =>
      if err
        return cb(err) if cb
        return Promise.reject(err)
      else
        @errorHandle res, body, cb

  getNoFollow: (path, params..., cb) =>

    @get(path, {followRedirect: false}, params..., cb)

  getOptions: (path, options, params..., cb) =>

    if typeof options != 'object'
      console.log('please pass options object as second arg')
      return undefined

    options = @requestOptions(
      uri: @buildUrl path, params...
      method: 'GET',
      options
    )

    return new Promise((resolve, reject) =>
      @request options, (err, res, body) =>
        return (if cb then cb(err) else reject(err)) if err
        @errorHandle res, body, resolve, reject, cb
      )

  # Github api POST request
  post: (path, content, options, callback) ->
    if !callback? and typeof options is 'function'
      callback = options
      options = {}

    reqDefaultOption =
      uri: @buildUrl path, options.query
      method: 'POST'
      headers: 'Content-Type': 'application/json'

    if content
      reqDefaultOption.body = JSON.stringify content

    reqOpt = @requestOptions extend reqDefaultOption, options
    @request reqOpt, (err, res, body) =>
      return callback(err) if err
      @errorHandle res, body, callback

  # Github api PATCH request
  patch: (path, content, callback) ->
    @request @requestOptions(
      uri: @buildUrl path
      method: 'PATCH'
      body: JSON.stringify content
      headers:
        'Content-Type': 'application/json'
    ), (err, res, body) =>
      return callback(err) if err
      @errorHandle res, body, callback

  # Github api PUT request
  put: (path, content, options, callback) ->
    if !callback and options
      callback = options
      options =
        'Content-Type': 'application/json'
    @request @requestOptions(
      uri: @buildUrl path
      method: 'PUT'
      body: JSON.stringify content
      headers: options
    ), (err, res, body) =>
      return callback(err) if err
      @errorHandle res, body, callback

  # Github api DELETE request
  del: (path, content, callback) ->
    @request @requestOptions(
      uri: @buildUrl path
      method: 'DELETE'
      body: JSON.stringify content
      headers:
        'Content-Type': 'application/json'
    ), (err, res, body) =>
      return callback(err) if err
      @errorHandle res, body, callback

  limit: (callback) =>
    @get '/rate_limit', (err, s, b) ->
      return callback(err) if err
      if s isnt 200 then callback(new HttpError('Client rate_limit error', s))
      else callback null, b.resources.core.remaining, b.resources.core.limit, b.resources.core.reset, b

# Export modules
module.exports = (token, credentials...) ->
  Promise.promisifyAll(new Client(token, credentials...), {multiArgs: true})
