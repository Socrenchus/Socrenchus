(function() {

  $(document).ready(function() {
    /*
      Send answer and handle reply.
    */
    var answerQuestion, getQuestionTemplate, loadQuestion, myCache, navPage, reloadStream;
    answerQuestion = function(qid, ans) {
      window.history.pushState('', '', '/');
      scrollTo(0, 0);
      return $.getJSON('/ajax/answer', {
        question_id: qid,
        answer: ans
      }, function(data) {
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
      });
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
          item.find('#share > input').attr('value', questionURL);
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
    navPage = 0;
    myCache = null;
    (reloadStream = function() {
      var initializeStuff, loadWithData, pageSize, start;
      initializeStuff = function(data) {
        $('#logout').attr('href', data.logout);
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
      if (!myCache || myCache.length >= start) {
        return $.getJSON('/ajax/stream', {
          segment: navPage
        }, function(data) {
          if (data === '') return;
          if (myCache == null) {
            myCache = data.assignments;
            initializeStuff(data);
          } else {
            myCache = myCache.concat(data.assignments);
          }
          return loadWithData(myCache.slice(start, start + pageSize));
        });
      } else {
        return loadWithData(myCache.slice(start, start + pageSize));
      }
    })();
    /*
      Check for database key in URL.
    */
    return (function() {
      var urlPathArray, urlPathString;
      urlPathString = decodeURI(window.location.pathname);
      urlPathArray = urlPathString.split('/');
      if (urlPathArray.length === 2 && urlPathArray[1]) {
        return answerQuestion(urlPathArray[1], '');
      }
    })();
  });

}).call(this);
