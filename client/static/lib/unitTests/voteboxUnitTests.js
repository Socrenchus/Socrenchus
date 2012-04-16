(function() {
  var testUtils;

  (function() {});
  testUtils = {
    voteDiff: 0,
    state: 0,
    votetextVal: 0,
    newVotes: 0,
    states: {
      none: 0,
      up: 1,
      down: 2
    },
    defaultTestOptions: {
      selector: '#votebox',
      voteboxOptions: {}
    },
    init: function(options) {
      var opts;
      testUtils.reset();
      opts = $.extend({}, testUtils.defaultTestOptions, options);
      $(opts.selector).votebox(opts.voteboxOptions);
      $(opts.selector).bind('upArrowPressed', testUtils.upArrowPressed);
      $(opts.selector).bind('downArrowPressed', testUtils.downArrowPressed);
      $(opts.selector).bind('votetextChanged', testUtils.votetextChanged);
      return $(opts.selector);
    },
    votetextChanged: function(event, params) {
      testUtils.votetextVal = params[0];
      return testUtils.newVotes = params[1];
    },
    upArrowPressed: function(event, state) {
      testUtils.state = state;
      return testUtils.voteDiff = 1;
    },
    downArrowPressed: function(event, state) {
      testUtils.state = state;
      return testUtils.voteDiff = -1;
    },
    reset: function() {
      $(testUtils.defaultTestOptions.selector).unbind('upArrowPressed', testUtils.upArrowPressed);
      $(testUtils.defaultTestOptions.selector).unbind('downArrowPressed', testUtils.downArrowPressed);
      $(testUtils.defaultTestOptions.selector).unbind('votetextChanged', testUtils.votetextChanged);
      return testUtils.voteDiff = 0;
    }
  };
  module("Module A");
  test("UP arrow click tests", (function() {
    var votebox;
    votebox = testUtils.init();
    votebox.find('#ui-upvote').click();
    equal(testUtils.voteDiff, 1, "The upvote has been clicked");
    equal(testUtils.state, testUtils.states.up, "The state is supposed to be up");
    equal(testUtils.votetextVal, testUtils.newVotes, "the textbox number should be equivalent to the number of votes");
    $('#votebox #ui-upvote').click();
    equal(testUtils.state, testUtils.states.none, "The state is supposed to be none");
    return equal(testUtils.votetextVal, testUtils.newVotes, "the textbox number should be equivalent to the number of votes");
  }));
  test("DOWN arrow click tests", (function() {
    var votebox;
    votebox = testUtils.init();
    votebox.find('#ui-downvote').click();
    equal(testUtils.voteDiff, -1, "The downvote has been clicked");
    equal(testUtils.state, testUtils.states.down, "The state is supposed to be down");
    equal(testUtils.votetextVal, testUtils.newVotes, "the textbox number should be equivalent to the number of votes");
    votebox.find('#ui-downvote').click();
    return equal(testUtils.state, testUtils.states.none, "The state is supposed to be none");
  }));
  test("both arrow click tests", (function() {
    var votebox;
    votebox = testUtils.init();
    votebox.find('#ui-upvote').click();
    votebox.find('#ui-downvote').click();
    equal(testUtils.state, testUtils.states.down, "Up was clicked then down.  The state is supposed to be down");
    equal(testUtils.votetextVal, testUtils.newVotes, "the textbox number should be equivalent to the number of votes");
    return votebox.find('#ui-downvote').click();
  }));

}).call(this);
