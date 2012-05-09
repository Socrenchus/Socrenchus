Meteor.startup ->
  if Lists.find().count() is 0
    data = [
      {
        name: "Meteor Principles",
        contents: 
          [
            ["Data on the Wire", "Simplicity", "Better UX", "Fun"],
            ["One Language", "Simplicity", "Fun"],
            ["Database Everywhere", "Simplicity"],
            ["Latency Compensation", "Better UX"],
            ["Full Stack Reactivity", "Better UX", "Fun"],
            ["Embrace the Ecosystem", "Fun"],
            ["Simplicity Equals Productivity", "Simplicity", "Fun"]
          ]
      },
      {
        name: "Languages",
        contents: 
          [
            ["Lisp", "GC"],
            ["C", "Linked"],
            ["C++", "Objects", "Linked"],
            ["Python", "GC", "Objects"],
            ["Ruby", "GC", "Objects"],
            ["JavaScript", "GC", "Objects"],
            ["Scala", "GC", "Objects"],
            ["Erlang", "GC"],
            ["6502 Assembly", "Linked"]
          ]
      },
      {
        name: "Favorite Scientists",
        contents: 
          [
            ["Ada Lovelace", "Computer Science"],
            ["Grace Hopper", "Computer Science"],
            ["Marie Curie", "Physics", "Chemistry"],
            ["Carl Friedrich Gauss", "Math", "Physics"],
            ["Nikola Tesla", "Physics"],
            ["Claude Shannon", "Math", "Computer Science"]
          ]
      }
    ]
    timestamp = (new Date()).getTime()
    i = 0

    while i < data.length
      list_id = Lists.insert(name: data[i].name)
      j = 0

      while j < data[i].contents.length
        info = data[i].contents[j]
        Todos.insert
          list_id: list_id
          text: info[0]
          timestamp: timestamp
          tags: info.slice(1)

        timestamp += 1
        j++
      i++
