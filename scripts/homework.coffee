# Description:
#   Ability to manage hw for the WDI Rosencrantz class
#
# Commands:
#   hubot close pr - Close all open pull requests

_ = require 'underscore';

module.exports = (robot) ->

  getOpenPulls = (msg, cb) ->
    instructors = ["Jeff Konowitch", "Neel Patel","Sean West"]
    if msg.message.user.name in instructors
      msg.http("https://api.github.com/search/issues?access_token=#{process.env.HUBOT_GITHUB_TOKEN}&per_page=100&q=repo:ga-students/rosencrantz+type:pull+state:open")
        .headers("User-Agent": "darthneel")
        .get() (err, response, body) ->
          parsedBody = JSON.parse body
          cb parsedBody
    else
      msg.send "Sorry, you are not allowed to do that"

  robot.respond /close pr/i, (msg) ->
    instructors = ["Jeff Konowitch", "Neel Patel","Sean West"]
    if instructors.indexOf(msg.message.user.name) != -1
      msg.http("https://api.github.com/search/issues?access_token=#{process.env.HUBOT_GITHUB_TOKEN}&per_page=100&q=repo:ga-students/rosencrantz+type:pull+state:open")
          .headers("User-Agent": "darthneel")
          .get() (err, response, body) ->
            parsedBody = JSON.parse body
            console.log parsedBody.items[0].user.login
            if parsedBody.items.length == 0
              msg.send "No open pull requests at this time"
            else
              _.each parsedBody.items, (pullRequest) ->
                console.log pullRequest
                url = pullRequest.pull_request.url
                queryString = JSON.stringify("commit_message": "merged")
                msg.http(url + "/merge?access_token=#{process.env.HUBOT_GITHUB_TOKEN}")
                  .headers("User-Agent": "#{process.env.GITHUB_USER_NAME}")
                  .put(queryString) (err, response, body) ->
                    if err
                      console.log err
                      msg.send 'ERROR'
                    else
                      console.log pullRequest.user.login
                      msg.send "Pull request for user #{pullRequest.user.login} has been closed"
    else
      msg.send "Sorry, you are not allowed to do that"

  robot.respond /open pulls/i, (msg) ->
    getOpenPulls msg, (pulls) ->
      msg.send "There are currently #{pulls.items.length} open pull requests"
