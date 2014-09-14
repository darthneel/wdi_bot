# Description:
#   Deept thoughts
#
# Commands:
# hubot deep


# Configures the plugin
module.exports = (robot) ->
    # waits for the string "hubot deep" to occur
    robot.respond /deep/i, (msg) ->
        # Configures the url of a remote server
        msg.http('http://andymatthews.net/code/deepthoughts/get.cfm')
            # and makes an http get call
            .get() (error, response, body) ->
                # passes back the complete reponse
                parsedbody = JSON.parse body
                # console.log body
                # console.log typeof parsedbody
                # console.log parsedbody
                # console.log parsedbody['thought']
                # console.log parsedbody.thought

                msg.send parsedbody['thought']
