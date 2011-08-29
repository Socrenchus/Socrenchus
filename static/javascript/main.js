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
  $( "#newAnswerTemplate" ).template( "newAnswerTemplate" );
  
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
  // Set up draggable lists and droppable tabs
  //
  $(function() {
    $( "#assignments, #toolbox" ).sortable().disableSelection();
    
    var $tabs = $( "#tabs" ).tabs();
    
    var $tab_items = $( "ul:first li", $tabs ).droppable({
      accept: ".correct",
      hoverClass: "ui-state-hover",
      tolerance: "pointer",
      drop: function( event, ui ) {
        var $item = $( this );
        var $list = $( $item.find( "a" ).attr( "href" ) )
          .find( ".teachLearnSortable" );
          
        ui.draggable.hide("fast", function() {
          $.getJSON('/ajax/answer', {'question_id': $(this).attr('id'),'div':$list.attr('id')}, function(data) {
            loadQuestion( data );
          });
        });
      }
    });
  });
  
  //
  // Create new question form
  //
  $(function() {
    [0, 1, 2, 3].forEach( function( i ) {
      $.tmpl( "newAnswerTemplate", {'i': i} ).appendTo( "#answers" );
      
      $( "#next"+i ).sortable({
        connectWith: ".teachSortable",
        tolerance: "pointer"
      }).disableSelection();
    });
    
    $( "#incoming" ).sortable({connectWith: ".teachSortable",placeholder: "empty"}).disableSelection();
    $( "#toolbox" ).sortable({connectWith: ".teachSortable"}).disableSelection();
    
    $("#newQuestionSubmit").click( function() {
      // get all the inputs into an array.
      var $inputs = $('#newQuestion :text,textarea');
      
      // get an associative array of just the values.
      var values = {};
      $inputs.each(function() {
        values[this.name] = $(this).val();
      });
      
      // get question links
      [0, 1, 2, 3].forEach( function( i ) {
        var next_questions = $('#next'+i).children().map(function() {
          return $(this).attr("id");
        }).get();
        
        if (next_questions.length > 0)
          values[i+'-n'] = next_questions;
        
      });
      
      $.getJSON('/ajax/new', values, function(data) {
        $('#newQuestion :text,textarea').val('').blur();
        $('#newQuestion > div > ul').empty();
        reloadStream();
      });
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