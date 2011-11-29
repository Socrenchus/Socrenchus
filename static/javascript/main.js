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
  // Compile templates
  //
  $( "#questionTemplate" ).template( "questionTemplate" );  
  //
  // Load a question array
  //
  var loadQuestion = function(d) {
    $.tmpl( "questionTemplate", d ).prependTo( '#'+d.list ).click(function( eventObj ) {
      scrollTo(0,0);
      switch ( eventObj.target.id ) {
        case 'rateButton':
          //
          // Like button clicked
          //
          $.getJSON('/ajax/rate', {'question_id': d.question.id}, function( data ) {
            $('#'+data.question.id).remove();
            loadQuestion( data );
          });
          break;
        case 'answer':
          //
          // Question answered
          //
          $.getJSON('/ajax/answer', {'question_id': d.question.id, 'answer': $('input:radio[name='+d.question.id+']:checked').val(),'div': d.list}, function(data) {
            var len = data.length;
            if (len) {
              $('#'+d.question.id).remove();
              window.history.pushState("object or string", "Title", "/q/" + data[len-1].question.id);
            }
            for ( var i=0; i<len; i++ ){
              loadQuestion( data[i] );
            }
          });
          break;
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
    });
  }
  reloadStream();
  
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