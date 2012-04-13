(function() {
  var testUtils;

  (function() {});
  testUtils = {
    states: {
      none: 0,
      typing: 1,
      altering: 2
    },
    state: 0,
    tagCount: 0,
    defaultTestOptions: {
      selector: '#tagbox',
      voteboxOptions: {}
    },
    init: function(options) {
      var opts, tagbox;
      testUtils.reset();
      opts = $.extend({}, testUtils.defaultTestOptions, options);
      tagbox = $(opts.selector).tagbox(opts.voteboxOptions);
      $(opts.selector).bind('tagAdded', testUtils.setTagCount);
      $(opts.selector).bind('tagRemoved', testUtils.setTagCount);
      $(opts.selector).bind('typingTag', testUtils.setState);
      $(opts.selector).bind('alteringTag', testUtils.setState);
      $(opts.selector).bind('unfocusingTagBox', testUtils.setState);
      return $(opts.selector);
    },
    setState: function(event, state) {
      return testUtils.state = state;
    },
    setTagCount: function(event, tagCount) {
      return testUtils.tagCount = tagCount;
    },
    reset: function() {
      $(testUtils.defaultTestOptions.selector).unbind('tagAdded', testUtils.setTagCount);
      $(testUtils.defaultTestOptions.selector).unbind('tagRemoved', testUtils.setTagCount);
      $(testUtils.defaultTestOptions.selector).unbind('typingTag', testUtils.setState);
      $(testUtils.defaultTestOptions.selector).unbind('alteringTag', testUtils.setState);
      $(testUtils.defaultTestOptions.selector).unbind('unfocusingTagBox', testUtils.setState);
      return testUtils.voteDiff = 0;
    }
  };
  module("Module A");
  test("adding tags and removing tags", (function() {
    var e, tagbox;
    tagbox = testUtils.init();
    tagbox.find('.ui-tagtext:eq(0)').click();
    tagbox.find('.ui-individualtag:eq(0)').text('hello world');
    e = jQuery.Event('keydown');
    e.keyCode = 13;
    $('#tagbox .ui-tagtext:eq(0)').trigger(e);
    equal(testUtils.tagCount, 1, "A tag has been added, the count of tags should be 1");
    tagbox.find('.ui-individualtag:eq(1)').text('hello universe');
    e = jQuery.Event('keydown');
    e.keyCode = 13;
    $('#tagbox .ui-tagtext:eq(0)').trigger(e);
    tagbox.find('.ui-individualtag:eq(2)').text('hello multiverse');
    e = jQuery.Event('keydown');
    e.keyCode = 13;
    $('#tagbox .ui-tagtext:eq(0)').trigger(e);
    equal(testUtils.tagCount, 3, "2 tags have been added, the count of tags should be 3");
    tagbox.find('.ui-tagtext:eq(0)').find('.delete-imageicon:eq(0)').click();
    equal(testUtils.tagCount, 2, "One of the tags has been deleted, the tag count should be 2");
    tagbox.find('.ui-tagtext:eq(0)').find('.delete-imageicon:eq(0)').click();
    tagbox.find('.ui-tagtext:eq(0)').find('.delete-imageicon:eq(0)').click();
    return equal(testUtils.tagCount, 0, "The rest of the tags have been removed, the count should be 0");
  }));
  test("checking states", (function() {
    var e, tagbox;
    tagbox = testUtils.init();
    e = jQuery.Event('focusout');
    $('#tagbox .ui-tagtext:eq(0)').trigger(e);
    equal(testUtils.state, testUtils.states.none, "the state should be none");
    tagbox.find('.ui-tagtext:eq(0)').click();
    equal(testUtils.state, testUtils.states.typing, "The tagbox has been clicked, so the state should be typing");
    tagbox.find('.ui-tagtext:eq(0)').click();
    tagbox.find('.ui-individualtag:eq(0)').text('hello world');
    e = jQuery.Event('keydown');
    e.keyCode = 13;
    $('#tagbox .ui-tagtext:eq(0)').trigger(e);
    $('.ui-individualtag:eq(0)').click();
    return equal(testUtils.state, testUtils.states.altering, "A tag is being altered so the state should be altering");
  }));

}).call(this);
