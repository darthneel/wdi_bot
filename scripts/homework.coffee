# Description:
#   Ability to manage hw for the WDI Rosencrantz class
#
# Commands:
#   hubot close pr - Close all open pull requests
#   hubot pr count - Returns count of open pull requests

_   = require 'underscore'
fs  = require 'fs'
moment = require 'moment-timezone'

#===== Cron functions

messageRoom = (robot) ->
  # pattern = "*/10 * * * * *"
  pattern = "00 15 9 * * 1-5"
  url = "#{process.env.HEROKU_URL}/hubot/morningmessage"
  timezone = "America/New_York"
  description = "Messages room at 9:15am to remind students to submit their hw"

  robot.emit "cron created", {
    pattern: pattern,
    url: url,
    timezone: timezone,
    description: description,
    }

hwHandler = (robot) ->
  pattern = "00 30 9 * * 1-5"
  url = "#{process.env.HEROKU_URL}/hubot/handlehw"
  timezone = "America/New_York"
  description = "At 9:30am will automatically push status to WDI api and close all pull requests"

  robot.emit "cron created", {
    pattern: pattern,
    url: url,
    timezone: timezone,
    description: description,
    }

module.exports = (robot) ->

  #==== Initiate all Cron jobs once database has connected
  robot.brain.on 'loaded', () ->
    messageRoom(robot)

  #==== Helper functions

  instructorsHash = ->
    buffer = fs.readFileSync "./lib/instructors.json"
    JSON.parse buffer.toString()

  studentsHash = ->
    buffer = fs.readFileSync "./lib/students.json"
    JSON.parse buffer.toString()

  validate = (msg) ->
    instructors = Object.keys instructorsHash()
    if msg.message.user.name in instructors
       return true
    else
      return false

  getOpenPulls = (msg, cb) ->
    robot.http("https://api.github.com/search/issues?access_token=#{process.env.HUBOT_GITHUB_TOKEN}&per_page=100&q=repo:#{process.env.COURSE_REPO}+type:pull+state:open")
      .headers("User-Agent": "darthneel")
      .get() (err, response, body) ->
        parsedBody = JSON.parse body
        cb parsedBody

  closePullRequest = (msg, pullRequest) ->
    url = pullRequest.pull_request.url
    queryString = JSON.stringify("commit_message": "merged")
    instructorRoom = process.env.HUBOT_INSTRUCTOR_ROOM
    robot.http(url + "/merge?access_token=#{process.env.HUBOT_GITHUB_TOKEN}")
      .headers("User-Agent": "#{process.env.GITHUB_USER_NAME}")
      .put(queryString) (err, response, body) ->
        throw err if err
        if typeof msg is 'string'
          robot.messageRoom instructorRoom "Pull request for user #{pullRequest.user.login} has been closed"
        else
          msg.send "Pull request for user #{pullRequest.user.login} has been closed"

  closeAllPullRequests = (msg) ->
    getOpenPulls msg, (allPullRequests) ->
      if allPullRequests.items.length is 0
        if msg?
          msg.send "No open pull requests at this time"
      else
        _.each allPullRequests.items, (pullRequest) ->
          closePullRequest(msg, pullRequest)

  checkIncompletes = (msg) ->
    getOpenPulls msg, (allPullRequests) ->
      submittedGithubAccounts = _.pluck (_.pluck allPullRequests.items, 'user'), 'login'

      students = studentsHash()
      githubAccounts = _.pluck students, 'github'

      noPullRequest = _.difference githubAccounts, submittedGithubAccounts

      msg.send "Students with no open pull requests: \n #{noPullRequest.join('\n')}"

  checkHW = (msg) ->
    console.log "checking!"
    now = moment()
    if (moment.tz now.format(), "America/New_York").day() isnt 1
      date = (now.subtract 1, 'day').format "YYYY-MM-DD"
    else
      date = (now.subtract 3, 'day').format "YYYY-MM-DD"

    console.log date

    students = studentsHash()

    getOpenPulls msg, (allPullRequests) ->
      console.log "in get open pulls"
      _.each students, (student) ->

        payload = {
          homework: {
            student_id: student['id'],
            date: date
          }
        }

        studentMatch = _.find(allPullRequests["items"], (pr) ->
          pr["user"]["login"] is student["github"])

        if studentMatch
          payload["homework"]["completeness"] = (JSON.parse studentMatch["body"])["completeness"]
          payload["homework"]["comfortability"] = (JSON.parse studentMatch["body"])["comfortability"]
          payload["homework"]["status"] = "complete"
        else
          payload["homework"]["status"] = "incomplete"

        robot.http("http://app.ga-instructors.com/api/courses/#{process.env.COURSE_ID}/homework?email=#{process.env.EMAIL}&auth_token=#{process.env.WDI_AUTH_TOKEN}")
          .headers("Content-Type": "application/json")
          .put( JSON.stringify(payload) ) (err, response, body) ->
            console.log "made api call"
            console.log response
            throw err if err
            if msg?
              msg.send "HW updated for #{student["fname"]} #{student["lname"]}"
            else
              robot.messageRoom process.env.HUBOT_INSTRUCTOR_ROOM, "HW updated for #{student["fname"]} #{student["lname"]}"


  #===== HTTP Routes

  robot.router.get "/hubot/morningmessage", (req, res) ->
    studentRoom = process.env.HUBOT_STUDENT_ROOM
    instructorRoom = process.env.HUBOT_INSTRUCTOR_ROOM
    now = moment()
    weekdays = [0..5]
    if (moment.tz now.format(), "America/New_York").day() in weekdays
      robot.messageRoom studentRoom, "Reminder: Please submit yesterday's work before 9:30am"
      robot.messageRoom instructorRoom, "Update: Students have been reminded to submit their homework before 9:30am"
      res.end "Response sent to room"
    else
      res.end "Wrong day!"

  robot.router.get "/hubot/handlehw", (req, res) ->
    studentRoom = process.env.HUBOT_STUDENT_ROOM
    instructorRoom = process.env.HUBOT_INSTRUCTOR_ROOM
    now = moment()
    weekdays = [0..5]
    if (moment.tz now.format(), "America/New_York").day() in weekdays
      checkHW()
      # closeAllPullRequests("msg")
      # robot.messageRoom instructorRoom, "Update: Students have been reminded to submit their homework before 9:30am"
      res.end "Response sent to room"
    else
      res.end "Wrong day!"


  #==== Hipchat Response patterns

  robot.respond /close all pr/i, (msg) ->
    if validate(msg)
      closeAllPullRequests(msg)
    else
      msg.send "Sorry, you're not allowed to do that"

  robot.respond /pr count/i, (msg) ->
    if validate(msg)
      getOpenPulls msg, (allPullRequests) ->
        msg.send "There are currently #{allPullRequests.items.length} open pull requests"
    else
      msg.send "Sorry, you're not allowed to do that"

  robot.respond /incompletes/i, (msg) ->
    if validate(msg)
      checkIncompletes(msg)
    else
      msg.send "Sorry, you're not allowed to do that"

  robot.respond /check hw/i, (msg) ->
    if validate(msg)
      checkHW(msg)
    else
      msg.send "Sorry, you're not allowed to do that"
