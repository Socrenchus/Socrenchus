(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  $(function() {
    /*
      # Core Model and Logic
    */
    var App, Assignment, AssignmentView, Assignments, Class, Classes, Question, QuestionView, Questions, StreamView, Templates, Workspace, aFollowUpView, aGraderView, aShortAnswerView, app_router, e, myAssignments, myQuestions, _i, _len, _ref;
    Class = (function(_super) {

      __extends(Class, _super);

      function Class() {
        Class.__super__.constructor.apply(this, arguments);
      }

      return Class;

    })(Backbone.Model);
    Question = (function(_super) {

      __extends(Question, _super);

      function Question() {
        Question.__super__.constructor.apply(this, arguments);
      }

      return Question;

    })(Backbone.Model);
    Assignment = (function(_super) {

      __extends(Assignment, _super);

      function Assignment() {
        Assignment.__super__.constructor.apply(this, arguments);
      }

      Assignment.prototype.defaults = {
        question: {}
      };

      Assignment.prototype.answer = function(ans) {
        this.save({
          answer: {
            value: ans
          }
        }, {
          success: this.answered
        });
        return this.clear();
      };

      Assignment.prototype.answered = function(model, response) {
        return myAssignments.add(response);
      };

      return Assignment;

    })(Backbone.Model);
    Questions = (function(_super) {

      __extends(Questions, _super);

      function Questions() {
        Questions.__super__.constructor.apply(this, arguments);
      }

      Questions.prototype.model = Question;

      return Questions;

    })(Backbone.Collection);
    myQuestions = new Questions();
    Assignments = (function(_super) {

      __extends(Assignments, _super);

      function Assignments() {
        Assignments.__super__.constructor.apply(this, arguments);
      }

      Assignments.prototype.model = Assignment;

      Assignments.prototype.url = '/rpc/assignments';

      Assignments.prototype.question = function(q) {
        return this.filter(function(a) {
          return a.get('question').id === q.id;
        });
      };

      Assignments.prototype.add = function(items) {
        var item, _i, _len, _results;
        Assignments.__super__.add.call(this, items);
        if (items.length == null) items = [items];
        _results = [];
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          if (!myQuestions.get(item.question.id)) {
            _results.push(myQuestions.add(new Question(item.question)));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      return Assignments;

    })(Backbone.Collection);
    Classes = (function(_super) {

      __extends(Classes, _super);

      function Classes() {
        Classes.__super__.constructor.apply(this, arguments);
      }

      Classes.prototype.model = Class;

      return Classes;

    })(Backbone.Collection);
    myAssignments = new Assignments();
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
        $(this.el).html(this.template);
        this.$('#score').hide();
        this.$('#submit').hide();
        this.$('#grader').hide();
        return $(this.el);
      };

      AssignmentView.prototype.remove = function() {
        return $(this.el).remove();
      };

      AssignmentView.prototype.clear = function() {
        return this.model.destroy();
      };

      return AssignmentView;

    })(Backbone.View);
    aShortAnswerView = (function(_super) {

      __extends(aShortAnswerView, _super);

      function aShortAnswerView() {
        aShortAnswerView.__super__.constructor.apply(this, arguments);
      }

      aShortAnswerView.prototype.events = {
        'click #submit': 'answer',
        'focusin': 'focusin',
        'focusout': 'focusout'
      };

      aShortAnswerView.prototype.render = function() {
        var a, answer;
        aShortAnswerView.__super__.render.call(this);
        this.$('#assignment-text').text('Answer the question above to the best of your ability.');
        answer = this.$('#answer').focusout();
        a = this.model.get('answer');
        if (a != null) {
          answer.text(a.value).attr('readonly', 'readonly');
          if (a.confidence >= 0.5) {
            this.$('#score').text(a.correctness * 100).show();
          }
        }
        return $(this.el);
      };

      aShortAnswerView.prototype.focusin = function() {
        var answer;
        answer = this.$('#answer');
        if (this.model.get('answer') == null) {
          this.$('#submit').show();
          answer.removeClass('defaultTextActive');
          if (answer.val() === answer.attr('title')) return answer.text('');
        }
      };

      aShortAnswerView.prototype.focusout = function() {
        var answer;
        answer = this.$('#answer');
        if (answer.val() === '' && !(this.model.get('answer') != null)) {
          this.$('#submit').hide();
          answer.addClass('defaultTextActive');
          return answer.text(answer.attr('title'));
        }
      };

      aShortAnswerView.prototype.answer = function() {
        return this.model.answer(this.$('#answer').val());
      };

      return aShortAnswerView;

    })(AssignmentView);
    aGraderView = (function(_super) {

      __extends(aGraderView, _super);

      function aGraderView() {
        aGraderView.__super__.constructor.apply(this, arguments);
      }

      aGraderView.prototype.events = {
        'click #submit': 'answer',
        'focusin #slider': 'focusin'
      };

      aGraderView.prototype.render = function() {
        var a, options,
          _this = this;
        aGraderView.__super__.render.call(this);
        this.$('#grader').show();
        this.$('#assignment-text').text('Grade the following answer to the above question.');
        this.$('#answer').text(this.model.get('answerInQuestion').value).attr('readonly', 'readonly');
        options = {
          slide: function(event, ui) {
            return _this.$('#grade').text(ui.value);
          }
        };
        a = this.model.get('answer');
        if (a != null) {
          options['disabled'] = true;
          options['value'] = a;
          this.$('#grade').text(a);
        }
        this.$('#slider').slider(options);
        return $(this.el);
      };

      aGraderView.prototype.focusin = function() {
        return this.$('#submit').show();
      };

      aGraderView.prototype.answer = function() {
        return this.model.answer(this.$('#grade').text());
      };

      return aGraderView;

    })(AssignmentView);
    aFollowUpView = (function(_super) {

      __extends(aFollowUpView, _super);

      function aFollowUpView() {
        aFollowUpView.__super__.constructor.apply(this, arguments);
      }

      aFollowUpView.prototype.render = function() {
        var questionURL,
          _this = this;
        if (this.model.get('answer') == null) {
          this.template = Templates.assignment;
          aFollowUpView.__super__.render.call(this);
          this.$('#assignment-text').text('What will you ask your students next...');
        } else {
          this.template = Templates.stats;
          aFollowUpView.__super__.render.call(this);
          this.$('#assignment-text').hide();
          questionURL = "http://" + window.location.host + "/" + this.model.id;
          this.$('#addThis').attr('addthis:url', questionURL);
          this.$('#report').attr('href', "/" + this.model.id + "/report.csv");
          $(this.el).ready(function() {
            return _this.draw();
          });
        }
        return $(this.el);
      };

      aFollowUpView.prototype.draw = function() {
        var cgd, data, gd, key, object, sum;
        data = [];
        sum = 0;
        if (this.model.get('gradeDistribution') != null) {
          gd = this.model.get('gradeDistribution');
          cgd = this.model.get('confidentGradeDistribution');
          for (key in gd) {
            object = gd[key];
            data.push([[object, cgd[key]], "" + (key * 10)]);
            sum += object;
            sum += cgd[key];
          }
          if (false && sum > 0) {
            this.$('#chart').jqbargraph({
              'data': data,
              'width': 470,
              'colors': ['#242424', '#437346'],
              'animate': false,
              'legends': ['Algorithm', 'You'],
              'legend': false,
              'barSpace': 0
            });
          } else {
            this.$('#chart').hide();
            this.$('#share').removeClass('submitArea');
            this.$('#addThis').addClass('addthis_32x32_style');
          }
        }
        return addthis.toolbox('.addthis_toolbox');
      };

      return aFollowUpView;

    })(aShortAnswerView);
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
        a = null;
        switch (item.get('class_').pop()) {
          case 'aShortAnswerQuestion':
            a = new aShortAnswerView({
              model: item
            });
            break;
          case 'aGraderQuestion':
          case 'aConfidentGraderQuestion':
            a = new aGraderView({
              model: item
            });
            break;
          case 'aFollowUpBuilderQuestion':
            a = new aFollowUpView({
              model: item
            });
            break;
          default:
            a = new AssignmentView({
              model: item
            });
        }
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

      QuestionView.prototype.remove = function() {
        return $(this.el).remove();
      };

      QuestionView.prototype.clear = function() {
        return this.model.destroy();
      };

      return QuestionView;

    })(Backbone.View);
    StreamView = (function(_super) {

      __extends(StreamView, _super);

      function StreamView() {
        StreamView.__super__.constructor.apply(this, arguments);
      }

      StreamView.prototype.initialize = function() {
        myQuestions.bind('add', this.addOne, this);
        myQuestions.bind('reset', this.addAll, this);
        return myAssignments.fetch();
      };

      StreamView.prototype.addOne = function(item) {
        var q;
        q = new QuestionView({
          model: myQuestions.get(item.get('id'))
        });
        return $(q.render()).appendTo(this.el);
      };

      StreamView.prototype.addAll = function() {
        return myQuestions.each(this.addOne);
      };

      StreamView.prototype.remove = function() {
        return $(this.el).remove();
      };

      StreamView.prototype.clear = function() {
        return this.model.destroy();
      };

      return StreamView;

    })(Backbone.View);
    App = new StreamView({
      el: $('#assignments')
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
        'newclass': 'newclass',
        'q/:id': 'assign'
      };

      Workspace.prototype.newclass = function() {
        var b;
        b = new ClassBuilderView();
        return b.render();
      };

      Workspace.prototype.assign = function(id) {
        myAssignments.get(id);
        return myAssignments.fetch();
      };

      return Workspace;

    })(Backbone.Router);
    app_router = new Workspace();
    return app_router.newclass();
  });

}).call(this);
