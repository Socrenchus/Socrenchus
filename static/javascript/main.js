$(document).ready(function() {
  // Get URL parameters
  var urlParams = {}
  var urlPathString = decodeURI(window.location.pathname);
  var urlPathArray = urlPathString.split('/');
  for (i = 0; i < urlPathArray.length; i++ )
    if (!(i % 2))
      urlParams[urlPathArray[i-1]] = urlPathArray[i];

  if (urlParams['q'])
    $.get('/ajax/ask', {'question_id': urlParams['q']});

  var reloadStream = function() { 
    $.getJSON('/ajax/stream', function(data) {
      window.history.pushState("object or string", "Title", "/q/" + data[data.length-1].assignment.question.id);
      $( "#assignments > div" ).remove();
      data.forEach( function( d ) {
        $( "#questionTemplate" ).tmpl( d ).prependTo( "#assignments" ).click(function() {
          $.post('/ajax/ask', {'question_id': d.assignment.question.id, 'answer': $('input:radio[name='+d.assignment.question.id+']:checked').val()}, function(data) {
            if (data == "true")
              reloadStream();
          });
        });
      });
    });
  }
  reloadStream();
  
  $(function() {
    $( "#tabs" ).tabs();
  });
});