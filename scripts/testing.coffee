CronJob = require("cron").CronJob
_       = require 'underscore'
moment = require 'moment-timezone'
util = require 'util'
JSONfn = require 'json-fn'


module.exports = (robot) ->

  # save = (obj) ->
  #   robot.brain.data.cronJobs.push obj

  getDate = (params) ->
    # console.log this
    moment2 = params || moment
    # if moment?
    #   console.log "exists"
    #   now = moment()
    # else
    #   console.log module.children[1].exports
    #   console.log module.children[1].exports()
    #   moment = module.children[1].exports
    #   now = moment()
    now = moment2()
    console.log "#{(moment2.tz now.format(), "America/New_York").day()}"

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
