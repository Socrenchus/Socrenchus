(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  $(function() {
    /*
      # Core Model and Logic
    */
    var App, Assignment, AssignmentView, Assignments, Question, QuestionView, Questions, StreamView, Templates, Workspace, app_router, e, myQuestions, _i, _len, _ref;
    Question = (function(_super) {

      __extends(Question, _super);

      function Question() {
        Question.__super__.constructor.apply(this, arguments);
      }

      Question.prototype.initialize = function() {
        this.assignments = new Assignments();
        return this.assignments.add(this.get('assignments'));
      };

      return Question;

    })(Backbone.Model);
    Assignment = (function(_super) {

      __extends(Assignment, _super);

      function Assignment() {
        Assignment.__super__.constructor.apply(this, arguments);
      }

      Assignment.prototype.answer = function(ans) {
        return this.save({
          answer: {
            value: ans
          }
        });
      };

      return Assignment;

    })(Backbone.Model);
    Assignments = (function(_super) {

      __extends(Assignments, _super);

      function Assignments() {
        Assignments.__super__.constructor.apply(this, arguments);
      }

      Assignments.prototype.model = Assignment;

      Assignments.prototype.localStorage = new Store('assignments');

      return Assignments;

    })(Backbone.Collection);
    Questions = (function(_super) {

      __extends(Questions, _super);

      function Questions() {
        Questions.__super__.constructor.apply(this, arguments);
      }

      Questions.prototype.model = Question;

      Questions.prototype.localStorage = new Store('questions');

      return Questions;

    })(Backbone.Collection);
    /*
      # View
    */
    Templates = {};
    _ref = $('#templates').children();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      Templates[e.id] = $(e).html();
    }
    AssignmentView = (function(_super) {

      __extends(AssignmentView, _super);

      function AssignmentView() {
        AssignmentView.__super__.constructor.apply(this, arguments);
      }

      AssignmentView.prototype.tagName = 'li';

      AssignmentView.prototype.template = Templates.assignment;

      AssignmentView.prototype.initialize = function() {
        this.id = this.model.id;
        return this.model.bind('change', this.render, this);
      };

      AssignmentView.prototype.render = function() {
        var a;
        $(this.el).html(this.template);
        this.$('#score').hide();
        this.$('#grader').hide();
        this.$('#assignment-text').hide();
        this.$('#answer').submitView({
          tools: this.$('#submit')
        });
        a = this.model.get('answer');
        if (a != null) {
          answer.text(a.value).attr('readonly', 'readonly');
          if (a.confidence >= 0.5) {
            this.$('#score').text(a.correctness * 100).show();
          }
        }
        return $(this.el);
      };

      AssignmentView.prototype.answer = function() {
        return this.model.answer(this.$('#answer').val());
      };

      return AssignmentView;

    })(Backbone.View);
    QuestionView = (function(_super) {

      __extends(QuestionView, _super);

      function QuestionView() {
        QuestionView.__super__.constructor.apply(this, arguments);
      }

      QuestionView.prototype.tagName = 'li';

      QuestionView.prototype.className = 'question';

      QuestionView.prototype.template = Templates.question;

      QuestionView.prototype.initialize = function() {
        return this.id = this.model.id;
      };

      QuestionView.prototype.render = function() {
        $(this.el).html(this.template);
        this.$('#question-text').text(this.model.get('value'));
        this.addAll();
        return $(this.el);
      };

      QuestionView.prototype.addOne = function(item) {
        var a;
        a = new AssignmentView({
          model: item
        });
        return $(a.render()).appendTo(this.$('#content'));
      };

      QuestionView.prototype.addAll = function() {
        var item, _j, _len2, _ref2, _results;
        _ref2 = this.assignments();
        _results = [];
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          item = _ref2[_j];
          _results.push(this.addOne(item));
        }
        return _results;
      };

      QuestionView.prototype.assignments = function() {
        return myAssignments.question(this.model);
      };

      return QuestionView;

    })(Backbone.View);
    StreamView = (function(_super) {

      __extends(StreamView, _super);

      function StreamView() {
        StreamView.__super__.constructor.apply(this, arguments);
      }

      StreamView.prototype.initialize = function() {
        this.$('#newquestion').html(Templates.assignment).find('#assignment-text').submitView({
          tools: this.$('#newquestion').find('#submit')
        });
        myQuestions.bind('add', this.addOne, this);
        myQuestions.bind('reset', this.addAll, this);
        return myQuestions.fetch();
      };

      StreamView.prototype.addOne = function(item) {
        var q;
        q = new QuestionView({
          model: item
        });
        return $(q.render()).appendTo(this.$('#assignments'));
      };

      StreamView.prototype.addAll = function() {
        return myQuestions.each(this.addOne);
      };

      StreamView.prototype.newQuestion = function() {};

      return StreamView;

    })(Backbone.View);
    myQuestions = new Questions();
    App = new StreamView({
      el: $('#learn')
    });
    /*
      # Routes
    */
    Workspace = (function(_super) {

      __extends(Workspace, _super);

      function Workspace() {
        Workspace.__super__.constructor.apply(this, arguments);
      }

      Workspace.prototype.routes = {
        '/:id': 'assign'
      };

      Workspace.prototype.assign = function(id) {
        myAssignments.get(id);
        return myAssignments.fetch();
      };

      return Workspace;

    })(Backbone.Router);
    return app_router = new Workspace();
  });

}).call(this);
