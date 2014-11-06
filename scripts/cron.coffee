# Description:
#   Allows for the creation and maintence of Cron jobs.
#
# Commands:


CronJob = require("cron").CronJob
_       = require 'underscore'
moment = require 'moment-timezone'
JSONfn = require 'json-fn'

module.exports = (robot) ->
  robot.brain.data.cronJobs ?= {}

  robot.on "cron created", (cron) ->
    console.log cron
    job = new Job cron.pattern, cron.func, cron.timezone
    job.createCron()
    save job
    job.startJob()

  robot.brain.on 'loaded', () ->
    console.log "DB HAS LOADED"
    _.each robot.brain.data.cronJobs, (job) ->

      console.log moment().format()

      func = JSONfn.parse job[1]
      console.log func
      func()

      newJob = new Job job[0], func, job[2]
      newJob.createCron()
      newJob.startJob()

  save = (obj) ->
    robot.brain.data.cronJobs[obj.id] = [obj.pattern, JSONfn.stringify obj.func, obj.timezone]

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


  # ===== Description of function and function name that is available for Cron
  robot.brain.data.potentialJobs = [
    {"name": "testJob", "function": testJob, "description": "Job to test if cron works"},
    {"name": "uptimePing", "function": uptimePing, "description": "Pings Hubot every 10 minutes to keep server up"},
    {"name": "third", "function": third, "description": "Third"}
  ]

  # ===== Response patterns =====

  robot.respond /testing again/i, (msg) ->
    console.log module.children[1].exports()
    # console.log Object.keys module
    # console.log Object.keys module.exports.repl.context.moment()

  robot.respond /cron ping/i, (msg) ->
    pattern = "0 0,10,20,30,40,50 * * * *"
    newJob = new Job pattern, uptimePing
    newJob.createCron {"msg": msg}
    newJob.save robot
    newJob.startJob()


  robot.respond /cron test/i, (msg) ->
    console.log robot
    pattern = "*/15 * * * * *"

    newJob = new Job pattern, testJob
    newJob.createCron {"string": "Hello World", "msg": msg}
    newJob.save robot
    newJob.startJob()

  robot.respond /l(ist)? active jobs/i, (msg) ->
    # console.log JSON.parse robot.brain.data.cronJobs
    console.log robot.brain.data.cronJobs

  robot.respond /d(elete)? all jobs/i, (msg) ->
    _.each robot.brain.data.cronJobs, (job) ->
      job.stopJob()

    robot.brain.data.cronJobs.splice(0, robot.brain.data.cronJobs.length)

  robot.respond /l(ist)? all jobs/i, (msg) ->
    msg.send "\n Use the following format to choose a job to Cron: `start job [JOB NUMBER] - [CRONTAB PATTERN]`"
    msg.send "\n Read up on Crontab patterns: http://www.nncron.ru/help/EN/working/cron-format.htm or http://en.wikipedia.org/wiki/Cron or "
    msg.send "\n Note: This application uses the standard Crontab pattern EXCEPT that it has an additional placeholder for seconds"
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

  robot.respond /clear brain/i, (msg) ->
    console.log robot.brain.data.cronJobs

    robot.brain.data.cronJobs = {}

    # robot.brain.data.cronJobs.splice(0, robot.brain.data.cronJobs.length)

    console.log robot.brain.data.cronJobs


# ======= Class definitions =======

class Job
  constructor: (@pattern, @func, @timezone) ->
    @id = this.generateID()

  generateID: () ->
    now = Date.now().toString()
    now.substring(now.length - 7, now.length)

  save: (robot) ->
    console.log "in save"
    robot.brain.data.cronJobs.push this

  startJob: () ->
    @cronJob.start()

  stopJob: () ->
    @cronJob.stop()

  createCron: (optionsHash) ->
    console.log "in create"
    @cronJob = new CronJob @pattern, =>
      @func(optionsHash)
    , ->
      console.log "job ended"
    , false
    , @timezone
    console.log "finished creating"
