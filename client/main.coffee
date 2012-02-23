$ ->
  
  ###
  # Core Model and Logic 
  ###
  class Question extends Backbone.Model
    initialize: ->
      @assignments = new Assignments()
      @assignments.add(@get('assignments'))

  class Assignment extends Backbone.Model
    answer: (ans) ->
      @save(
        answer:
          value: ans
      )

  class Assignments extends Backbone.Collection
    model: Assignment
    localStorage: new Store('assignments')

  class Questions extends Backbone.Collection
    model: Question
    localStorage: new Store('questions')
    
  ###
  # View
  ###
  
  Templates = {}
  Templates[e.id] = $(e).html() for e in $('#templates').children()
  
  class AssignmentView extends Backbone.View
    tagName: 'li'
    template: Templates.assignment
    initialize: ->
      @id = @model.id
      @model.bind('change', @render, @)
    render: ->
      $(@el).html(@template)
      @$('#score').hide()
      @$('#grader').hide()
      @$('#assignment-text').hide()
      @$('#answer').submitView(tools: @$('#submit'))
      a = @model.get('answer')
      if a?
        answer.text(a.value).attr('readonly', 'readonly')
        @$('#score').text(a.correctness * 100).show()  if a.confidence >= 0.5
        
      $(@el)
    answer: ->
      @model.answer(@$('#answer').val())
  
  class QuestionView extends Backbone.View
    tagName: 'li'
    className: 'question'
    template: Templates.question
    initialize: ->
      @id = @model.id
    render: -> 
      $(@el).html(@template)
      @$('#question-text').text(@model.get('value'))
      @addAll()
      return $(@el)
    addOne: (item) ->
      a = new AssignmentView(model: item)
      $(a.render()).appendTo(@$('#content'))
    addAll: ->
      for item in @assignments()
        @addOne(item)
    assignments: -> myAssignments.question(@model)

  class StreamView extends Backbone.View
    initialize: ->
      @$('#newquestion').html(Templates.assignment).find('#assignment-text').submitView(tools: @$('#newquestion').find('#submit'))
      myQuestions.bind('add',   @addOne, this)
      myQuestions.bind('reset', @addAll, this)
      myQuestions.fetch()
    addOne: (item) ->
      q = new QuestionView(model: item)
      $(q.render()).appendTo(@$('#assignments'))
    addAll: -> 
      myQuestions.each(@addOne)
    newQuestion: ->
  
  myQuestions = new Questions()
  App = new StreamView(el: $('#learn'))
    
  ###
  # Routes
  ###
  # TODO: fix router
  class Workspace extends Backbone.Router
    routes:
      '/:id' : 'assign'
    assign: (id) ->
      myAssignments.get(id)
      myAssignments.fetch()
  
  app_router = new Workspace()