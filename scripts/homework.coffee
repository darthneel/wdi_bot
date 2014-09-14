# Description:
#   Ability to manage hw for the WDI Rosencrantz class
#
# Commands:
#   Working on it

_ = require 'underscore';

module.exports = (robot) ->
#   closePullRequest = (pullRequest) ->
#     console.log pullRequest
#     url = pullRequest.pull_request.url
#     queryString = JSON.stringify("commit_message": "merged")
#     msg.http(url + "/merge?access_token=#{process.env.HUBOT_GITHUB_TOKEN}")
#       .headers("User-Agent": "#{process.env.GITHUB_USER_NAME}")
#       .put(queryString) (err, response, body) ->
#         if err
#           console.log err
#         else
#           user = JSON.parse pullRequest.user
#           # console.log user.login
#           console.log "Merged for #{user.login}"

  robot.respond /close pr/i, (msg) ->
    msg.http("https://api.github.com/search/issues?access_token=#{process.env.HUBOT_GITHUB_TOKEN}&per_page=100&q=repo:ga-students/rosencrantz+type:pull+state:open")
        .headers("User-Agent": "darthneel")
        .get() (err, response, body) ->
          parsedBody = JSON.parse body
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
                  msg.send "Pull requests have been closed"

  robot.respond /username/i, (msg) ->
    username = process.env.GITHUB_USER_NAME
    test = msg.message.user
    console.log test
    msg.send test.id
