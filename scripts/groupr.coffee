# Description:
#   Split class into groups
#
# Commands:
#   hubot groupr one
#   hubot groupr test me
#   hubot groupr split

_ = require 'underscore';
fs  = require 'fs';


module.exports = (robot) ->

  studentsHash = ->
    buffer = fs.readFileSync "./lib/students.json"
    JSON.parse buffer.toString()

  stringifyGroups = (groups) ->
    _.each groups, (el, index) ->
      reply += "/n"
      reply += "Group #{index}"
      reply += "/n"
      reply += el.join(" ")
      reply +=
      reply
    , ""

  robot.respond /random one/i, (msg) ->
    student = _.sample(students_arr)
    msg.send "Random student - #{student}"

  robot.respond /groupr test me (.*)/i, (msg) ->
    one = msg.match[1]
    two = msg.match[2]
    three = msg.match[3]
    msg_full = msg.match
    msg.send "#{one}, #{two}, #{three}, #{msg_full}"

  robot.respond /groupr (\d+)/i, (msg) ->
    groupNum = msg.match[1]

    students = _.map studentsHash(), (student) ->
      student["fname"] + " " + student["lname"]

    console.log students
