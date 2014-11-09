# Description:
#   Allows for the creation and maintence of Cron jobs.
#
# Commands:


CronJob = require("cron").CronJob
_       = require 'underscore'
JSONfn = require 'json-fn'

JOBS = {}

module.exports = (robot) ->
  robot.brain.data.cronJobs ?= {}

  robot.on "cron created", (cron) ->
    console.log cron
    job = new Job cron.pattern, cron.func, cron.timezone, cron.description
    job.createCron()
    job.startJob()
    save job
    JOBS[job.id] = job

  robot.brain.on 'loaded', () ->
    console.log "DB HAS LOADED"
    _.each robot.brain.data.cronJobs, (job, id) ->

      func = JSONfn.parse job["func"]

      job = new Job job["pattern"], func, job["timezone"], job["description"], job["running"]
      job.id = id
      job.createCron()
      if job.running is true
        job.startJob()
      JOBS[job.id.toString()] = job

  save = (obj) ->
    func = JSONfn.stringify obj.func
    robot.brain.data.cronJobs[obj.id] = {pattern: obj.pattern, func: func, timezone: obj.timezone, description: obj.description, running: obj.running}

  #===== Functions being called in robot.respond callbacks ======
  allJobs = ->
    console.log robot.brain.data.cronJobs

  stringifyJobs = ->
    list = robot.brain.data.cronJobs
    _.reduce list, (reply, job, id) ->
      reply += "\n"
      reply += "Job Number: #{id} - #{job.description}. Currently Running: #{job.running}"
      reply
    , ""


  #===== Functions available for Cron ========

  uptimePing = (optionsHash) ->
    msg = optionsHash["msg"]
    msg.http("#{process.env.HEROKU_URL}/hubot/ping")
      .post() (err, res, body) ->
        console.log(body)
# http://fathomless-garden-6223.herokuapp.com/hubot/ping
  # ===== Response patterns =====

  robot.respond /cron ping/i, (msg) ->
    pattern = "0 0,10,20,30,40,50 * * * *"
    newJob = new Job pattern, uptimePing
    newJob.createCron {"msg": msg}
    newJob.save robot
    newJob.startJob()

  robot.respond /l(ist)? active jobs/i, (msg) ->
    console.log robot.brain.data.cronJobs

  robot.respond /k(ill)? job (\d{7})/i, (msg) ->
    jobNumber =  msg.match[2]
    console.log typeof jobNumber
    console.log msg.match
    job = JOBS[jobNumber]
    console.log job
    if job? and job.running is true
      job.stopJob()
      robot.brain.data.cronJobs[jobNumber]["running"] = false
      job.running = false
      msg.send "Job #{job.id} has been stopped"
    else
      msg.send "Error: The job number you entered is either not running or does not exist"

  robot.respond /l(ist)? jobs/i, (msg) ->
    msg.send stringifyJobs()

  robot.respond /s(tart)? job (\d{7})/i, (msg) ->
    jobNumber =  msg.match[2]
    job = JOBS[jobNumber]
    if job? and job.running is false
      job.startJob()
      robot.brain.data.cronJobs[jobNumber]["running"] = true
      job.running = true
      msg.send "Job #{job.id} has been started"
    else
      msg.send "Error: The job number you entered is either already running or does not exist"
      msg.send "Use the command 'l all jobs' to check the job number"

  # robot.respond /start job (\d{1}) - ((\*?(\/?\d+)? ?){6})/i, (msg) ->
  #   jobNumber = msg.match[1]
  #   pattern = msg.match[2]
  #   if pattern.split(" ").length isnt 6
  #     msg.send "Crontab pattern is not valid, please try again"
  #   else
  #     job = robot.brain.data.potentialJobs[msg.match[1] - 1]
  #     newJob = new Job pattern, job.function
  #     newJob.createCron {"msg": msg}
  #     newJob.save robot
  #     newJob.startJob()
  #
  #     msg.send "Cron Job for #{job.name} has been started!"

  robot.respond /clear brain/i, (msg) ->
    robot.brain.data.cronJobs = {}

# ======= Class definitions =======

class Job
  constructor: (@pattern, @func, @timezone, @description, running) ->
    @id = this.generateID()
    @running = running or false

  generateID: () ->
    now = Date.now().toString()
    now.substring(now.length - 7, now.length)

  startJob: () ->
    @cronJob.start()
    @running = true

  stopJob: () ->
    @cronJob.stop()
    @running = false

  createCron: (optionsHash) ->
    console.log "in create"
    @cronJob = new CronJob @pattern, =>
      @func(optionsHash)
    , ->
      console.log "job ended"
    , false
    , @timezone
    console.log "finished creating"
