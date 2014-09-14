# Description:
#   Ability to manage hw for the WDI Rosencrantz class
#
# Commands:
#   Working on it

_ = require 'underscore';

module.exports = (robot) ->

  fGetKeys = (obj) ->
    keys = []
    for key of obj
      keys.push key
    keys

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

  robot.respond /username/i, (msg) ->
    username = process.env.GITHUB_USER_NAME
    user = msg.message.user
    keys = fGetKeys(user)
    console.log keys
    msg.send "name - #{user.name}, mention_name - #{user.mention_name}"
