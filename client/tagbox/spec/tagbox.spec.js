(function() {
  var testUtils;

  testUtils = {
    states: {
      none: 0,
      typing: 1
    },
    state: 0,
    currtag: '',
    defaultTestOptions: {
      id: 'tagbox',
      selector: '#tagbox',
      voteboxOptions: {}
    },
    init: function(options) {
      var opts, tagbox;
      testUtils.reset();
      opts = $.extend({}, testUtils.defaultTestOptions, options);
      tagbox = $(opts.selector).tagbox(opts.voteboxOptions);
      $(opts.selector).bind('tagSync', testUtils.setTag);
      $(opts.selector).bind('typingTag', testUtils.setState);
      $(opts.selector).bind('unfocusingTagBox', testUtils.setState);
      return $(opts.selector);
    },
    setState: function(event, state) {
      return testUtils.state = state;
    },
    setTag: function(event, tag) {
      return testUtils.currtag = tag;
    },
    reset: function() {
      $(testUtils.defaultTestOptions.selector).unbind('tagSync', testUtils.setTag);
      $(testUtils.defaultTestOptions.selector).unbind('typingTag', testUtils.setState);
      $(testUtils.defaultTestOptions.selector).unbind('unfocusingTagBox', testUtils.setState);
      $(testUtils.defaultTestOptions.selector).remove();
      $('body').append($("<div id=" + testUtils.defaultTestOptions.id + "></div>"));
      testUtils.state = testUtils.states.none;
      return testUtils.currtag = '';
    }
  };

  describe('no interaction', (function() {
    it('should have none state', (function() {
      return expect(testUtils.state).toEqual(testUtils.states.none);
    }));
    it('should have no tags added', (function() {
      return expect(testUtils.currtag).toEqual('');
    }));
    return $('#snapshot').trigger('render', 'nointeraction');
  }));

  describe('adding tags', (function() {
    it('tag string should equal hello world', (function() {
      var e, tagbox;
      tagbox = testUtils.init();
      tagbox.find('.ui-tagtext:eq(0)').click();
      tagbox.find('.ui-individualtag:eq(0)').text('hello world');
      e = jQuery.Event('keydown');
      e.keyCode = 13;
      return $('#tagbox .ui-tagtext:eq(0)').trigger(e);
    }));
    it('adding multiple tags, last one should be hello multiverse', (function() {
      var e, i, tagbox;
      tagbox = testUtils.init();
      tagbox.find('.ui-tagtext:eq(0)').click();
      for (i = 1; i <= 10; i++) {
        tagbox.find('.ui-individualtag:eq(0)').text('hello world');
        e = jQuery.Event('keydown');
        e.keyCode = 13;
        $('#tagbox .ui-tagtext:eq(0)').trigger(e);
      }
      tagbox.find('.ui-individualtag:eq(0)').text('hello multiverse');
      e = jQuery.Event('keydown');
      e.keyCode = 13;
      return $('#tagbox .ui-tagtext:eq(0)').trigger(e);
    }));
    return $('#snapshot').trigger('render', 'multipleclickshellomultiverse');
  }));

  describe('checking states', (function() {
    it('state should be typing', (function() {
      var tagbox;
      tagbox = testUtils.init();
      tagbox.find('.ui-tagtext:eq(0)').click();
      return tagbox.find('.ui-individualtag:eq(0)').text('hello world');
    }));
    it('state should be none', (function() {
      var e;
      e = jQuery.Event('focusout');
      $('#tagbox .ui-tagtext:eq(0)').trigger(e);
      return expect(testUtils.state).toEqual(testUtils.states.none);
    }));
    return $.doTimeout(100, function() {
      return $('#snapshot').trigger('render', 'statecheck');
    });
  }));

}).call(this);
