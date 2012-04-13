(function() {
  var testUtils;

  (function() {});
  testUtils = {
    states: {
      none: 0,
      open: 1
    },
    state: 0,
    defaultTestOptions: {
      selector: '#notify',
      voteboxOptions: {}
    },
    init: function(options) {
      var opts;
      testUtils.reset();
      opts = $.extend({}, testUtils.defaultTestOptions, options);
      $(opts.selector).notify(opts.voteboxOptions);
      $(opts.selector).bind('notifyClicked', testUtils.setState);
      $(opts.selector).bind('documentClicked', testUtils.setState);
      return $(opts.selector);
    },
    setState: function(event, state) {
      return testUtils.state = state;
    },
    setTagCount: function(event, tagCount) {
      return testUtils.tagCount = tagCount;
    },
    reset: function() {
      $(testUtils.defaultTestOptions.selector).unbind('notifyClicked', testUtils.setState);
      $(testUtils.defaultTestOptions.selector).unbind('documentClicked', testUtils.setState);
      return testUtils.voteDiff = 0;
    }
  };
  module("Module A");
  test("checking states", (function() {
    var notifyBox;
    notifyBox = testUtils.init();
    equal(testUtils.state, testUtils.states.none, "the notify box has been spawned so the state should be none");
    notifyBox.find('#notification-counter').click();
    equal(testUtils.state, testUtils.states.open, "the notify box has been clicked so the state should be open");
    notifyBox.find('#notification-counter').click();
    equal(testUtils.state, testUtils.states.none, "the notify box has been clicked again so the state should be none");
    notifyBox.find('#notification-counter').click();
    $(document).click();
    return equal(testUtils.state, testUtils.states.none, "the notify box has been clicked and then clicked out of, so the state should be none");
  }));

}).call(this);
