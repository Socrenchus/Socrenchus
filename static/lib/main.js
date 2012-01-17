(function() {

  $(document).ready(function() {
    /*
      Make a request to the server with optional callback.
    */
    var answerQuestion, assignQuestion, getQuestionTemplate, isFirstRun, loadQuestion, navPage, prependQuestions, reloadStream, serverRequest;
    serverRequest = function(function_name, opt_argv) {
      var callback, i, key, len, query, val;
      if (!opt_argv) opt_argv = new Array();
      callback = null;
      len = opt_argv.length;
      if (len > 0 && typeof opt_argv[len - 1] === "function") {
        callback = opt_argv[len - 1];
        opt_argv.length--;
      }
      query = "action=" + encodeURIComponent(function_name);
      i = 0;
      while (i < opt_argv.length) {
        key = "arg" + i;
        val = JSON.stringify(opt_argv[i]);
        query += "&" + key + "=" + encodeURIComponent(val);
        i++;
      }
      query += "&time=" + new Date().getTime();
      return $.ajax({
        type: "GET",
        url: '/rpc',
        data: query,
        dataType: "json",
        complete: function(xhr, textStatus) {
          if (textStatus === 'parsererror') {
            $('#welcome').show();
            return $('#logout').text('Login');
          }
        },
        success: function(data, textStatus) {
          return callback(data);
        }
      });
    };
    /*
      Handle prepending questions to stream.
    */
    prependQuestions = function(data) {
      var i, _results;
      if (data) {
        i = 0;
        _results = [];
        while (i < data.length) {
          $('#' + data[i].key).remove();
          loadQuestion(data[i], true);
          _results.push(i++);
        }
        return _results;
      }
    };
    /*
      Send answer and handle reply.
    */
    answerQuestion = function(qid, ans) {
      return serverRequest('answer', [
        qid, ans, function(data) {
          window.scrollTo(0, 0);
          return prependQuestions(data);
        }
      ]);
    };
    /*
      Send assign and handle reply.
    */
    assignQuestion = function(qid) {
      return serverRequest('assign', [qid, prependQuestions]);
    };
    /*
      Build a question template by class.
    */
    getQuestionTemplate = {
      aQuestion: function(d) {
        var item;
        item = $('#templates > #assignment').clone();
        item.attr('id', d.key);
        item.find('#submit').hide();
        item.find('#score').hide();
        item.find('#grader').hide();
        item.render = function() {};
        return item;
      },
      aShortAnswerQuestion: function(d) {
        var answer, item, submit;
        item = getQuestionTemplate['aQuestion'](d);
        item.find('#assignment-text').text('Answer the question above to the best of your ability.');
        answer = item.find('#answer');
        if (d.answer || d.answer === 0) {
          answer.text(d.answer.value).attr('readonly', 'readonly');
          if (d.answer.confidence >= 0.5) {
            item.find('#score').text(d.answer.correctness * 100).show();
          }
        } else {
          submit = item.find('#submit').click(function() {
            return answerQuestion(d.key, item.find('#answer').val());
          });
          answer.focusin(function() {
            submit.show();
            answer.removeClass('defaultTextActive');
            if (answer.val() === answer.attr('title')) return answer.text('');
          }).focusout(function() {
            if (answer.val() === '') {
              submit.hide();
              answer.text(answer.attr('title'));
              return answer.addClass('defaultTextActive');
            }
          }).focusout();
        }
        return item;
      },
      aGraderQuestion: function(d) {
        var item, options, slider, submit;
        item = getQuestionTemplate['aQuestion'](d);
        item.find('#grader').show();
        item.find('#assignment-text').text('Grade the following answer to the above question.');
        item.find('#answer').text(d.answerInQuestion.value).attr('readonly', 'readonly');
        options = {
          slide: function(event, ui) {
            return item.find('#grade').text(ui.value);
          }
        };
        slider = item.find('#slider');
        if (!d.answer && d.answer !== 0) {
          submit = item.find('#submit').click(function() {
            return answerQuestion(d.key, item.find('#grade').text());
          });
          slider.focusin(function() {
            submit.show();
            return item.find('#grade').text('0');
          });
        } else {
          options['disabled'] = true;
          options['value'] = d.answer;
          item.find('#grade').text(d.answer);
        }
        slider.slider(options);
        return item;
      },
      aBuilderQuestion: function(d) {
        var item, questionURL, txt;
        if (d.answer) {
          item = $('#templates > #stats').clone();
          item.attr('id', d.key);
          questionURL = "http://" + window.location.host + "/" + d.answer.key;
          item.find('#addThis').attr('addthis:url', questionURL);
          item.find('#report').attr('href', "/" + d.key + "/report.csv");
          /*
                  Draw the plot and toolbox at template render time.
          */
          item.render = function() {
            var plot1, plot2;
            addthis.toolbox('.addthis_toolbox');
            plot1 = [];
            plot2 = [];
            if (d.hasOwnProperty('gradeDistribution')) {
              $.each(d.gradeDistribution, function(key, object) {
                return plot1.push([key * 10, object]);
              });
              $.each(d.confidentGradeDistribution, function(key, object) {
                return plot2.push([key * 10, object]);
              });
              return $.plot($("#" + d.key + " > #chart"), [
                {
                  label: 'Graded by Algorithm',
                  data: plot1,
                  bars: {
                    show: true,
                    barWidth: 10,
                    align: 'center'
                  },
                  stack: true
                }, {
                  label: 'Graded by You',
                  data: plot2,
                  bars: {
                    show: true,
                    barWidth: 10,
                    align: 'center'
                  },
                  stack: true
                }
              ], {
                yaxis: {
                  show: true
                },
                xaxis: {
                  show: true
                }
              });
            }
          };
          return item;
        }
        item = getQuestionTemplate['aShortAnswerQuestion'](d);
        txt = 'It should be something that will help you lead into the rest of your material. It should also have at least one right answer.';
        item.find('#assignment-text').text(txt);
        return item;
      },
      aFollowUpBuilderQuestion: function(d) {
        var item, txt;
        item = getQuestionTemplate['aBuilderQuestion'](d);
        if (!d.answer) {
          txt = 'What will you ask your students next...';
          item.find('#assignment-text').text(txt);
        }
        return item;
      }
    };
    /*
      Load an individual question to the stream.
    */
    loadQuestion = function(d, prepend) {
      var item, questionTemplate, str;
      if (typeof prepend === 'undefined') prepend = false;
      if (d.answer === undefined) d.answer = null;
      if (!$('#' + d.question.key).length) {
        item = $('#templates > #question').clone();
        item.attr('id', d.question.key);
        if (prepend) {
          item.prependTo('#assignments');
        } else {
          item.appendTo('#assignments');
        }
        item.find('#question-text').text(d.question.value).autoResize().trigger('keydown');
      } else {
        if (prepend) $('#' + d.question.key).prependTo('#assignments');
      }
      questionTemplate = null;
      $.each(d._class, function(key, object) {
        var tmp;
        tmp = getQuestionTemplate[object];
        if (tmp) return questionTemplate = tmp(d);
      });
      str = "#" + d.question.key + " > div > #content";
      if (prepend) {
        questionTemplate.prependTo(str);
      } else {
        questionTemplate.appendTo(str);
      }
      $('#' + d.key).find('.autoResizable').autoResize({
        extraSpace: 0
      }).trigger('keydown');
      return questionTemplate.render();
    };
    /*
      Load the stream.
    */
    navPage = 0;
    isFirstRun = true;
    (reloadStream = function() {
      var initializeStuff, loadWithData, pageSize, start;
      initializeStuff = function(data) {
        var classes;
        $('#logout').text('Logout');
        $('#logout').attr('href', data.logout);
        classes = $('#classes');
        classes.selectable({
          unselecting: function(event, ui) {
            return $('.ui-unselecting').addClass('ui-last-selected');
          },
          unselected: function(event, ui) {
            if (!classes.find('.ui-selecting').length) {
              $('.ui-last-selected').addClass('ui-selected');
            }
            return $('.ui-last-selected').removeClass('ui-last-selected');
          },
          selected: function(event, ui) {
            if (ui.selected.id === 'create') return window.location = '/newclass';
          }
        }).mouseover(function(obj) {
          return classes.children().show();
        }).mouseout(function(obj) {
          classes.children().hide();
          return classes.find('.ui-selected, .ui-selecting').show();
        });
        return $('#nextPage').click(function(obj) {
          navPage++;
          return reloadStream();
        });
      };
      loadWithData = function(data) {
        data.forEach(function(d) {
          return loadQuestion(d);
        });
        if (data.length >= 15) {
          return $('#nextPage').show();
        } else {
          $('#intro').clone().appendTo('#assignments');
          return $('#nextPage').hide();
        }
      };
      pageSize = 15;
      start = pageSize * navPage;
      return serverRequest('stream', [
        navPage, function(data) {
          if (data === '') return;
          if (isFirstRun) {
            isFirstRun = false;
            initializeStuff(data);
          }
          return loadWithData(data.assignments);
        }
      ]);
    })();
    /*
      Check for database key in URL.
    */
    return (function() {
      var urlPathArray, urlPathString;
      urlPathString = decodeURI(window.location.pathname);
      urlPathArray = urlPathString.split('/');
      if (urlPathArray.length === 3 && urlPathArray[2]) {
        return assignQuestion(urlPathArray[2], '');
      }
    })();
  });

}).call(this);
