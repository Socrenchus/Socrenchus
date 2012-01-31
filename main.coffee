$ ->
  
  ###
  # Core Model and Logic 
  ###
  class Class extends Backbone.Model
  class Question extends Backbone.Model
  class Assignment extends Backbone.Model
    defaults:
      question: {}
    answer: (ans) ->
      @save({answer:{value:ans}},{success:@answered})
      @clear()
    answered: (model, response) ->
      myAssignments.add(response)
  
  class Questions extends Backbone.Collection
    model: Question
  
  myQuestions = new Questions()
  
  class Assignments extends Backbone.Collection
    model: Assignment
    url: '/rpc/assignments'
    question: (q) -> @filter (a) -> a.get('question').id is q.id
    add: (items) ->
      super(items)
      items = [items] unless items.length?
      for item in items
        unless myQuestions.get(item.question.id)
          myQuestions.add(new Question(item.question))
          
  class Classes extends Backbone.Collection
    model: Class

  
  myAssignments = new Assignments()
  
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
      @$('#submit').hide()
      @$('#grader').hide()
      $(@el)
    remove: -> $(@el).remove()
    clear: -> @model.destroy()
    
  class aShortAnswerView extends AssignmentView
    events:
      'click #submit': 'answer'
      'focusin' : 'focusin'
      'focusout' : 'focusout'
    render: ->
      super()
      @$('#assignment-text').text('Answer the question above to the best of your ability.')
      
      answer = @$('#answer').focusout()
      a = @model.get('answer')
      if a?
        answer.text(a.value).attr('readonly', 'readonly')
        @$('#score').text(a.correctness * 100).show()  if a.confidence >= 0.5
        
      $(@el)
    focusin: ->
      answer = @$('#answer')
      unless @model.get('answer')?
        @$('#submit').show()
        answer.removeClass('defaultTextActive')
        answer.text('') if answer.val() is answer.attr('title')
    focusout: ->
      answer = @$('#answer')
      if answer.val() is '' and not @model.get('answer')?
        @$('#submit').hide()
        answer.addClass('defaultTextActive')
        answer.text(answer.attr('title'))
    answer: ->
      @model.answer(@$('#answer').val())
    
  class aGraderView extends AssignmentView
    events:
      'click #submit': 'answer'
      'focusin #slider': 'focusin'
    render: ->
      super()
      @$('#grader').show()
      @$('#assignment-text').text('Grade the following answer to the above question.')
      @$('#answer').text(@model.get('answerInQuestion').value).attr('readonly', 'readonly')
      options = slide: (event, ui) =>
        @$('#grade').text(ui.value)

      a = @model.get('answer')
      if a?
        options['disabled'] = true
        options['value'] = a
        @$('#grade').text(a)
      @$('#slider').slider(options)
      $(@el)
    focusin: ->
      @$('#submit').show()
    answer: ->
      @model.answer(@$('#grade').text())
      
  class aFollowUpView extends aShortAnswerView
    render: ->
      unless @model.get('answer')?
        @template = Templates.assignment
        super()
        @$('#assignment-text').text('What will you ask your students next...')
      else
        @template = Templates.stats
        super()
        @$('#assignment-text').hide()
        questionURL = "http://#{window.location.host}/#{@model.id}"
        @$('#addThis').attr('addthis:url', questionURL)
        @$('#report').attr('href', "/#{@model.id}/report.csv")
        $(@el).ready => @draw()
      
      $(@el)
      
    draw: ->
      data = []
      sum = 0
      if @model.get('gradeDistribution')?
        gd = @model.get('gradeDistribution')
        cgd = @model.get('confidentGradeDistribution')
        for key, object of gd
          data.push([ [object, cgd[key]], "#{key * 10}" ])
          sum += object
          sum += cgd[key]
        if false and sum > 0
          @$('#chart').jqbargraph(
            'data': data
            'width': 470
            'colors': ['#242424','#437346'] 
            'animate': false
            'legends': ['Algorithm','You']
            'legend': false
            'barSpace': 0
            )
        else
          @$('#chart').hide()
          @$('#share').removeClass('submitArea')
          @$('#addThis').addClass('addthis_32x32_style')
      addthis.toolbox('.addthis_toolbox')

  
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
      a = null
      switch item.get('class_').pop()
        when 'aShortAnswerQuestion'
          a = new aShortAnswerView({ model: item })
        when 'aGraderQuestion', 'aConfidentGraderQuestion'
          a = new aGraderView({ model: item })
        when 'aFollowUpBuilderQuestion'
          a = new aFollowUpView({ model: item })
        else
          a = new AssignmentView({ model: item })
      $(a.render()).appendTo(@$('#content'))
    addAll: ->
      for item in @assignments()
        @addOne(item)
    assignments: -> myAssignments.question(@model)
    remove: -> $(@el).remove()
    clear: -> @model.destroy()

  class StreamView extends Backbone.View
    initialize: ->
      myQuestions.bind('add',   @addOne, this)
      myQuestions.bind('reset', @addAll, this)
      myAssignments.fetch()
    addOne: (item) ->
      q = new QuestionView(
        model: myQuestions.get(item.get('id'))
      )
      $(q.render()).appendTo(@el)
    addAll: -> 
      myQuestions.each(@addOne)
    remove: -> $(@el).remove()
    clear: -> @model.destroy()
  
  App = new StreamView({el: $('#assignments')})
  
  ###
  # Routes
  ###
  # TODO: fix router
  class Workspace extends Backbone.Router
    routes:
      'newclass': 'newclass'
      'q/:id' : 'assign'
    newclass: ->
      #$.get('/rpc/createClass')
      #myAssignments.fetch()
      b = new ClassBuilderView()
      b.render()
    assign: (id) ->
      myAssignments.get(id)
      myAssignments.fetch()
  
  app_router = new Workspace()
  app_router.newclass()