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
  if (urlParams['q'])
    $.get('/ajax/answer', {'question_id': urlParams['q']});
    
  //
  // Compile templates
  //
  $( "#questionTemplate" ).template( "questionTemplate" );  
  //
  // Load a question array
  //
  var loadQuestion = function(d) {
    d._class = oc(d._class);
    var tmp = d.answer
    if (tmp && tmp.length >= 0) {
      $.each(tmp, function(key, object) { d.answer.push(object.value) });
      d.answer = oc(d.answer);
    }
    if ('aConfidentGraderQuestion' in d._class) {
      d.question.author = d.answerInQuestion.author;
    }
    $.tmpl( "questionTemplate", d ).prependTo( '#assignments' ).click(function( eventObj ) {
      if (eventObj.target.id == 'submit') {
        scrollTo(0,0);
        var messageObj = {'question_id': d.key, 'answer': [], 'class': d._class }
        if ('aShortAnswerQuestion' in d._class)
          messageObj.answer = $('#'+d.key+' #answer').val();
        else if ('aMultipleChoiceQuestion' in d._class)
          messageObj.answer = $('input:radio[name='+d.key+']:checked').val();
        else if ('aMultipleAnswerQuestion' in d._class) {
          var data = $('input:checkbox[name='+d.key+']:checked');
          $.each(data, function(key, object) {
            messageObj.answer.push($(this).val());
          });
        }
        $.getJSON('/ajax/answer', messageObj, function(data) {
          if (data) {
            var len = data.length;
            if (len) {
              $('#'+d.key).remove();
              //window.history.pushState("object or string", "Title", "/q/" + data[len-1].question.id);
            }
            for ( var i=0; i<len; i++ ){
              loadQuestion( data[i] );
            }
          }
        });
      }
    });
  }
  
  //
  // Load the question stream
  //
  var reloadStream = function() { 
    $.getJSON('/ajax/stream', function(data) {
      if (data == '') return;
      $( "#learn > div" ).remove();
      data.forEach( function( d ) {
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