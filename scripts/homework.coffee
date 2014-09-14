# Description:
#   Ability to manage hw for the WDI Rosencrantz class
#
# Commands:
#   Working on it still

_ = require 'underscore';

students_arr = ['Clayton Albachteh', 'Joe Biggica', 'Jeffrey Campomanes', 'Nastassia Carmona', 'Lee Crawford', 'Daniel Farber', 'Crawford Forbes', 'Conor Hastings', 'Shotaro Kamegai', 'Timoor Kurdi', 'Quardean Lewis-Allen', 'Adrian Lin', 'Yoshie Muranaka', 'Brenda Dargan-Levy', 'Andrea Ortega-Williams', 'Tejal Patel', 'Janine Rosen', 'Tess Shapiro', 'Iris Martinez', 'Lisa Wells', 'Heidi Williams-Foy', 'Eric Kramer', 'Jill Ortenberg', 'Patricia Laws', 'Alex Fong']

module.exports = (robot) ->

  stringifyGroups = (groups) ->
    _.each groups, (el, index) ->
      reply += "/n"
      reply += "Group #{index}"
      reply += "/n"
      reply += el.join(" ")
      reply +=
      reply
    , ""

  robot.respond /random one/, (msg) ->
    student = _.sample(students_arr)
    debugger
    msg.send "Random student - #{student}"

  robot.respond /groupr test me (.*)/, (msg) ->
    one = msg.match[1]
    two = msg.match[2]
    three = msg.match[3]
    msg_full = msg.match
    msg.send "#{one}, #{two}, #{three}, #{msg_full}"

  robot.respond /groupr split (\d+)/, (msg) ->
    groups = []
    group_num = msg.match[1]
    group_size = students_arr.length/group_num
    for i in [0..group_num] by 1
      num = group_size
      group_arr = while num -= 1
        _.shuffle(student_arr)
        students_arr.pop()
      groups.push(group_arr)
    debugger
    # console.log groups
    msg.send "Hello"
