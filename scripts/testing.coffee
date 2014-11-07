_       = require 'underscore'
global.moment = require 'moment-timezone'
util = require 'util'
module.exports = (robot) ->

  # save = (obj) ->
  #   robot.brain.data.cronJobs.push obj

  getDate = () ->
    now = moment()
    console.log "#{(moment.tz now.format(), "America/New_York").day()}"

  testFunc = ->
    console.log this
    console.log "hello"

  robot.respond /cron date/i, (msg) ->
    pattern = "*/10 * * * * *"
    func = getDate
    timezone = "America/New_York"

    robot.emit "cron created", {
      pattern: pattern,
      func: func
      timezone: timezone
      description: "Gets the bloody date"
      }

  robot.respond /cron testfunc/i, (msg) ->
    pattern = "*/10 * * * * *"
    func = testFunc
    timezone = "America/New_York"

    robot.emit "cron created", {
      pattern: pattern,
      func: func
      timezone: timezone
      }

  robot.respond /get date/i, (msg) ->
    getDate()


    # newJob = new Job pattern, getDate
    #
    # console.log newJob
    #
    # newJob.createCron()
    # save (util.inspect newJob)
    # newJob.startJob()

  robot.respond /save test/i, (msg) ->
    robot.brain.data.cronJobs.push "TESTING!"

  # class Job
  #   constructor: (@pattern, @func) ->
  #     @id = Math.floor(Math.random() * 10000) + Date.now()
  #
  #   # save: (robot) ->
  #   #   console.log "in save"
  #   #   robot.brain.data.cronJobs.push this
  #
  #   startJob: () ->
  #     @cronJob.start()
  #
  #   stopJob: () ->
  #     @cronJob.stop()
  #
  #   createCron: (optionsHash) ->
  #     console.log "in create"
  #     pattern = @pattern
  #     func = @func
  #     @cronJob = new CronJob pattern, =>
  #       func(optionsHash)
  #     , ->
  #       console.log "job ended"
  #     , false
  #     console.log "finished creating"
