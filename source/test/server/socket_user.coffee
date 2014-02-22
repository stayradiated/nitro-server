should      = require('should')
setup       = require('../setup')
token       = require('../../server/controllers/token')
GuestSocket = require('../../server/sockets/guest')
Sandal      = require('./sandal')

describe 'UserSocket', ->

  client = null
  socket = null

  before (done) ->
    setup()
    .then(setup.createUser)
    .then(Sandal.setup)
    .then -> done()
    .done()

  beforeEach (done) ->

    sessionToken = token.createSocketToken(setup.userId)

    client = new Sandal()
    socket = new GuestSocket(client.serverSocket)

    client.emit 'user.auth', sessionToken, (err, user) ->
      should.equal(err, null)
      done()

  afterEach ->
    client.end()

  describe ':user', ->

    describe ':info', ->

      it 'should get user info', (done) ->

        client.emit 'user.info', (err, user) ->
          user.should.have.keys('id', 'name', 'email', 'pro', 'created_at')

          user.id.should.equal(setup.userId)
          user.name.should.equal(setup._user.name)
          user.email.should.equal(setup._user.email)
          user.pro.should.equal(setup._user.pro)
          user.created_at.should.be.a.Date

          done()

  describe ':list', ->

    beforeEach (done) ->
      setup.createList()
      .then(setup.createTimeList)
      .then -> done()
      .done()

    describe ':create', ->

      it 'should create a new list', (done) ->

        data =
          name: 'list_name'

        client.emit 'list.create', data, (err, list) ->
          list.should.have.keys('id', 'userId', 'name')
          done()

    describe ':update', ->

      it 'should update a list', (done) ->

        id = setup.listId

        data =
          name: 'list_name_changed'

        client.emit 'list.update', id, data, (err, list) ->
          list.should.have.keys('id', 'userId', 'name')
          done()

    describe ':destroy', ->

      it 'should destroy a list', (done) ->

        data =
          id: setup.listId

        client.emit 'list.destroy', data, (err, success) ->
          success.should.equal(true)
          done()

  describe ':task', ->

    beforeEach (done) ->
      setup.createList()
      .then(setup.createTask)
      .then(setup.createTimeTask)
      .then -> done()
      .done()

    describe ':create', ->

      it 'should create a task', (done) ->

        data =
          listId: setup.listId
          name: 'task_name'
          notes: ''
          date: 0
          priority: 0
          completed: 0

        client.emit 'task.create', data, (err, task) ->
          should.equal(null, err)

          data.id = task.id
          data.userId = setup.userId
          task.should.eql(data)

          done()

    describe ':update', ->

      it 'should update a task', (done) ->

        id = setup.taskId

        data =
          name: 'task_name_updated'

        client.emit 'task.update', id, data, (err, task) ->
          should.equal(null, err)

          setup._task.name = 'task_name_updated'
          task.should.eql(setup._task)

          done()

    describe ':destroy', ->

      it 'should destroy a task', (done) ->

        data =
          id: setup.taskId

        client.emit 'task.destroy', data, (err, success) ->
          should.equal(null, err)
          success.should.equal(true)

          done()

  describe ':pref', ->

    describe ':update', ->

      beforeEach (done) ->
        setup.createPref()
        .then(setup.createTimePref)
        .then -> done()
        .done()

      it 'should update a pref', (done) ->

        data =
          sort: 1

        client.emit 'pref.update', data, (err, prefs) ->
          should.equal(null, err)

          setup._pref.sort = 1
          prefs.should.eql(setup._pref)

          done()
