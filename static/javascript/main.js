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
  'questionStatsTemplate',
  'graderQuestionTemplate',
  'shortAnswerQuestionTemplate'
  ]; 
  $.each(templates, function(key, object) { $( '#'+object ).template( object ) });
  
  
  // Define message objects by class
  var createMessageObject = function(d) {
    var messageObj = {'question_id': d.key, 'answer': [], 'class': d._class }
    $.each(d._class, function(key, object) {
      switch ( object ) {
        case 'aConfidentGraderQuestion':
        case 'aGraderQuestion':
          messageObj.answer = $('#'+d.key+' #answer').text();
          break;
        case 'aBuilderQuestion':
        case 'aShortAnswerQuestion':
          messageObj.answer = $('#'+d.key+' #answer').val();
          break;
        case 'aMultipleChoiceQuestion':
          messageObj.answer = $('input:radio[name='+d.key+']:checked').val();
          break;
      }
    });
    return messageObj;
  }
  
  // Define pre-display functions by class
  var getQuestionTemplate = {
    'aShortAnswerQuestion' : function(d) {
      d.confident = d.answer && (d.answer.confidence >= 0.5);
      if (d.answer)
        d.score = d.answer.correctness;
      return 'shortAnswerQuestionTemplate';
    },
    'aGraderQuestion' : function(d) {
      d.question.author = {'nickname':'Personal Assistant'};
      return 'graderQuestionTemplate';
    },
    'aBuilderQuestion' : function(d) {
      d.question = {
        value:'Think of the first question you want to ask your students...'
      };
      if (d.answer) {
        return 'questionStatsTemplate';
      }
      return 'shortAnswerQuestionTemplate';
    }
  };
  
  // Called just after display, by class
  var postDisplay = {
    'aGraderQuestion' : function(d) {
      var options = {
          'slide': function( event, ui ) {
            $('#'+d.key+' #answer').text(ui.value);
          }
      };
      if (d.answer || d.answer == 0) {
        options['disabled'] = true;
        options['value'] = d.answer;
        $('#'+d.key+' #answer').text(d.answer);
      }
      $( '#slider' ).slider(options);
    },
    'aBuilderQuestion' : function(d) {
      
      if (d.answer) {
        $( '#'+d.key+' #question-text' ).text( d.answer.value ).trigger('keydown');
        addthis.toolbox('.addthis_toolbox');
        var plot1 = [];
        var plot2 = [];
        if (d.hasOwnProperty('gradeDistribution')) {
          $.each(d.gradeDistribution, function(key, object) { plot1.push([key*10,object]) });
          $.each(d.confidentGradeDistribution, function(key, object) { plot2.push([key*10,object]) });
          $.plot($('#'+d.key+' #chart'), [ {
            label: "Graded by Algorithm",
            data: plot1,
            bars: {show: true, barWidth: 10, align:'center'},
            stack: true
          },   {
              label: "Graded by You",
              data: plot2,
              bars: {show: true, barWidth: 10, align:'center'},
              stack: true
          } ], { yaxis: { show: true }, xaxis: { show: true } } );
        }
      }
    }
  }
  
  //
  // Load a question array
  //
  var loadQuestion = function(d, prepend) {
    prepend = typeof(prepend) != 'undefined' ? prepend : false;
    if (d.answer == undefined) d.answer = null;
    
    // Answer the question (on submit)
    var answerQuestion = function( eventObj ) {
      if (eventObj.target.id == 'submit') {
        window.history.pushState("object or string", "Title", '/');
        scrollTo(0,0);
        
        $.getJSON('/ajax/answer', createMessageObject(d), function(data) {
          if (data) {
            for ( var i=0; i<data.length; i++ ){
              $('#'+data[i].key).remove();
              loadQuestion( data[i], true );
            }
          }
        });
      }
    }
    
    // Execute preparation by class
    var questionTemplate = 'errorTemplate';
    $.each(d._class, function(key, object) {
      var tmp = getQuestionTemplate[object];
      if (tmp) questionTemplate = tmp(d);
    });
    
    // Render template
    var tmp = $.tmpl( questionTemplate, d ).click(answerQuestion);
    if (prepend)
      tmp.prependTo( '#assignments' );
    else
      tmp.appendTo( '#assignments' );
      
    $( '#'+d.key+' #question-text' ).text( d.question.value ).autoResize({extraSpace : 0}).trigger('keydown');
    $( '.autoResizable' ).autoResize({extraSpace : 0}).trigger('keydown');
    
    // Handle post-display stuff
    $.each(d._class, function(key, object) {
      var tmp = postDisplay[object];
      if (tmp) tmp(d);
    });
    
  }
  
  //
  // Load the question stream
  //
  navPage = 0;
  firstRun = true;
  var reloadStream = function() { 
    $.getJSON('/ajax/stream',{'segment': navPage}, function(data) {
      if (data == '') return;
      $( "#assignments" ).empty();
      data.assignments.forEach( function( d ) {
          loadQuestion( d );
        });

        if (data.assignments.length >= 5) {
          $('#nextPage').show();
        } else {
          $('#intro').clone().appendTo( '#assignments' );
          $('#nextPage').hide();
        }
        
        if (navPage > 0) {
          $('#prevPage').show();
        } else {
          $('#prevPage').hide();
        }
        
        if ( firstRun ) {
          firstRun = false;
          $( "#logout" ).attr("href", data.logout);
        
          //
          // Set up paging
          //
          $('#nextPage').click(function(obj) {
            navPage++;
            reloadStream();
          });
          $('#prevPage').click(function(obj) {
            navPage--;
            reloadStream();
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
              extraSpace : 10
          }).trigger('keydown');

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
        }
    });
  }
  reloadStream();
  
  });