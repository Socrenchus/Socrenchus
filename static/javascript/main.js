//
// Copyright 2011 Bryan Goldstein.
// All rights reserved.
//

$(document).ready(function() {
  //
  // Get URL parameters
  //
  
  var urlParams = {}
  var urlPathString = decodeURI(window.location.pathname);
  var urlPathArray = urlPathString.split('/');
  for (i = 0; i < urlPathArray.length; i++ )
    if (!(i % 2))
      urlParams[urlPathArray[i-1]] = urlPathArray[i];
      
  //
  // Utility functions
  //
  function oc(a)
  {
    var o = {};
    for(var i=0;i<a.length;i++)
    {
      o[a[i]]='';
    }
    if (a.length == 0)
      return null;
    else
      return o;
  }
      
  //
  // Check for certain parameters
  //
  if (urlPathArray.length == 2 && urlPathArray[1])
    $.get('/ajax/answer', {'question_id': urlPathArray[1]});
  //
  // Compile templates
  //
  var templates = [
  'multipleAnswerQuestionTemplate',
  'questionStatsTemplate',
  'confidentGraderQuestionTemplate',
  'shortAnswerQuestionTemplate'
  ]; 
  $.each(templates, function(key, object) { $( '#'+object ).template( object ) });
  
  //
  // Load a question array
  //
  var loadQuestion = function(d) {
    
    // Define message objects by class
    var createMessageObject = function() {
      var messageObj = {'question_id': d.key, 'answer': [], 'class': d._class }
      $.each(d._class, function(key, object) {
        switch ( object ) {
          case 'aBuilderQuestion':
          case 'aShortAnswerQuestion':
            messageObj.answer = $('#'+d.key+' #answer').val();
            break;
          case 'aMultipleChoiceQuestion':
            messageObj.answer = $('input:radio[name='+d.key+']:checked').val();
            break;
          case 'aMultipleAnswerQuestion':
            var data = $('input:checkbox[name='+d.key+']:checked');
            $.each(data, function(key, object) {
              messageObj.answer.push($(this).val());
            });
            if (messageObj.answer.length == 0)
              messageObj.answer.push('None of the above');
            break;
        }
      });
      return messageObj;
    }
    
    // Answer the question (on submit)
    var answerQuestion = function( eventObj ) {
      if (eventObj.target.id == 'submit') {
        window.history.pushState("object or string", "Title", '/');
        scrollTo(0,0);
        
        $.getJSON('/ajax/answer', createMessageObject(), function(data) {
          if (data) {
            var len = data.length;
            if (len) {
              $('#'+d.key).remove();
            }
            for ( var i=0; i<len; i++ ){
              loadQuestion( data[i] );
            }
          }
        });
      }
    }
    
    // Define pre-display functions by class
    if (d.answer == undefined) d.answer = null;
    var getQuestionTemplate = {
      'aMultipleAnswerQuestion' : function() {
        var tmp = d.answer
        if (tmp && tmp.length >= 0) {
          d.answer = [];
          $.each(tmp, function(key, object) { d.answer.push(object.value) });
          d.answer = oc(d.answer);
        }
        return 'multipleAnswerQuestionTemplate';
      },
      'aShortAnswerQuestion' : function() {
        d.confident = d.answer && (d.answer.confidence >= 0.5);
        if (d.answer)
          d.score = d.answer.correctness;
        return 'shortAnswerQuestionTemplate';
      },
      'aConfidentGraderQuestion' : function() {
        d.question.author = d.answerInQuestion.author;
        return 'confidentGraderQuestionTemplate';
      },
      'aBuilderQuestion' : function() {
        if (d.answer) {
          return 'questionStatsTemplate';
        }
        return 'shortAnswerQuestionTemplate';
      }
    };
    
    // Called just after display, by class
    var postDisplay = {
      'aConfidentGraderQuestion' : function() {
        if (d.answer) {
          var plot1 = [];
          var plot2 = [];
          if (d.hasOwnProperty('estimatedGrades')) {
            $.each(d.estimatedGrades, function(key, object) { plot1.push([key,object]) });
            $.each(d.confidentGrades, function(key, object) { plot2.push([key,object]) });
            $.plot($("#chart_"+d.key), [ {
              label: "Grading Algorithm",
              data: plot1
            },   {
                label: "Your Grading",
                data: plot2
            } ], { yaxis: { max: 1, show: false }, xaxis: {show: false} } );
          }
        }
      }
    }
    
    // Execute preparation by class
    var questionTemplate = 'errorTemplate';
    $.each(d._class, function(key, object) {
      var tmp = getQuestionTemplate[object];
      if (tmp) questionTemplate = tmp();
    });
    
    // Render template
    $.tmpl( questionTemplate, d ).prependTo( '#assignments' ).click(answerQuestion);
    
    // Handle post-display stuff
    $.each(d._class, function(key, object) {
      var tmp = postDisplay[object];
      if (tmp) tmp();
    });
    
  }
  
  //
  // Load the question stream
  //
  var reloadStream = function() { 
    $.getJSON('/ajax/stream', function(data) {
      if (data == '') return;
      $( "#learn > div" ).remove();
      $( "#logout" ).attr("href", data.logout);
      data.assignments.forEach( function( d ) {
          loadQuestion( d );
        });
          //
          // Set up autoresizing text areas
          //
          $('.autoResizable').autoResize({
              // On resize:
              onResize : function() {
                  $(this).css({opacity:0.8});
              },
              // After resize:
              animateCallback : function() {
                  $(this).css({opacity:1});
              },
              // Quite slow animation:
              animateDuration : 300,
              // More extra space:
              extraSpace : 40
          });

          //
          // Set up default text construct
          //
          $(function() {
            $(".defaultText").focus(function(srcc)
            {
                if ($(this).val() == $(this)[0].title)
                {
                    $(this).removeClass("defaultTextActive");
                    $(this).val("");
                }
            });

            $(".defaultText").blur(function()
            {
                if ($(this).val() == "")
                {
                    $(this).addClass("defaultTextActive");
                    $(this).val($(this)[0].title);
                }
            });

            $(".defaultText").blur();
          });
    });
  }
  reloadStream();
  
  });