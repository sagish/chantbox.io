twitterAPI = require 'node-twitter-api'
twitter = new twitterAPI(require('../../config/twitter')().config)

module.exports = class Auth

  clearCookies = (c) ->
    c.res.cookie k, '', {expires: new Date(+(new Date)-1000000)} for k in Object.keys(c.req.cookies)

  twitter: (c) ->
    if not c.req.query.oauth_token
      console.log 'twitter auth - get request token'
      return twitter.getRequestToken (err, requestToken, requestTokenSecret, results) ->
        return c.send 500, err if err
        c.res.cookie 'requestToken', requestToken, {signed: true}
        c.res.cookie 'requestTokenSecret', requestTokenSecret, {signed: true}
        c.redirect 'https://twitter.com/oauth/authenticate?oauth_token=' + requestToken

    else if c.req.query.oauth_token
      console.log 'twitter auth - get access token'
      requestToken = c.req.signedCookies.requestToken
      requestTokenSecret = c.req.signedCookies.requestTokenSecret

      twitter.getAccessToken requestToken, requestTokenSecret, c.req.query.oauth_verifier, (err, accessToken, accessTokenSecret, results) ->
        return c.send 500, err if err
        twitter.verifyCredentials accessToken, accessTokenSecret, (err, data, response) ->
          return c.send 500, err if err
          console.log 'twitter auth - verified user', data.screen_name
          c.compound.models.User.update {screen_name: data.screen_name}, {$set: {avatar: data.profile_image_url_https}}, {upsert: true}, (err, affected, meta) ->
            c.compound.models.User.findOne {screen_name: data.screen_name}, (err, user) ->
              if not user.createdAt
                user.createdAt = new Date 
                user.save()
              clearCookies(c)
              c.res.cookie 'i', user._id.toString()
              # todo: redirect to refering room
              c.redirect '/?' + (new Date).getTime()

  logout: (c) ->
    clearCookies(c)
    c.redirect c.path_to.root()
