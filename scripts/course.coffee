# Description:
#   General course functions
#
# Commands:
#   hubot course set students - makes call to WDI app and writes students hash to 'lib/students.json'

fs    = require 'fs'
_     = require 'underscore'

module.exports = (robot) ->

  robot.respond /set students/i, (msg) ->
    msg.http('http://app.ga-instructors.com/api/courses/6/students?email=neel.patel@generalassemb.ly&auth_token=f1855098c59f9379a028986962d3af81')
      .get() (error, response, body) ->
        if err
          msg.send "ERROR - #{err}"
        else
          parsedresponse = JSON.parse body
          fs.writeFile "./lib/students.json", body, (err) ->
            if err
              msg.send "ERROR - #{err}"
            else
              msg.send "Students have been set"

  robot.respond /get students/i, (msg) ->
    fs.readFile "./lib/students.json", (err, data) ->
      msg.send "/code " + data.toString()
      
