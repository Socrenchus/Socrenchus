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
  
  // Answer the question (on submit)
  var answerQuestion = function( qid, ans ) {
    window.history.pushState("", "", '/');
    scrollTo(0,0);
        
    $.getJSON('/ajax/answer', {'question_id':qid,'answer':ans}, function(data) {
      if (data) {
        for ( var i=0; i<data.length; i++ ){
          $('#'+data[i].key).remove();
          loadQuestion( data[i], true );
        }
      }
    });
  }
  
  // Define pre-display functions by class
  var getQuestionTemplate = {
    'aQuestion' : function(d) {
      
      var item = $('#templates > #question').clone();
      item.attr('id', d.key);
      item.find('#question-text').text(d.question.value);
      item.find('#submit').hide();
      item.find('#score').hide();
      item.find('#grader').hide();

      return item;
    },
    'aShortAnswerQuestion' : function(d) {
      var item = getQuestionTemplate['aQuestion'](d);
      if (d.answer || d.answer == 0) {
        item.find('#answer').text(d.answer.value).attr('readonly','readonly');
        if (d.answer.confidence >= 0.5)
          item.find('#score').text('Score: '+d.answer.correctness*100+'%').show();
      } else {
        item.find('#submit').click(function() {
          answerQuestion(d.key, item.find('#answer').val());
        }).show();
      }
      return item;
    },
    'aGraderQuestion' : function(d) {
      var item = getQuestionTemplate['aQuestion'](d);
      item.find('#grader').show();
      item.find('#answer').text(d.answerInQuestion.value).attr('readonly','readonly');
      var options = {
          'slide': function( event, ui ) {
            item.find('#grade').text(ui.value);
          }
      };
      if (!d.answer && d.answer != 0) {
        item.find('#submit').click(function() {
          answerQuestion(d.key, item.find('#grade').text());
        }).show();
      } else {
        options['disabled'] = true;
        options['value'] = d.answer;
        item.find('#grade').text(d.answer);
      }
      item.find('#slider').slider(options);
      return item;
    },
    'aBuilderQuestion' : function(d) {
      if (d.answer) {
        var item = $('#templates > #questionStats').clone();
        item.find('#question-text').text(d.answer.value);
        item.attr('id', d.key);
        var questionURL = 'http://'+window.location.host+'/'+d.key;
        item.find('#share > input').attr('value', questionURL);
        item.find('#addThis').attr('addthis:url', questionURL);
        item.find('#report').attr('href','/'+d.key+'/report.csv');
        return item;
      }
      var item = getQuestionTemplate['aShortAnswerQuestion'](d);
      var txt = 'Think of the first question you want to ask your students...';
      item.find('#question-text').text(txt);
      return item;
    },
    'aFollowUpBuilderQuestion' : function(d) {
      var item = getQuestionTemplate['aBuilderQuestion'](d);
      if (!d.answer) {
        var txt = 'What do you want to ask a student after they answer the following...\n\n';
        item.find('#question-text').text(txt+d.question.value);
      } else item.find('#question-text').text(d.question.value);
      
      return item;
    }
  };
  
  // Called just after display, by class
  var postDisplay = {
    'aBuilderQuestion' : function(d) {
      if (d.answer) {
        addthis.toolbox('.addthis_toolbox');
        var plot1 = [];
        var plot2 = [];
        if (d.hasOwnProperty('gradeDistribution')) {
          $.each(d.gradeDistribution, function(key, object) { plot1.push([key*10,object]) });
          $.each(d.confidentGradeDistribution, function(key, object) { plot2.push([key*10,object]) });
          $.plot($('#'+d.key+' > div > #chart'), [ {
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
    
    // Execute preparation by class
    var questionTemplate = null;
    $.each(d._class, function(key, object) {
      var tmp = getQuestionTemplate[object];
      if (tmp) questionTemplate = tmp(d);
    });
    
    // Render template
    if (prepend)
      questionTemplate.prependTo( '#assignments' );
    else
      questionTemplate.appendTo( '#assignments' );
      
    $( '#'+d.key+' > div > #question-text' ).autoResize({extraSpace : 0}).trigger('keydown');
    $( '#'+d.key+' > div > .autoResizable' ).autoResize({extraSpace : 0}).trigger('keydown');
    
    // Handle post-display stuff
    $.each(d._class, function(key, object) {
      var tmp = postDisplay[object];
      if (tmp) tmp(d);
    });    
  }
  
  //
  // Load the question stream
  //
  var navPage = 0;
  var myCache = null;
  var reloadStream = function() { 
    
    var initializeStuff = function(data) {

      $( "#logout" ).attr("href", data.logout);
    
      //
      // Set up paging
      //
      $('#nextPage').click(function(obj) {
        navPage++;
        reloadStream();
      });

    }
    
    var loadWithData = function(data) {

      data.forEach( function( d ) {
          loadQuestion( d );
        });

        if (data.length >= 15) {
          $('#nextPage').show();
        } else {
          $('#intro').clone().appendTo( '#assignments' );
          $('#nextPage').hide();
        }
        
    }
    var pageSize = 15;
    var start = pageSize*navPage;
    if ( !myCache || myCache.length >= start ) {
      $.getJSON('/ajax/stream',{'segment': navPage}, function(data) {
        if (data == '') return;
        if (myCache == null) {
          myCache = data.assignments;
          initializeStuff(data);
        } else myCache = myCache.concat(data.assignments);
        loadWithData(myCache.slice(start,start+pageSize));
      });
    } else {
      loadWithData(myCache.slice(start,start+pageSize));
    }
  }
  reloadStream();
  
  });