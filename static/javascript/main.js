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
    $.get('/ajax/stream', function(data) {
      var data = eval('(' + data + ')');
      window.history.pushState("object or string", "Title", "/q/" + data[0].assignment.question.id);
      $( "#assignments > div" ).remove();
      data.forEach( function( d ) {
        $( "#questionTemplate" ).tmpl( d ).appendTo( "#assignments" ).click(function() {
          $.post('/ajax/ask', {'question_id': d.assignment.question.id, 'answer': $('input:radio[name='+d.assignment.question.id+']:checked').val()}, function(data) {
            if (data == "true")
              reloadStream();
          });
        });
      });
    });
  }
  reloadStream();
});