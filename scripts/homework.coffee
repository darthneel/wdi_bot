# Description:
#   Ability to manage hw for the WDI Rosencrantz class
#
# Commands:
#   hubot close pr - Close all open pull requests
#   hubot open pulls - Returns count of open pull requests

_   = require 'underscore';
fs  = require 'fs';
moment = require 'moment'


module.exports = (robot) ->
  robot.brain.data.noPRSubmission ?= []

  instructorsHash = ->
    buffer = fs.readFileSync "./lib/instructors.json"
    JSON.parse buffer.toString()

  studentsHash = ->
    buffer = fs.readFileSync "./lib/students.json"
    JSON.parse buffer.toString()

  getOpenPulls = (msg, cb) ->
    instructors = Object.keys instructorsHash()
    # if msg.message.user.name in instructors
    msg.http("https://api.github.com/search/issues?access_token=#{process.env.HUBOT_GITHUB_TOKEN}&per_page=100&q=repo:ga-students/rosencrantz+type:pull+state:open")
      .headers("User-Agent": "darthneel")
      .get() (err, response, body) ->
        parsedBody = JSON.parse body
        cb parsedBody
    # else
    #   msg.send "Sorry, you are not allowed to do that"

  closePullRequest = (msg, pullRequest) ->
    url = pullRequest.pull_request.url
    queryString = JSON.stringify("commit_message": "merged")
    msg.http(url + "/merge?access_token=#{process.env.HUBOT_GITHUB_TOKEN}")
      .headers("User-Agent": "#{process.env.GITHUB_USER_NAME}")
      .put(queryString) (err, response, body) ->
        throw err if err
        console.log pullRequest.user.login
        msg.send "Pull request for user #{pullRequest.user.login} has been closed"

  robot.respond /close pr/i, (msg) ->
    getOpenPulls msg, (allPullRequests) ->
      if allPullRequests.items.length is 0
        msg.send "No open pull requests at this time"
      else
        _.each allPullRequests.items, (pullRequest) ->
          closePullRequest(msg, pullRequest)

  robot.respond /open pulls/i, (msg) ->
    getOpenPulls msg, (allPullRequests) ->
      msg.send "There are currently #{allPullRequests.items.length} open pull requests"

  robot.respond /incompletes/i, (msg) ->
    getOpenPulls msg, (allPullRequests) ->
      submittedGithubAccounts = _.pluck (_.pluck allPullRequests.items, 'user'), 'login'

      students = studentsHash()
      githubAccounts = _.pluck students, 'github'

      noPullRequest = _.difference githubAccounts, submittedGithubAccounts
      msg.send "#{noPullRequest}"
