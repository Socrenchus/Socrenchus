#when _debug is on: All db actions are executed
#                   Errors printed on console are ignored
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
          #console.log 'initial Posts.insert fields received:\n', args
          #pick out only the appropriate fields
          args[0] =
            _.pick( args[0], 'content', 'parent_id', 'instance_id', '_id')
          #console.log "after pick statement\n", args
          console.log("GC post/insert")
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
            error_list.push('blank content in post/insert')
        update: =>
          update_user_id = Meteor.call('get_user_id')
          #tagging, voting also comes in here
          tron.test(->
            console.log("selector: \n", args[0])
            console.log("args[1]: \n", args[1]))
          if (args[0]._id? and args[1].$set?)
            #for tagging
            if (args[1].$set.my_tags?)
              tron.log('ERMAHGERD, TERGS')
              for my_tags,tag_string of args[1]['$set']
                tron.log('tag_string value:', tag_string)
                #check if tag already exists
                #   may/may not be needed when server logic is in place
                if tag_string in _.keys(Posts.findOne(args[0]).tags)
                  tron.log('tag update, no new tag needed')
                  tag_exist = 1
                all_tags = _.pick( Posts.findOne(args[0]), 'tags')
                #TODO: Tag weight set will differ when updating existing tags
                #      Currently always 1, should be changed in server logic
                all_tags.tags[tag_string] ?= {users:[],weight:1}
                all_tags.tags[tag_string].users
                  .push( Meteor.call('get_user_id') )
                tron.log('Values of all tags:\n', all_tags.tags)
                update_user_id = Meteor.call('get_user_id')
                args[1] = { '$set' : all_tags }
            else
              args = null
          else
            args = null
                
        remove: (args...) =>
          args = null #currently disallowing removal
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
      console.error(error_list)
    #console.info 'GrandCentral is operational!!'
    error_list = []
   


Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      gc = new GrandCentral(collection, method)
)
