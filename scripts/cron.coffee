# Description:
#   Allows for the creation and maintence of Cron jobs.
#
# Commands:


CronJob = require("cron").CronJob
_       = require 'underscore'
request = require 'request'

JOBS = {}

module.exports = (robot) ->
  robot.brain.data.cronJobs ?= {}

  robot.on "cron created", (cron) ->
    console.log cron
    job = new Job cron.pattern, cron.url, cron.timezone, cron.description
    job.createCron()
    job.startJob()
    save job
    JOBS[job.id] = job

  robot.brain.on 'loaded', () ->
    console.log "DB HAS LOADED"
    _.each robot.brain.data.cronJobs, (job, id) ->

      job = new Job job["pattern"], job["url"], job["timezone"], job["description"], job["running"]
      job.id = id
      job.createCron()
      if job.running is true
        job.startJob()
      JOBS[job.id.toString()] = job

  save = (obj) ->
    robot.brain.data.cronJobs[obj.id] = {pattern: obj.pattern, url: obj.url, timezone: obj.timezone, description: obj.description, running: obj.running}

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


  # ===== Response patterns =====

  robot.respond /cron roomer/i, (msg) ->
    pattern = "*/10 * * * * *"
    url = "#{process.env.HEROKU_URL}/hubot/roomtest"
    timezone = "America/New_York"
    description = "Crons room message"

    robot.emit "cron created", {
      pattern: pattern,
      url: url,
      timezone: timezone,
      description: "Messages room",
      }

  robot.respond /l(ist)? active jobs/i, (msg) ->
    console.log robot.brain.data.cronJobs

  robot.respond /k(ill)? job (\d{7})/i, (msg) ->
    jobNumber =  msg.match[2]
    job = JOBS[jobNumber]
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

  robot.respond /clear brain/i, (msg) ->
    robot.brain.data.cronJobs = {}

# ======= Class definitions =======

class Job
  constructor: (@pattern, @url, @timezone, @description, running) ->
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

  createCron: () ->
    console.log "in create"
    @cronJob = new CronJob @pattern, =>
      request @url, (err, res, body) ->
        console.log res
    , ->
      console.log "job ended"
    , false
    , @timezone
    console.log "finished creating"
