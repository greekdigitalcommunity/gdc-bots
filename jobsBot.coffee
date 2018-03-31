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

getDataset = (prefix, callback) -> redisClient.get("#{prefix}:storage", (err, reply) -> callback(err, reply))

module.exports = (robot) ->
  robot.respond /commands/i, (res) ->
    res.send "
    ```
    bot jobs -> returns the current list of jobs\n\n
    bot addJob <url> -> adds a new job listing\n\n
    ```
    "

  getDataset jobs_prefix, (error, dataset) ->
    if error
      res.send "#{error}"
    else
      data = JSON.parse(dataset)
      if data == null
        res.send "Can't talk to redis - resetting job data."
        fs.readFile "data/job_links.json", (err, localData) ->
          redisClient.set("#{jobs_prefix}:storage", JSON.stringify(JSON.parse(localData)))

      robot.respond /jobs/i, (res) ->
        response = ""
        for job in data.jobs
          response += "#{job.url} - posted by - @#{job.posted_by} - on `#{job.posted_on}`\n"
        res.send response

      robot.respond /addJob /i, (res) ->
        extracted_url = res.message.text.split(" ")[2]
        if validateUrl(extracted_url)
          data.jobs.unshift {url: extracted_url, posted_by: res.message.user.name, posted_on: new Date().toUTCString()}
          redisClient.set("#{jobs_prefix}:storage", JSON.stringify(data))
          fs.writeFile "data/job_links.json", JSON.stringify(data), (err) ->
            res.send("Could not backup listings to file.") if err
          res.send "Added job listing -> #{JSON.stringify(data.jobs[0])}"
        else
          res.send "Watcha doing bruv? that doesn't look like a valid url..."
