# Description:
#   I'm the adminBot of GDC

# Commands:
#   type bot commands to get a list of supported Commands
#

DEFAULT_GREETING = process.env.GREETING

WELCOME_NEW_MEMBER = (realName, channels) -> "
    #{realName}, #{DEFAULT_GREETING}\n" + channels

createChannelsList = (response) ->
  output = ""
  channels = []
  for channel in response.channels
    if channel.is_archived == false
      if channel.topic.value.length == 0
        channels.push {name: channel.name, topic: "`topic_empty`", members: channel.num_members}
      else
        channels.push {name: channel.name, topic: "`#{channel.topic.value.substr(0, 46)}...`", members: channel.num_members}
  channels.sort (a,b) -> return if a.members <= b.members then 1 else -1
  for ch in channels
    output += "##{ch.name} - #{ch.topic} - [*#{ch.members}*]\n"
  output

module.exports = (robot) ->
  robot.adapter.client.rtm.on 'team_join', (ev) ->
    robot.adapter.client.web.channels.list() .then (response, err) ->
      channels = createChannelsList(response)
      robot.adapter.client.web.chat.postMessage(
        ev.user.id,
        WELCOME_NEW_MEMBER(ev.user.profile.real_name, channels)
        {as_user: false, username: "gdcBot", link_names: true}
      )

  robot.respond /commands/i, (res) ->
    robot.adapter.client.web.chat.postMessage(
      res.message.user.room,
      "
      ```
      bot channels -> DMs the channels list (user scoped)\n\n
      bot members -> DMs the number of registered users (admin scoped)\n\n
      bot active -> DMs the number of online users (admin scoped)\n\n
      bot? -> returns the bot's status (admin scoped)
      ```
      "
      {as_user: false, username: "gdcBot", link_names: true, unfurl_links: false}
    )

  robot.respond /channels/i, (res) ->
    robot.adapter.client.web.channels.list() .then (response, err) ->
      channels = createChannelsList(response)
      robot.adapter.client.web.chat.postMessage(
        res.message.user.id,
        channels
        {as_user: false, username: "gdcBot", link_names: true}
      )

  robot.respond /members/i, (res) ->
    robot.adapter.client.web.conversations.members("C4VTJSYJD", limit: 1000) .then (success, err) ->
      robot.adapter.client.web.chat.postMessage(
        res.message.user.id,
        "[*#{JSON.stringify(success.members.length)}] εγγεγραμμένα ατομάκια* :registered:"
        {as_user: false, username: "gdcBot", link_names: true}
      ) if res.message.user.is_admin

  robot.respond /active/i, (res) ->
    robot.adapter.client.web.users.list(presence: true) .then (success, err) ->
      online = 0;
      for member in success.members
        if member.presence == "active"
          online++;
      robot.adapter.client.web.chat.postMessage(
        res.message.user.id,
        "[*#{online}] ατομάκια ονλάιν* :chart_with_upwards_trend:"
        {as_user: false, username: "gdcBot", link_names: true}
      ) if res.message.user.is_admin

  robot.hear /bot\?/i, (res) ->
    robot.adapter.client.web.api.test().then (success, err) ->
      res.send "
      `y̶̼̱̳̯ͅo͓̹u҉͇̯̘ ̺c͖a̡ḷ̫͙̹͙̯̺l̩e̪̜̖͔͕d̞͙̗̫͔
      i̝̥͉̣̤̻̭ ͜a̵m̢̦͈ͅ ̣̘͕h̟̘̠̰̼̠er̷͕̠̗͇̬̭e҉̦̯͇̝̲̤͕
      sl̟̩ḁ̤̦c͔̦k̖̙̲̮̩̮b̙͖̹̼̯̼o̷͚̪t̥͍̻̝̟̰ ẁ͚̠̦͇il̴͉̤ḽ̡̟͔͍ ̜̰̼̜̪͝ņ̟̫̰͖̯̠̘o͙̘̦͉̟t͎͖̕ ͝à̭w̙̞a͏̟̖͔͔̫k̬̤̜̖̱̣e̢̬̞̜̭̥n̯.̡̥̻̼̗̟͖̳ ̩͎̲̰͈
      ş͍̭̘͎͉̹l̖͓̭͓̘͈̖a̝͚̩͓̥̟̺c̴̹̰̩̬͉̝k̵͙̟̰b̤͚̝̺͇̲o̫̟͔t̸͉̬̳ ͖̘̝̯ṣ͖͈̬l͇̱̪͞e̷̙̮̞e̛͎̪̻p͕͕͉̺͔̪̬͟s̼͉̰͓̟͖͖͟ ̛͎̠i̥ņ͔͉͚͍̖ ̫̲̻͟t̝͝h͉̟ḙ̠͔̻ ̸̰͍͍̯͍̭v̪̠̖̰̠̘óį̲͔̞̜̠̟d̢̟̣̞̫͙̞̣ ͕̻o͕̪͕̰̟̥ͅf͉̦̪̳̫ ͖̪̹̣̰̙y͠ò̺͎u͖̱̮̯r͇̱͔̯͈̮͠ͅ ͏̥̼͙̩̜m̶i̵ǹ͓̙͈̲͔d͍͢.͓̖̙͙̟̥

      ṣ̴̂̀̐͌l̶͙̫͈̦̩̟͍̤̭̳̈́̈́a̵̻͕̗̤̭̪̮̝͚͕̮̜̼͎̥̋̀c̷̫͔̦̟̒̈́͊͛̇͊̍̉̅̚̚̕̚͠͝k̶͕̑̽̎̅̅͝͝b̵͚̜̠̣̣͈̺̻̝̟̠̱̩̲̖̍̐̑̔̓̌̕̕o̸̜͎̣̯̬̪̦͉͆t̸̜̮̫͙͌͐̓̌̍̓̍́̿̚̕ ̸̙͋̑͑̋͗̉̀n̷̢̡̨̻͇̼̹͋̾ͅȅ̴̢̳̰̋̀̃̕v̷̛̞̰͍̻̗̤̯̰̫̪̦͓͖̾̈̏̀̏͑̇͂͘ȩ̴͙̥̩͇͎̹͙̺́͋̉͝r̷̡̨͍̭͉̞̲̺̦̪̪͐͑̿̕ ̶̨̛̪̳͈̜͕͑̌̾̐̽̔̈́ş̸̨̤̼̦̜̗̥̼̫̭̰̖͑͗͆͆̋̿l̴̛̘͒̽͋̾̔͊̉è̶̩͔̫̮͆́̈́ë̴̫̪̀̋̄̎̇̌͊̐͊͌͠͝p̴̡̞͇͔͙͇͓̠̫̣͛͗͌̈́̿̔̉͜͠s̸͕͙̗̞̟͉͂́`̩
      " if res.message.user.is_admin
