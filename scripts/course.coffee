# Description:
#   General course functions
#
# Commands:
#   hubot course set students - makes call to WDI app and writes students hash to 'lib/students.json'

fs    = require 'fs'
_     = require 'underscore'

module.exports = (robot) ->

  robot.respond /set students/i, (msg) ->
    msg.http("http://app.ga-instructors.com/api/courses/#{process.env.COURSE_ID}/students?email=#{process.env.EMAIL}&auth_token=#{process.env.WDI_AUTH_TOKEN}")
      .get() (err, response, body) ->
        throw err if err
        parsedresponse = JSON.parse body
        fs.writeFile "./lib/students.json", body, (err) ->
          throw err if err
          msg.send "Students have been set"

  robot.respond /get students/i, (msg) ->
    fs.readFile "./lib/students.json", (err, data) ->
      msg.send "/code " + data.toString()

  robot.respond /set instructors/i, (msg) ->
    hash = {"Neel Patel": "darthneel", "Jeff Konowitch": "jkonowitch", "Sean West": "sean-west" }
    json = JSON.stringify(hash)
    fs.writeFile "./lib/instructors.json", json, (err) ->
      throw err if err
      msg.send "Instructors have been set"
