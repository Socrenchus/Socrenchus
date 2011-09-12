// setup Dependencies
require( __dirname + "/lib/setup" )
   .ext( __dirname + "/lib/database" )
   .ext( __dirname + "/lib" )
   .ext( __dirname + "/lib/express/support" );
var connect = require('connect')
    , express = require('express')
    , mongoose = require('mongoose')
    , sys = require('sys')
    , port = (process.env.PORT || 8081);

// Setup Express
var server = express.createServer();
server.configure(function(){
    server.set('views', __dirname + '/views');
    server.use(connect.bodyParser());
    server.use(connect.static(__dirname + '/static'));
    server.use(server.router);
});

// Setup Mongoose
mongoose.connect('mongodb://localhost/socrenchus');

// setup the errors
server.error(function(err, req, res, next) {
    if (err instanceof NotFound) {
        res.render('404.ejs', { locals: { 
                  header: '#Header#'
                 ,footer: '#Footer#'
                 ,title : '404 - Not Found'
                 ,description: ''
                 ,author: ''
                 ,analyticssiteid: 'XXXXXXX' 
                },status: 404 });
    } else {
        res.render('500.ejs', { locals: { 
                  header: '#Header#'
                 ,footer: '#Footer#'
                 ,title : 'The Server Encountered an Error'
                 ,description: ''
                 ,author: ''
                 ,analyticssiteid: 'XXXXXXX'
                 ,error: err 
                },status: 500 });
    }
});
server.listen( port );


///////////////////////////////////////////
//              Routes                   //
///////////////////////////////////////////

server.get('/ajax/stream', function(req,res) {
  
});

server.get('/ajax/new', function(req,res) {
  var q = new Question();
  q.value = req.param('question');
  for (var i = 0; i < 4; ++i) {
    var a = new Answer();
    a.value = req.param(i+'-a');
    q.answers.push(a);
    a.save();
  }
  
  var a = new Assignment();
  a.question = q;
  a.save();
  q.save();
});

server.get('/', function(req,res) {
  res.render('index.ejs', {
    locals : { 
              header: '#Header#'
             ,footer: '#Footer#'
             ,title : 'Page Title'
             ,description: 'Page Description'
             ,author: 'Your Name'
             ,analyticssiteid: 'XXXXXXX' 
            }
  });
});


//A Route for Creating a 500 Error (Useful to keep around)
server.get('/500', function(req, res) {
    throw new Error('This is a 500 Error');
});

//The 404 Route (ALWAYS Keep this as the last route)
server.get('/*', function(req, res) {
    throw new NotFound;
});

function NotFound(msg) {
    this.name = 'NotFound';
    Error.call(this, msg);
    Error.captureStackTrace(this, arguments.callee);
}


console.log('Listening on http://0.0.0.0:' + port );
