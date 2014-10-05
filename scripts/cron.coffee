# Description:
#   Utility commands surrounding Hubot uptime.
#
# Commands:


CronJob = require("cron").CronJob

module.exports = (robot) ->

  robot.respond /cron ping/i, (msg) ->

    job = new CronJob "0 0,10,20,30,40,50 * * * *", ->
      msg.http("http://fathomless-garden-6223.herokuapp.com/hubot/ping")
        .post() (err, res, body) ->
          console.log(body)
    , ->
      console.log "Job has ended"
    , true

    console.log "Cron has initiated!"

    msg.send "Cron job has been started to hit /hubot/ping"
