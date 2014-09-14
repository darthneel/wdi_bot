# Description:
#   Ability to manage hw for the WDI Rosencrantz class
#
# Commands:
#   Working on it

# _   = require 'underscore';

module.exports = (robot) ->

  # github = require('githubot')(robot)
  # token = github.withOptions(token: process.env.HUBOT_GITHUB_TOKEN)
  #
  robot.respond /pr/i, (msg) ->
  #
  #   user = msg.match[1]
  #   console.log user
  #
  #   github.get "users/#{user}/repos", (repos) ->
  #     console.log repos
  #     msg.send "Fin!"

  # user = msg.match[1]
  # msg.http("https://api.github.com/users/#{user}/repos")
  #     .headers("User-Agent": "darthneel")
  #     .get() (err, response, body) ->
  #
  #       console.log body
  #       msg.send "Fin"

    user = msg.match[1]

    # console.log process.env.HUBOT_GITHUB_TOKEN
    msg.http("https://api.github.com/search/issues?access_token=#{process.env.HUBOT_GITHUB_TOKEN}&per_page=100&q=repo:ga-students/rosencrantz+type:pull+state:open")
        .headers("User-Agent": "darthneel")
        .get() (err, response, body) ->
          parsedBody = JSON.parse body
          console.log parsedBody.items[0].pull_request.url
          queryString = JSON.stringify("commit_message": "merged")
          msg.http(parsedBody.items[0].pull_request.url + "/merge?access_token=#{process.env.HUBOT_GITHUB_TOKEN}")
            .headers("User-Agent": "darthneel")
            .put(queryString) (err, response, body) ->
              result = JSON.parse body
              console.log result
              msg.send "Fin"
