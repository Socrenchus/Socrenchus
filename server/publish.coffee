Lists = new Meteor.Collection("lists")
Meteor.publish "lists", ->
  Lists.find()

Todos = new Meteor.Collection("todos")
Meteor.publish "todos", (list_id) ->
  Todos.find list_id: list_id
