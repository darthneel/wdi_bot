# Description:
#   Allows for the creation and maintence of Cron jobs.
#
# Commands:


CronJob = require("cron").CronJob
_       = require 'underscore';


module.exports = (robot) ->
  # Creates array in db
  robot.brain.data.cronJobs ?= []

  #===== Functions being called in robot.respond callbacks ======
  allJobs = ->
    console.log robot.brain.data.cronJobs

  stringifyPotentialJobs = ->
    list = robot.brain.data.potentialJobs
    _.reduce list, (reply, job) ->
      # console.log reply
      # console.log job
      reply += "\n"
      # reply += "#{job.name} - #{job.description}"
      reply += "#{( list.indexOf job ) + 1}: #{job.name} - #{job.description}"
      reply
    , ""


  #===== Functions available for Cron ========

  testJob = (optionsHash) ->
    string = "Hello World"
    msg = optionsHash["msg"]

    msg.send string

  uptimePing = (optionsHash) ->
    msg = optionsHash["msg"]
    msg.http("#{process.env.HEROKU_URL}/hubot/ping")
      .post() (err, res, body) ->
        console.log(body)

  third = ->
    console.log "third"
    msg.send "third"


  # ===== Description of function and fucntion name that is available for Cron
  robot.brain.data.potentialJobs = [
    {"name": "testJob", "function": testJob, "description": "Job to test if cron works"},
    {"name": "uptimePing", "function": uptimePing, "description": "Pings Hubot every 10 minutes to keep server up"},
    {"name": "third", "function": third, "description": "Third"}
  ]

  # ===== Response patterns =====

  robot.respond /cron test/i, (msg) ->
    console.log robot
    pattern = "*/15 * * * * *"

    newJob = new Job pattern, testJob
    newJob.createCron {"string": "Hello World", "msg": msg}
    newJob.save robot
    newJob.startJob()

  robot.respond /l(ist)? active jobs/i, (msg) ->
    console.log robot.brain.data.cronJobs

  robot.respond /d(elete)? all jobs/i, (msg) ->
    _.each robot.brain.data.cronJobs, (job) ->
      job.stopJob()

    robot.brain.data.cronJobs = []

  robot.respond /l(ist)? all jobs/i, (msg) ->
    msg.send "Use the following format to choose a job to Cron: `start job [JOB NUMBER] - [CRONTAB PATTERN]`"
    msg.send "Read up on Crontab patterns: http://www.nncron.ru/help/EN/working/cron-format.htm or http://en.wikipedia.org/wiki/Cron or "
    msg.send "Note: This application uses the standard Crontab pattern EXCEPT that it has an additional placeholder for seconds"
    msg.send "\n"
    msg.send stringifyPotentialJobs()

  robot.respond /start job (\d{1}) - ((\*?(\/?\d+)? ?){6})/i, (msg) ->
    jobNumber = msg.match[1]
    pattern = msg.match[2]
    if pattern.split(" ").length isnt 6
      msg.send "Crontab pattern is not valid, please try again"
    else
      job = robot.brain.data.potentialJobs[msg.match[1] - 1]
      newJob = new Job pattern, job.function
      newJob.createCron {"msg": msg}
      newJob.save robot
      newJob.startJob()

      msg.send "Cron Job for #{job.name} has been started!"

# ======= Class definitions =======

class Job
  constructor: (@pattern, @func) ->
    @id = Math.floor(Math.random() * 10000) + Date.now()

  save: (robot) ->
    console.log "in save"
    robot.brain.data.cronJobs.push this

  startJob: () ->
    @cronJob.start()

  stopJob: () ->
    @cronJob.stop()

  createCron: (optionsHash) ->
    console.log "in create"
    func = @func
    @cronJob = new CronJob @pattern, =>
      @func(optionsHash)
    , ->
      console.log "job ended"
    , false
    console.log "finished creating"
