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
          author_id = Meteor.call('get_user_id')
          tron.test(gctest.insert_post, args[0], author_id)
          #pick out only the appropriate fields
          args[0] =
            _.pick( args[0], 'content', 'parent_id', 'instance_id', '_id')
          if (args[0].content == '')
            error_list.push('blank content in post/insert')
          args[0].author_id = author_id
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
        update: =>
          gctest.run()
          post_id = args[0]
          update_user_id = Meteor.call('get_user_id')
          #tagging, voting also comes in here
          tron.test(->
            tron.log("selector: \n", args[0])
            tron.log("args[1]: \n", args[1])
          )
          if (args[0]._id? and args[1].$set?)
            #for tagging
            if (args[1].$set.my_tags?)
              tron.log('ERMAHGERD, TERGS')
              for my_tags,tag_string of args[1]['$set']
                tron.log('tag_string value:', tag_string)
                #check if tag already exists
                #   may/may not be needed when server logic is in place
                if tag_string in _.keys(Posts.findOne(post_id).tags)
                  tron.log('tag update, no new tag needed')
                  tag_exist = 1
                  #check if user has already used this tag
                  tag_users = _.values(Posts.findOne(post_id).tags["#{tag_string}"].users)
                  if update_user_id in tag_users
                    tron.log 'User has already applied this tag to this post'
                all_tags = _.pick( Posts.findOne(post_id), 'tags')
                #TODO: Tag weight set will differ when updating existing tags
                #      Starts at 1 and inc's, should be changed in server logic
                all_tags.tags[tag_string] ?= {users:[],weight:0}
                all_tags.tags[tag_string].users.push( update_user_id )
                all_tags.tags[tag_string].weight++
                #tron.log('Values of all tags in post:\n', all_tags.tags)
                args[1] = { '$set' : all_tags }
            else
              error_list.push('Posts.update(): Invalid $set parameters')
          else
            error_list.push('Posts.update(): Invalid update request')
                
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
      console.error(error_list)
    #console.info 'GrandCentral is operational!!'
    error_list = []
   


Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      gc = new GrandCentral(collection, method)
)
