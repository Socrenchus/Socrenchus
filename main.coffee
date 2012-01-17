$(document).ready ->
  
  ###
  Make a request to the server with optional callback.
  ###
  serverRequest = (function_name, opt_argv) ->
    opt_argv = new Array() unless opt_argv
    callback = null
    len = opt_argv.length
    if len > 0 and typeof opt_argv[len - 1] is "function"
      callback = opt_argv[len - 1]
      opt_argv.length--
    query = "action=" + encodeURIComponent(function_name)
    i = 0

    while i < opt_argv.length
      key = "arg" + i
      val = JSON.stringify(opt_argv[i])
      query += "&" + key + "=" + encodeURIComponent(val)
      i++
    query += "&time=" + new Date().getTime()
    
    $.ajax(
      type: "GET",
      url: '/rpc',
      data: query,
      dataType: "json",
      complete: (xhr,textStatus) ->
        if textStatus is 'parsererror'
          $('#welcome').show()
          $('#logout').text('Login')
      success: (data, textStatus) ->
        callback(data)
    )
    
    
  ###
  Handle prepending questions to stream.
  ###
  prependQuestions = (data) ->
    if data
      i = 0
      while i < data.length
        $('#' + data[i].key).remove()
        loadQuestion(data[i], true)
        i++
  
  ###
  Send answer and handle reply.
  ###
  answerQuestion = (qid, ans) ->
    serverRequest('answer', [qid, ans, (data) ->
      window.scrollTo(0,0)
      prependQuestions(data)
    ])
    
  ###
  Send assign and handle reply.
  ###
  assignQuestion = (qid) ->
    serverRequest('assign', [qid, prependQuestions])
        

  ###
  Build a question template by class.
  ###
  getQuestionTemplate =
    
    aQuestion: (d) ->
      item = $('#templates > #assignment').clone()
      item.attr('id', d.key)
      item.find('#submit').hide()
      item.find('#score').hide()
      item.find('#grader').hide()
      item.render = () -> # function called after template is placed
      return item

    aShortAnswerQuestion: (d) ->
      item = getQuestionTemplate['aQuestion'](d)
      item.find('#assignment-text').text('Answer the question above to the best of your ability.')
      answer = item.find('#answer')
      if d.answer or d.answer is 0
        answer.text(d.answer.value).attr('readonly', 'readonly')
        item.find('#score').text(d.answer.correctness * 100).show()  if d.answer.confidence >= 0.5
      else
        submit = item.find('#submit').click(->
          answerQuestion(d.key, item.find('#answer').val())
        )
        answer.focusin(->
          submit.show()
          answer.removeClass('defaultTextActive')
          if answer.val() is answer.attr('title')
            answer.text('')
        ).focusout(->
          if answer.val() is ''
            submit.hide()
            answer.text answer.attr('title')
            answer.addClass('defaultTextActive')
        ).focusout()
      return item

    aGraderQuestion: (d) ->
      item = getQuestionTemplate['aQuestion'](d)
      item.find('#grader').show()
      item.find('#assignment-text').text('Grade the following answer to the above question.')
      item.find('#answer').text(d.answerInQuestion.value).attr('readonly', 'readonly')
      options = slide: (event, ui) ->
        item.find('#grade').text(ui.value)

      slider = item.find('#slider')
      if not d.answer and d.answer isnt 0
        submit = item.find('#submit').click(->
          answerQuestion(d.key, item.find('#grade').text())
        )
        slider.focusin ->
          submit.show()
          item.find('#grade').text('0')
      else
        options['disabled'] = true
        options['value'] = d.answer
        item.find('#grade').text(d.answer)
      slider.slider(options)
      return item

    aBuilderQuestion: (d) ->
      if d.answer
        item = $('#templates > #stats').clone()
        item.attr('id', d.key)
        questionURL = "http://#{window.location.host}/#{d.answer.key}"
        item.find('#addThis').attr('addthis:url', questionURL)
        item.find('#report').attr('href', "/#{d.key}/report.csv")
        
        ###
        Draw the plot and toolbox at template render time.
        ###
        item.render = () ->
          addthis.toolbox('.addthis_toolbox')
          plot1 = []
          plot2 = []
          if d.hasOwnProperty('gradeDistribution')
            $.each(d.gradeDistribution, (key, object) ->
              plot1.push [ key * 10, object ])
            $.each(d.confidentGradeDistribution, (key, object) ->
              plot2.push [ key * 10, object ])
            $.plot($("##{d.key} > #chart"), [
              label: 'Graded by Algorithm'
              data: plot1
              bars:
                show: true
                barWidth: 10
                align: 'center'

              stack: true
            ,
              label: 'Graded by You'
              data: plot2
              bars:
                show: true
                barWidth: 10
                align: 'center'

              stack: true
             ],
              yaxis:
                show: true

              xaxis:
                show: true)
        
        return item
      item = getQuestionTemplate['aShortAnswerQuestion'](d)
      txt = 'It should be something that will help you lead into the rest of your material. It should also have at least one right answer.'
      item.find('#assignment-text').text(txt)
      return item

    aFollowUpBuilderQuestion: (d) ->
      item = getQuestionTemplate['aBuilderQuestion'](d)
      unless d.answer
        txt = 'What will you ask your students next...'
        item.find('#assignment-text').text txt
      return item
  
  ###
  Load an individual question to the stream.
  ###
  loadQuestion = (d, prepend) ->
    prepend = false if typeof (prepend) is 'undefined'
    d.answer = null if d.answer is `undefined`
    unless $('#' + d.question.key).length
      item = $('#templates > #question').clone()
      item.attr 'id', d.question.key
      if prepend
        item.prependTo '#assignments'
      else
        item.appendTo '#assignments'
      item.find('#question-text').text(d.question.value).autoResize().trigger('keydown')
    else $('#' + d.question.key).prependTo '#assignments'  if prepend
    questionTemplate = null
    $.each d._class, (key, object) ->
      tmp = getQuestionTemplate[object]
      questionTemplate = tmp(d)  if tmp

    str = "##{d.question.key} > div > #content"
    if prepend
      questionTemplate.prependTo(str)
    else
      questionTemplate.appendTo(str)
    $('#' + d.key).find('.autoResizable').autoResize(extraSpace: 0).trigger('keydown')
    
    questionTemplate.render()

  ###
  Load the stream.
  ###
  navPage = 0
  isFirstRun = true
  do reloadStream = ->
    initializeStuff = (data) ->
      $('#logout').text('Logout')
      $('#logout').attr('href', data.logout)
      classes = $('#classes')
      classes.selectable(
        unselecting: (event, ui) ->
          $('.ui-unselecting').addClass('ui-last-selected')
        unselected: (event, ui) ->
          unless classes.find('.ui-selecting').length
            $('.ui-last-selected').addClass('ui-selected')
          $('.ui-last-selected').removeClass('ui-last-selected')
        selected: (event, ui) ->
          if ui.selected.id is 'create'
            window.location = '/newclass'
      ).mouseover((obj) ->
        classes.children().show()
      ).mouseout((obj) ->
        classes.children().hide()
        classes.find('.ui-selected, .ui-selecting').show()
      )
      $('#nextPage').click((obj) ->
        navPage++
        reloadStream()
      )

    loadWithData = (data) ->
      data.forEach (d) ->
        loadQuestion d

      if data.length >= 15
        $('#nextPage').show()
      else
        $('#intro').clone().appendTo('#assignments')
        $('#nextPage').hide()

    pageSize = 15
    start = pageSize * navPage
    serverRequest('stream', [navPage, (data) ->
      return if data is ''
      if isFirstRun
        isFirstRun = false
        initializeStuff(data)
      return loadWithData(data.assignments)
    ])
  
  ###
  Check for database key in URL.
  ###
  do ->
    urlPathString = decodeURI(window.location.pathname)
    urlPathArray = urlPathString.split('/')
    if urlPathArray.length is 3 and urlPathArray[2]
      assignQuestion(urlPathArray[2], '')
  
