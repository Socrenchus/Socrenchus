#when _debug is on, all db actions are executed ignoring the errors which are printed on console
#when off, db actions are blocked if any errors are encountered.
_debug = true

class GrandCentral
  constructor: (@collection, @method) ->
    @default =
      Meteor.default_server.method_handlers["/#{@collection}/#{@method}"]
    Meteor.default_server.method_handlers["/#{@collection}/#{@method}"] =
      @dispatch
      
  error_list = []
  dispatch: (args...) =>
    {
      users: {
        insert: (args...) =>
          error_list.push('not implemented yet')
        update: (args...) =>
          error_list.push('not implemented yet')
        remove: (args...) =>
          error_list.push('not implemented yet')
      }
      posts: {
        insert: (args...) =>
          console.log "GC post/insert"
          args[0].author_id = Meteor.call('get_user_id')
          args[0].votes = {
            'up': {
              users: []
              weight: 0
            }
            'down': {
              users: []
              weight: 0
            }
          }
          args[0].tags = []
          if (args[0].content == '')
            error_list.push 'blank content in post/insert'
        update: (args...) =>
          update_user_id = Meteor.call('get_user_id')
          #tagging, voting also comes in here
          console.log "raw args: "
          console.log args
          console.log "args[0]: "
          console.log args[0]
          console.log "args[1]: "
          console.log args[1]
          #for voting
          if (args[0]._id? and args[1].$set?)
            #console.log args
            #if (args[1].$set?)
            if (args[1].$set.my_vote?)
              post = Posts.find(args[0]._id).fetch()
              console.log 'post to be updated in mongo'
              console.log post
              if (args[1].$set.my_vote)
                console.log "found up_vote from #{update_user_id}"
                #console.log _.keys(post.votes)
                new_args0 = "{_id: #{args[0]._id}}"
                new_args1 = "{$push: {votes.up.users: #{update_user_id}}, $inc: {votes.up.weight: 1}})"
                args[0] = new_args0
                args[1] = new_args1
                console.log 'formatted args'
                console.log args
                ###
                this syntax works when tried in mongo
                 db.posts.update({'content': 'whattsup'}, {'$push': {'votes.up.users': 'made up id'}, '$inc': {'votes.up.weight': 1}})
                *TODO: my_vote seems to be changing with clicking, not other fields though
                ###
                
              else
                console.log "found down_vote from #{update_user_id}"
                
          #error_list.push('this GrandCentral function (posts/update) is a work in progress')
        remove: (args...) =>
      }
      instances: {
        insert: (args...) =>
          error_list.push('not implemented yet')
        update: (args...) =>
          error_list.push('not implemented yet')
        remove: (args...) =>
      }
    }[@collection][@method](args...)
    if (error_list.length is 0 or @_debug)
      @default.apply(@, args)
    if (error_list.length>0)
      console.error (error_list)
    #console.info 'GrandCentral is operational!!'
    error_list = []


Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      gc = new GrandCentral(collection, method)
)
