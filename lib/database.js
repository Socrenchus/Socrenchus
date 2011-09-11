var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var User = new Schema({
  email: { 
    type      : String,
    lowercase : true,
    trim      : true,
    match     : /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/
  } 
});

var Connection = new Schema({
  target    : Schema.ObjectId,
  weight    : Number
});

var Answer = new Schema({
  value     : String,
  user      : User.ObjectId,
  correct   : Boolean,
  next      : [ Connection ]
});

var Question = new Schema({
  value     : String,
  author    : User.ObjectId,
  score     : Number,
  timestamp : Date
  answers   : [ Answer ]
  focus     : [ Connection ]
});

var Topic = new Schema({
  title    : Schema.ObjectId,
  start    : [ Question.ObjectId ],
  end      : [ Question.ObjectId ]
});

var Assignment = new Schema({
  topic     : Topic.ObjectId,
  question  : Question.ObjectId,
  answers   : [ String ],
  answer    : Answer.ObjectId,
  list      : { type: String, enum: ['assignments', 'toolbox'], default: 'assignments'},
  timestamp : Date,
  liked     : Boolean,
  user      : User.ObjectId
});