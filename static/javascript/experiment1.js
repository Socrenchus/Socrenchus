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
  // Check for certain parameters
  //
  if (urlParams['q'])
    $.get('/ajax/answer', {'question_id': urlParams['q']});
  
  //
  // Handle submit new question
  //
  $('#submit').click(function() {
    var message = {
      'question' : $('#question').val(),
      'correct1' : $('#correct1').val(),
      'correct2' : $('#correct2').val(),
      'correct3' : $('#correct3').val(),
      'correct4' : $('#correct4').val(),
      'correct5' : $('#correct5').val(),
      'incorrect1' : $('#incorrect1').val(),
      'incorrect2' : $('#incorrect2').val(),
      'incorrect3' : $('#incorrect3').val(),
      'incorrect4' : $('#incorrect4').val(),
      'incorrect5' : $('#incorrect5').val()
    };
    $.getJSON('/ajax/new', message, function(data) {
                var len = data.length;
                if (len) {
                  $('#'+d.question.id).remove();
                  window.history.pushState("object or string", "Title", "/q/" + data[len-1].question.id);
                }
                for ( var i=0; i<len; i++ ){
                  loadQuestion( data[i] );
                }
              });
    
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