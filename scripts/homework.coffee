# Description:
#   Ability to manage hw for the WDI Rosencrantz class
#
# Commands:
#   hubot close pr - Close all open pull requests
#   hubot pr count - Returns count of open pull requests

global._   = require 'underscore';
global.fs  = require 'fs';
global.moment = require 'moment-timezone'

getDate = ->
  now = moment();
  "#{(moment.tz now.format(), "America/New_York").day()}"


module.exports = (robot) ->
  # robot.brain.on 'loaded', () ->
  #   console.log "DB HAS LOADED"

  robot.brain.data.noPRSubmission ?= []


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

  checkIncompletes = (getOpenPulls, msg, cb) ->
    getOpenPulls msg, (allPullRequests) ->
      submittedGithubAccounts = _.pluck (_.pluck allPullRequests.items, 'user'), 'login'

      students = studentsHash()
      githubAccounts = _.pluck students, 'github'

      noPullRequest = _.difference githubAccounts, submittedGithubAccounts

      console.log(noPullRequest)

  #==== Response patterns

  robot.router.get "/hubot/students", (req, res) ->
    students = studentsHash()
    res.end "#{students}"

  robot.respond /close pr/i, (msg) ->
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
    getOpenPulls msg, (allPullRequests) ->
      submittedGithubAccounts = _.pluck (_.pluck allPullRequests.items, 'user'), 'login'

      students = studentsHash()
      githubAccounts = _.pluck students, 'github'

      noPullRequest = _.difference githubAccounts, submittedGithubAccounts

      msg.send "Students with no open pull requests: \n #{noPullRequest.join('\n')}"

  # robot.respond /date test/i, (msg) ->
  #   now = moment();
  #   msg.send "#{(moment.tz now.format(), "America/New_York").day()}"

  robot.respond /check hw/i, (msg) ->
    now = moment().format();
    if (moment.tz now, "America/New_York").day() isnt 1
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
