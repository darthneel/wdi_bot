# Description:
#   General course functions
#
# Commands:
#   hubot course set students - makes call to WDI app and writes students hash to 'lib/students.json'

fs    = require 'fs'
_     = require 'underscore'
request = require 'request'


module.exports = (robot) ->

  robot.brain.on 'loaded', () ->
    setStudents()
    setInstructors()

  setStudents = (msg) ->
    url = "http://app.ga-instructors.com/api/courses/#{process.env.COURSE_ID}/students?email=#{process.env.EMAIL}&auth_token=#{process.env.WDI_AUTH_TOKEN}"
    request url, (err, res, body) ->
      throw err if err
      fs.writeFile "./lib/students.json", body, (err) ->
          throw err if err
          if msg
            msg.send "Students have been set"
          else
            console.log "Students set upon server restart"

  setInstructors = (msg) ->
    hash = {"Neel Patel": "darthneel", "Jeff Konowitch": "jkonowitch", "Andrew Fritz": "andrewfritz86", "Eric Kramer": "theerickramer", "Shell": "Shell"}
    json = JSON.stringify hash
    fs.writeFile "./lib/instructors.json", json, (err) ->
      throw err if err
      if msg
        msg.send "Instructors have been set"
      else
        console.log "Instructors set upon server restart"

  studentsHash = ->
    buffer = fs.readFileSync "./lib/students.json"
    JSON.parse buffer.toString()

  robot.respond /students test/i, (msg) ->
    setStudents()

  robot.respond /set students/i, (msg) ->
    setStudents(msg)

  robot.respond /get students hash/i, (msg) ->
    buffer = fs.readFileSync "./lib/students.json"
    hash = buffer.toString()
    msg.send "/code " + hash

  robot.respond /get students arr/i, (msg) ->
    buffer = fs.readFileSync "./lib/students.json"
    hash = buffer.toString()
    arr = _.map hash, (student) ->
      "#{student["fname"]} #{student["lname"]}"
    msg.send "/code " + arr

  robot.respond /set instructors/i, (msg) ->
    setInstructors(msg)

  robot.respond /num of students/i, (msg) ->
    msg.send "#{studentsHash().length}"
