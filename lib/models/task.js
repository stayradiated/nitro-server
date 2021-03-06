const Sequelize = require('sequelize')
const db = require('../db')

const Task = db.define('task', {
  id: {
    primaryKey: true,
    type: Sequelize.UUID,
    defaultValue: Sequelize.UUIDV4,
  },
  name: Sequelize.STRING,
  type: Sequelize.STRING,
  // unlimited. Might have to truncate in the controller.
  notes: Sequelize.TEXT,
  completed: Sequelize.DATE,
  date: Sequelize.DATE,
  deadline: Sequelize.DATE,
  priority: Sequelize.INTEGER,
})

module.exports = Task