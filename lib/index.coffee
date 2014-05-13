fs           = require 'fs'
path         = require 'path'
http         = require 'http'
EventEmitter = require('events').EventEmitter
extend       = require 'lodash.assign'
connect      = require 'connect'
WebSocket    = require 'faye-websocket'
m            = require './middleware'

###*
 * The main function, given a root and options, returns a decorated connect
 * instance pre-loaded with selected middleware.
 *
 * @param  {String} root - the root of the project to be served
 * @param  {*} opts - string, object, or undefined, described below
 * @return {Function} an instance of connect
###

module.exports = charge = (root, opts) ->
  root = path.resolve(root)
  opts = parse_options(root, opts)
  if opts.root then root = path.resolve(opts.root)
  if typeof opts.websockets == 'undefined' then opts.websockets = true
  if opts.write then opts.gzip = false

  app = connect()

  if opts.clean_urls    then app.use(m.hygienist(root))
  if opts.routes        then app.use(m.pathologist(opts.routes))
  if opts.exclude       then app.use(m.escapist(opts.exclude))
  if opts.auth          then app.use(m.publicist(opts.auth))
  if opts.cache_control then app.use(m.archivist(opts.cache_control))
  if opts.write         then app.use(m.journalist(opts.write))

  app.use(m.alchemist(root, { url: opts.url, gzip: opts.gzip }))
  app.use(m.apologist(root, opts.error_page))

  extend(app, new EventEmitter)
  extend(app, { start: start.bind(app, opts.websockets) })
  extend(app, { stop: stop.bind(app) })
  extend(app, { send: send.bind(app, opts.websockets) })

  return app

###*
 * Starts a server using the charge instance. Accepts an optional port
 * and a callback, port defaults to 1111. Also initializes websockets and
 * keeps track of open sockets while the server is running.
 *
 * @param  {Boolean} ws_enabled - private bound variable, ignore
 * @param  {Integer} port - port to start the server on, defaults to 1111
 * @param  {Function} cb - callback, called when server has started
 * @return {Object} node http server instance
###

start = (ws_enabled, port = 1111, cb) ->
  @sockets = []

  if typeof port is 'function'
    cb = port
    port = 1111

  @server = http.createServer(@).listen(port, cb)
  if ws_enabled then initialize_websockets.call(@)

  return @server

###*
 * Stops a running server.
 *
 * @param  {Function} cb [description]
###

stop = (cb) ->
  @server.close(cb)
  delete @server

###*
 * Send a message to the client via websockets.
 *
 * @param  {*} msg - the message you want to send. preferably string or object
 * @param  {Object} opts - additional options passed to faye-websockets
###

send = (ws_enabled, msg, opts) ->
  if not ws_enabled then throw new Error('websockets disabled')
  if not @server then throw new Error('server not running')
  if typeof msg is 'object' then msg = JSON.stringify(msg)
  sock.send(msg, opts) for sock in @sockets

###*
 * The options param can accept a number of different types of input.
 *
 * - A string will be treated as a path to load json config from
 * - An object will be treated as a straight options object
 * - Undefined will try to load from default config paths, default to {}
 *
 * This method takes the direct options arg and parses whatever is given into
 * an object or throws an error if there's an invalid type passed.
 *
 * @private
 * @param  {String} root - charge project root
 * @param  {*} opts - options argument
 * @return {Object} parsed options object
###

parse_options = (root, opts) ->
  exists = (name) -> fs.existsSync(path.resolve(root, name))
  load_json = (name) -> require(path.resolve(root, name))

  return switch typeof opts
    when 'string' then load_json(opts)
    when 'object' then opts
    when 'undefined'
      do ->
        if exists('charge.json') then return load_json('charge.json')
        if exists('superstatic.json') then return load_json('superstatic.json')
        if exists('divshot.json') then return load_json('divshot.json')
        {}
    else throw new Error('invalid options')

###*
 * Initialize websockets listener and keep track of connections.
 * @private
###

initialize_websockets = ->
  @server.on 'upgrade', (req, socket, body) =>
    if WebSocket.isWebSocket(req)
      ws = new WebSocket(req, socket, body)
      ws.on 'open', =>
        @sockets.push(ws)
        @emit('connection')

###*
 * @exports hygienist
 * @exports escapist
 * @exports archivist
 * @exports alchemist
 * @exports apologist
 * @exports publicist
 * @exports pathologist
 * @exports journalist
###

extend(module.exports, m)
