throttle = require '../utils/throttle'

### ---------------------------------------------------------------------------

Recommended data structure

  user = {
    id:          int
    name:        string
    email:       string
    password:    string
    pro:         boolean
    data_task:   object
    data_list:   object
    data_time:   object
    data_pref:   object
    index_task:  int
    index_list:  int
    created_at:  date
    updated_at:  date
  }

#### --------------------------------------------------------------------------

class User

  ###
   * Create a new User instance
   *
   * - [attrs] (object) : optional attributes to load in
   * - [duration] (int) : how long to wait between writes
  ###

  constructor: (attrs, duration=5000) ->
    @_load attrs if attrs
    @_write = throttle @_write, duration


  # Resolve cyclic dependency with Storage controller
  module.exports = User
  Storage = require '../controllers/storage'


  ###
   * (private) Load attributes
   * Just copies keys from one object into the user instance.
   *
   * - attrs (object) : object to copy keys from
   * > this
  ###

  _load: (attrs) ->
    @[key] = value for own key, value of attrs
    return this


  ###
   * (private) Write to database
   * Writes the user data to disk.
   * Will do nothing if the user has been released from memoru.
  ###

  _write: (keys) =>
    return if @_released
    Storage.writeUser this, keys


  ###
   * Set a value on the instance
   * Will also write the change to disk
   *
   * - key (string)
   * - value (*)
   * > value
  ###

  set: (key, value) ->
    @[key] = value
    @_write key
    return value


  ###
   * Get or set user data
   * Prefixes keys with data_.
   * Will create an empty object if the key doesn't exist
   *
   * - key (string)
   * - [replaceWith] (object) : optional object to replace the data with
   * > data
  ###

  data: (key, replaceWith) ->
    key = 'data_' + key
    if replaceWith?
      @[key] = replaceWith
      return replaceWith
    if not this.hasOwnProperty(key)
      return @[key] = {}
    return @[key]


  ###
   * Save data to disk
   *
   * - key (string)
  ###

  save: (key) ->
    key = 'data_' + key
    @_write key


  ###
   * Get the index for a data set
   * Will be set to 0 if it doesn't exist
   *
   * - key (string)
   * > int
  ###

  index: (key) ->
    key = 'index_' + key
    index = @[key]
    return index ? @set key, 0


  ###
   * Increment the index for a data set by one
   * Will be set to 1 if the key doesn't exist
   *
   * - key (string)
   * > int
  ###

  incrIndex: (key) ->
    key = 'index_' + key
    value = @[key] ? 0
    @set key, ++value
    return value


  ###
   * Change a users password and remove all their login tokens
   *
   * - password (string) : the hash of the password
  ###

  setPassword: (password) ->
    @set 'password', password
    Storage.removeAllLoginTokens(@id)


  ###
   * Change a users email and update the email lookup table
   *
   * - email (string) : the email to change to
  ###

  setEmail: (email) ->
    oldEmail = @email
    @set 'email', email
    Storage.replaceEmail @id, oldEmail, email, @service

  ###
   * Get a model by an id for a class.
   * If the model doesn't exist, it will be created as an empty object
   *
   * - classname (string)
   * - id (int)
   * > object
  ###

  findModel: (classname, id) =>
    obj = @data(classname)
    return obj[id] ?= {}


  ###
   * Check if a model exists
   *
   * - classname (string)
   * - id (int)
   * > boolean
  ###

  hasModel: (classname, id) =>
    return @data(classname)?[id]?

  ###
   * Set attributes for a model
   *
   * - classname (string)
   * - id (int)
   * - attributes (object)
   * > object
  ###

  updateModel: (classname, id, attributes) =>
    model = @findModel(classname, id)
    model[key] = value for key, value of attributes
    @save classname
    return model


  ###
   * Replace the attributes for a model
   *
   * - classname (string)
   * - id (int)
   * - attributes (object)
   > attributes
  ###

  setModel: (classname, id, attributes) =>
    @data(classname)[id] = attributes
    @save classname
    return attributes

  ###
   * Get an array of all the active models in a class
   *
   * - classname (string)
   * > object
  ###

  exportModel: (classname) =>
    models = []
    data = @data classname
    return models unless data
    for id, model of data when not model.deleted
      models.push model
    return models

  ###
   * Mark the user as released from memory
  ###

  release: ->
    @_released = true
