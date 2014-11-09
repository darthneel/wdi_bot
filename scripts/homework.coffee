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
  pattern = "*/10 * * * * *"
  # pattern = "00 30 9 * * 1-5"
  url = "#{process.env.HEROKU_URL}/hubot/roomtest"
  timezone = "America/New_York"
  description = "Crons room message"

  robot.emit "cron created", {
    pattern: pattern,
    url: url,
    timezone: timezone,
    description: "Messages room",
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

  getOpenPulls = (msg, cb) ->
    instructors = Object.keys instructorsHash()
    console.log msg.message.user.name
    if msg.message.user.name in instructors
      msg.http("https://api.github.com/search/issues?access_token=#{process.env.HUBOT_GITHUB_TOKEN}&per_page=100&q=repo:#{process.env.COURSE_REPO}+type:pull+state:open")
        .headers("User-Agent": "darthneel")
        .get() (err, response, body) ->
          parsedBody = JSON.parse body
          cb parsedBody
    else
      msg.send "Sorry, you are not allowed to do that"

  closePullRequest = (msg, pullRequest) ->
    url = pullRequest.pull_request.url
    queryString = JSON.stringify("commit_message": "merged")
    msg.http(url + "/merge?access_token=#{process.env.HUBOT_GITHUB_TOKEN}")
      .headers("User-Agent": "#{process.env.GITHUB_USER_NAME}")
      .put(queryString) (err, response, body) ->
        throw err if err
        console.log pullRequest.user.login
        msg.send "Pull request for user #{pullRequest.user.login} has been closed"

  checkIncompletes = (msg) ->
    getOpenPulls msg, (allPullRequests) ->
      submittedGithubAccounts = _.pluck (_.pluck allPullRequests.items, 'user'), 'login'

      students = studentsHash()
      githubAccounts = _.pluck students, 'github'

      noPullRequest = _.difference githubAccounts, submittedGithubAccounts

      msg.send "Students with no open pull requests: \n #{noPullRequest.join('\n')}"

  checkHW = (msg) ->
    now = moment()
    if (moment.tz now.format(), "America/New_York").day() isnt 1
      date = (now.subtract 1, 'day').format "YYYY-MM-DD"
    else
      date = (now.subtract 3, 'day').format "YYYY-MM-DD"

    students = studentsHash()

    getOpenPulls msg, (allPullRequests) ->
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

        msg.http("http://app.ga-instructors.com/api/courses/#{process.env.COURSE_ID}/homework?email=#{process.env.EMAIL}&auth_token=#{process.env.WDI_AUTH_TOKEN}")
          .headers("Content-Type": "application/json")
          .put( JSON.stringify(payload) ) (err, response, body) ->
            throw err if err
            msg.send "HW updated for #{student["fname"]} #{student["lname"]}"

  #===== HTTP Routes

  robot.router.get "/hubot/students", (req, res) ->
    students = studentsHash()
    res.end "#{students}"

  robot.router.get "/hubot/roomtest", (req, res) ->
    room = process.env.HUBOT_HIPCHAT_ROOMS
    now = moment()
    weekdays = [0..5]
    if (moment.tz now.format(), "America/New_York").day() in weekdays
      robot.messageRoom room, "Reminder: Please submit yesterday's work before 9:30am"
      res.end "Response sent to room"
    else
      res.end "Wrong day!"

  robot.router.get "/hubot/anothertest", (req, res) ->
    room = process.env.HUBOT_HIPCHAT_ROOMS
    robot.messageRoom room, "Testing, testing, 1..2..3.."
    res.end "sent some things"

  #==== Hipchat Response patterns
  
  robot.respond /close all pr/i, (msg) ->
    getOpenPulls msg, (allPullRequests) ->
      if allPullRequests.items.length is 0
        msg.send "No open pull requests at this time"
      else
        _.each allPullRequests.items, (pullRequest) ->
          closePullRequest(msg, pullRequest)

  robot.respond /pr count/i, (msg) ->
    getOpenPulls msg, (allPullRequests) ->
      msg.send "There are currently #{allPullRequests.items.length} open pull requests"

  robot.respond /incompletes/i, (msg) ->
    checkIncompletes(msg)


  robot.respond /inc test/i, (msg) ->
    checkIncompletes(msg)

  robot.respond /check hw/i, (msg) ->
    checkHW(msg)
