# Release Notes for jobs bot

## [v0.0.2]
### Changed
- [x] :warning: ~~bot addJob \<url\> (deprecated)~~
- [x] **jobs are automatically added** by posting a link or a series of links in a single or multiple messages
- [x] **bot jobs** -> the jobs view has changed slightly to reduce noise and take advantage of the extracted job positions

##### Examples
- To add a job listing just post one or more urls separated by space to the designated channel or directly to the bot.  
The bot will first try to validate the url, make a GET request and try to extract the job position from the page's title,  
hence, it's advised to post single job adverts instead of portals. There's also stopword removal when extracting job positions
for words like `job|opening`, etc.  
The bot will reply in a thread to minimise channel spam as shown below:

![addJob1](/examples/images/addJob1.PNG)
---
a successful reply will look like this:  

![addJob2](/examples/images/addJob2.PNG)

---
### [v0.0.1]
#### Command support
- [x] **bot jobs** -> returns the current list of jobs
- [x] **bot addJob <url>** -> adds a new job listing
- [x] **bot deleteJob <index>** -> deletes the job listing at the provided index 

##### Examples
- To add a job listing type: `bot addJob www.test.com` to the appropriate channel  
- If talking directly to the bot just type: `addJob www.test.com`

