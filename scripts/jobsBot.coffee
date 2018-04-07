# Description:
#   I'm the jobsBot of GDC written by https://github.com/thanosIrodotou
#

redis = require "redis"
fs = require "fs"

jobs_prefix = "jobs"

DEFAULT_REDIS_URI = process.env.REDIS_URL
redisClient = redis.createClient(DEFAULT_REDIS_URI)

validateUrl = (value) ->
  return /^(?:(?:(?:https?|ftp):)?\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:[/?#]\S*)?$/i.test(value);

getDataset = (prefix, callback) -> redisClient.get("#{prefix}:storage", (err, reply) -> callback(err, JSON.parse(reply)))

syncToLocalFile = (data) ->
  fs.writeFile "data/job_links.json", JSON.stringify(data), (err) ->
    console.log("Could not backup listings to file.") if err

syncToRedis = (data) ->
  redisClient.set("#{jobs_prefix}:storage", JSON.stringify(data))

resetRedis = () ->
  localData = JSON.parse(fs.readFileSync "data/job_links.json", "utf8")
  redisClient.set("#{jobs_prefix}:storage", JSON.stringify(localData))

postMessage = (robot, res, message, settings) ->
    room = res.message.user.room
    defaultSettings = if !settings then {as_user: false, username: "gdcBot", link_names: false, unfurl_links: false} else settings
    robot.adapter.client.web.chat.postMessage(
      room, message, settings
    )

react = (robot, res, reaction) ->
  robot.adapter.client.web.reactions.add reaction, {channel: res.user.room, timestamp: res.rawMessage.ts}

module.exports = (robot) ->
  robot.respond /commands/i, (res) ->
    postMessage robot, res,
      "
      ```
      bot jobs -> returns the current list of jobs\n\n
      bot addJob <url> -> adds a new job listing\n\n
      bot deleteJob <index> -> deletes the job listing at the provided index
      ```
      "

  getDataset jobs_prefix, (error, dataset) ->
    if error
      res.send "#{error}"
    else
      data = dataset
      if data == null
        res.send "Can't talk to redis - setting job data from local backup"
        fs.readFile "data/job_links.json", (err, localData) ->
          syncToRedis localData
      else
        syncToLocalFile data

      robot.respond /jobs/i, (res) ->
        response = ""
        index = 0
        if data.jobs.length == 0
          postMessage robot, res, ":tumbleweed:"
        else
          for job in data.jobs
            index += 1
            response += "#{index} - #{job.url} - posted by - @#{job.posted_by} - on `#{job.posted_on}`\n"
          postMessage robot, res, response

      robot.respond /addJob /i, (res) ->
        extracted_url = res.message.text.split(" ")[2]
        if validateUrl(extracted_url)
          data.jobs.unshift {url: extracted_url, posted_by: res.message.user.name, posted_on: new Date().toUTCString()}
          syncToRedis data
          syncToLocalFile data
          react robot, res.message, "thumbsup"
        else
          react robot, res.message, "thumbsdown"

      robot.respond /deleteJob( (\d+))?/i, (res) ->
        index = parseInt(res.match[1])
        if !index
          react robot, res.message, "thumbsdown"
        else
          index--;
          if index >= data.jobs.length || index < 0
            react robot, res.message, "thumbsdown"
          else
            data.jobs.splice(index, 1)
            react robot, res.message, "thumbsup"
            syncToLocalFile data
            syncToRedis data
