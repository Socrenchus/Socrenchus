(function() {
  ;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($, window, document) {
    var Plugin, defaults, pluginName, states;
    pluginName = 'votebox';
    defaults = {
      votesnum: 0,
      callback: ''
    };
    states = {
      none: 0,
      up: 1,
      down: 2
    };
    Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.getState = __bind(this.getState, this);
        this.voteCount = __bind(this.voteCount, this);
        this.disable = __bind(this.disable, this);
        this.setImages = __bind(this.setImages, this);
        this.pressDown = __bind(this.pressDown, this);
        this.pressUp = __bind(this.pressUp, this);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'votebox';
        this._states = states;
        this.init();
      }

      Plugin.prototype.init = function() {
        var downpressed, originalvotesnum, uppressed,
          _this = this;
        this.state = this._states.none;
        uppressed = false;
        downpressed = false;
        originalvotesnum = this.options.votesnum;
        this.upArrow = $("<img alt='^' title='vote up' id='ui-upvote'>");
        this.upArrow.attr('onmouseover', 'src="/images/votearrowover.png"');
        this.upArrow.attr('onmousedown', 'src="/images/votearrowdown.png"');
        this.votetext = $("<div id='ui-votetext'>" + (Math.round(originalvotesnum)) + "</div>");
        this.downArrow = $("<img alt='v' title='vote down' id='ui-downvote'>");
        this.downArrow.attr('onmouseover', 'src="/images/votearrowover.png"');
        this.downArrow.attr('onmousedown', 'src="/images/votearrowdown.png"');
        $(this.element).append(this.upArrow);
        $(this.element).append(this.votetext);
        $(this.element).append(this.downArrow);
        this.setImages();
        if (this.options.vote === true) {
          this.pressUp();
          return this.disable();
        } else if (this.options.vote === false) {
          this.pressDown();
          return this.disable();
        } else {
          this.upArrow.click(function() {
            return _this.pressUp();
          });
          return this.downArrow.click(function() {
            return _this.pressDown();
          });
        }
      };

      Plugin.prototype.pressUp = function() {
        if (this.state !== this._states.up) {
          this.state = this._states.up;
        } else {
          this.voteCount(originalvotesnum);
          this.state = this._states.none;
        }
        this.votetext.text(Math.round(this.voteCount()));
        $(this.element).trigger('votetextChanged', [parseInt(this.votetext.text()), this.voteCount()]);
        this.setImages();
        if (this.state === this._states.up) {
          this.disable();
          this.options.callback(",correct");
        }
        return $(this.element).trigger('upArrowPressed', this.state);
      };

      Plugin.prototype.pressDown = function() {
        if (this.state !== this._states.down) {
          this.state = this._states.down;
        } else {
          this.voteCount(originalvotesnum);
          this.state = this._states.none;
        }
        this.votetext.text(Math.round(this.voteCount()));
        $(this.element).trigger('votetextChanged', [parseInt(this.votetext.text()), this.voteCount()]);
        this.setImages();
        if (this.state === this._states.down) {
          this.disable();
          this.options.callback(",incorrect");
        }
        return $(this.element).trigger('downArrowPressed', this.state);
      };

      Plugin.prototype.setImages = function() {
        if (this.state === this._states.down) {
          this.downArrow.attr('src', '/images/votearrowcomplete.png');
          this.downArrow.attr('onmouseout', 'src="/images/votearrowcomplete.png"');
          this.downArrow.attr('onmouseup', 'src="/images/votearrowcomplete.png"');
          this.upArrow.attr('src', '/images/votearrow.png');
          this.upArrow.attr('onmouseout', 'src="/images/votearrow.png"');
          return this.upArrow.attr('onmouseup', 'src="/images/votearrow.png"');
        } else if (this.state === this._states.up) {
          this.upArrow.attr('src', '/images/votearrowcomplete.png');
          this.upArrow.attr('onmouseout', 'src="/images/votearrowcomplete.png"');
          this.upArrow.attr('onmouseup', 'src="/images/votearrowcomplete.png"');
          this.downArrow.attr('src', '/images/votearrow.png');
          this.downArrow.attr('onmouseout', 'src="/images/votearrow.png"');
          return this.downArrow.attr('onmouseup', 'src="/images/votearrow.png"');
        } else if (this.state === this._states.none) {
          this.upArrow.attr('src', '/images/votearrow.png');
          this.upArrow.attr('onmouseout', 'src="/images/votearrow.png"');
          this.upArrow.attr('onmouseup', 'src="/images/votearrow.png"');
          this.downArrow.attr('src', '/images/votearrow.png');
          this.downArrow.attr('onmouseout', 'src="/images/votearrow.png"');
          return this.downArrow.attr('onmouseup', 'src="/images/votearrow.png"');
        }
      };

      Plugin.prototype.disable = function() {
        this.upArrow.attr('disabled', 'disabled');
        this.downArrow.attr('disabled', 'disabled');
        this.upArrow.unbind('click');
        this.downArrow.unbind('click');
        this.upArrow.removeAttr('onmouseout');
        this.upArrow.removeAttr('onmouseup');
        this.upArrow.removeAttr('onmouseover');
        this.upArrow.removeAttr('onmousedown');
        this.downArrow.removeAttr('onmouseout');
        this.downArrow.removeAttr('onmouseup');
        this.downArrow.removeAttr('onmouseover');
        return this.downArrow.removeAttr('onmousedown');
      };

      Plugin.prototype.voteCount = function(newVotesNum) {
        if (newVotesNum == null) newVotesNum = null;
        if (newVotesNum === null) {
          return this.options.votesnum;
        } else {
          return this.options.votesnum = newVotesNum;
        }
      };

      Plugin.prototype.getState = function() {
        return this.options.pressState;
      };

      return Plugin;

    })();
    return $.fn[pluginName] = function(options) {
      return this.each(function() {
        if (!$.data(this, "plugin_" + pluginName)) {
          return $.data(this, "plugin_" + pluginName, new Plugin(this, options));
        }
      });
    };
  })(jQuery, window, document);

}).call(this);
