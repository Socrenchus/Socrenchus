$(document).ready ->
  
  ###
  Send answer and handle reply.
  ###
  answerQuestion = (qid, ans) ->
    window.history.pushState('', '', '/')
    scrollTo(0, 0)
    $.getJSON('/ajax/answer',
      question_id: qid
      answer: ans, 
      (data) ->
        if data
          i = 0
          while i < data.length
            $('#' + data[i].key).remove()
            loadQuestion(data[i], true)
            i++)

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
          if answer.text() is answer.attr('title')
            answer.text('')
            answer.removeClass('defaultTextActive')
        ).focusout(->
          submit.hide()
          if answer.text() is ''
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
        item.find('#share > input').attr('value', questionURL)
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

  navPage = 0
  myCache = null
  do reloadStream = ->
    initializeStuff = (data) ->
      $('#logout').attr('href', data.logout)
      $('#nextPage').click (obj) ->
        navPage++
        reloadStream()

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
    if not myCache or myCache.length >= start
      $.getJSON('/ajax/stream',
        segment: navPage, 
        (data) ->
          return  if data is ''
          unless myCache?
            myCache = data.assignments
            initializeStuff(data)
          else
            myCache = myCache.concat(data.assignments)
          return loadWithData(myCache.slice(start, start + pageSize))
        )
    else
      return loadWithData(myCache.slice(start, start + pageSize))
  
  ###
  Check for database key in URL.
  ###
  do ->
    urlPathString = decodeURI(window.location.pathname)
    urlPathArray = urlPathString.split('/')
    if urlPathArray.length is 2 and urlPathArray[1]
      answerQuestion(urlPathArray[1], '')
  
