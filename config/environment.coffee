module.exports = (compound) ->

  crypto = require 'crypto'
  express = require 'express'
  app = compound.app
  io = require('socket.io').listen compound.server, {log: false}

  app.configure ->
    app.enable 'coffee'

    app.set 'cssEngine', 'stylus'
    compound.loadConfigs __dirname

    # make sure you run `npm install railway-routes browserify`
    # app.enable 'clientside'
    app.use express.static(app.root + '/public', maxAge: 86400000)
    app.use express.urlencoded()
    app.use express.json()
    app.use express.cookieParser 'mnsjsu477383hfhbvgata5151ref'
    # app.use express.session secret: 'secret'
    app.use express.methodOverride()
    app.locals.title = 'chantbox.io'
    # app.use (req, res, next) ->
    #   res.cookie 'user_id', crypto.createHash('md5').update((+(new Date)).toString()).digest('hex')
    #   next()
    app.locals.assets_timestamp = +(new Date)
    app.use app.router

  io.sockets.on 'connection', (socket) ->
    require('../app/events/rooms')(io.sockets, socket)