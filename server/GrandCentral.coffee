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
        insert: =>
          error_list.push('not implemented yet')
        update: =>
          error_list.push('not implemented yet')
        remove: =>
          error_list.push('not implemented yet')
      }
      posts: {
        insert: =>
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
        update: =>
          update_user_id = Meteor.call('get_user_id')
          #tagging, voting also comes in here
          tron.test ->
            console.log "selector: "
            console.log args[0]
            console.log "args[1]: "
            console.log args[1]
          #for voting
          if (args[0]._id? and args[1].$set?)
            #console.log args
            #if (args[1].$set?)
            if (args[1].$set.my_vote?)
              post = Posts.find(args[0]._id).fetch()
              tron.test ->
                tron.log 'post to be updated in mongo'
                tron.log post
              if (args[1].$set.my_vote )
                tron.log "found up_vote from #{update_user_id}"
                new_args0 = 
                  '_id': args[0]._id
                new_args1 =
                  #$push:
                  $addToSet:
                    'votes.up.users': update_user_id
                  $inc:
                    'votes.up.weight': 1
                args[0] = new_args0
                args[1] = new_args1
                tron.test ->
                  tron.log 'formatted args'
                  tron.log args                
              else
                tron.log "found down_vote from #{update_user_id}"
                new_args0 = 
                  '_id': args[0]._id
                new_args1 =
                  #$push:
                  $addToSet:
                    'votes.up.users': update_user_id
                  $inc:
                    'votes.up.weight': 1
                args[0] = new_args0
                args[1] = new_args1
                tron.test ->
                  tron.log 'formatted args'
                  tron.log args 
          #for tagging
          #TODO check if the tag exists, if not, create an empty dictionary, then do below
          if (args[0]['_id']? and args[1]['$set']?)
            tron.log 'client wants to tag'
            for tag_string,weight of args[1]['$set']
              a = tag_string.split('.')
              if a.length is 2 and a[0] is 'tags'
                tron.log 'tag request verified'
                args[1]["$addToSet"]["tags.#{a[1]}.users"] = update_user_id 
                args[1]["$inc"]["tags.#{a[1]}.weight"] = 1
          #error_list.push('this GrandCentral function (posts/update) is a work in progress')
        remove: (args...) =>
          error_list.push('not implemented yet')
      }
      instances: {
        insert: =>
          error_list.push('not implemented yet')
        update: =>
          error_list.push('not implemented yet')
        remove: =>
      }
    }[@collection][@method]()
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
