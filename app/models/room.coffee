module.exports = (compound, Room) ->

  Room = compound.models.Room
  Line = compound.models.Line
  
  Room.getOrCreate = (name, params, user, callback) ->
    fixed = params.fixed
    Room.findOne({name: name}).populate('creator').exec (err, room) -> 
      # return an existing room
      return callback err, room, false if (err or room)

      # create a new room
      if not room
        settings = {fixed: false} if not fixed or not user
        settings = {fixed: true} if fixed and user
        Room.create {name: name, settings: settings, creator: user?._id, createdAt: new Date}, (err, room) ->
          callback err, room, true

  Room.get = (name, callback) ->
    Room.findOne {name: name}, callback
      
  Room.prototype.kill = (callback=->) ->
    return callback 'cannot remove a fixed room' if @settings.fixed
    compound.models.Line.remove {room: @id}, (err) =>
      console.error err if err
      console.log "Removed lines from ##{@name}"
      @remove (err) =>
        console.log "Room.prototype.kill #{@name}"
        callback err

  Room.prototype.addLine = (data, callback=->) ->
    return callback() if not @settings.fixed
    data.createAt = new Date
    data.room = @id
    compound.models.Line.create data, callback

  Room.prototype.getLines = (limit, skip, callback) ->
    Line.find {room: @id, type: {$ne: 'system'}}, null, {limit: limit, skip: skip, sort: '-createdAt'}, (err, lines) ->
      callback err, lines