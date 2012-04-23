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
        this.setImages = __bind(this.setImages, this);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'votebox';
        this._states = states;
        this.init();
      }

      Plugin.prototype.init = function() {
        var downpressed, originalvotesnum, uppressed, voteboxdiv, votetext,
          _this = this;
        this.state = this._states.none;
        uppressed = false;
        downpressed = false;
        originalvotesnum = this.options.votesnum;
        voteboxdiv = $("<div class = 'ui-votebox'></div>");
        this.upArrow = $("<img alt='^' title='vote up' id='ui-upvote'>");
        this.upArrow.attr('onmouseover', 'src="/images/votearrowover.png"');
        this.upArrow.attr('onmousedown', 'src="/images/votearrowdown.png"');
        votetext = $("<div id='ui-votetext'>" + originalvotesnum + "</div>");
        this.downArrow = $("<img alt='v' title='vote down' id='ui-downvote'>");
        this.downArrow.attr('onmouseover', 'src="/images/votearrowover.png"');
        this.downArrow.attr('onmousedown', 'src="/images/votearrowdown.png"');
        voteboxdiv.append(this.upArrow);
        voteboxdiv.append(votetext);
        voteboxdiv.append(this.downArrow);
        $(this.element).append(voteboxdiv);
        this.setImages();
        this.upArrow.click(function() {
          if (_this.state !== _this._states.up) {
            _this.voteCount(originalvotesnum + 1);
            _this.state = _this._states.up;
          } else {
            _this.voteCount(originalvotesnum);
            _this.state = _this._states.none;
          }
          votetext.text(_this.voteCount());
          $(_this.element).trigger('votetextChanged', [parseInt(votetext.text()), _this.voteCount()]);
          _this.setImages();
          if (_this.state === _this._states.up) _this.options.callback(",correct");
          return $(_this.element).trigger('upArrowPressed', _this.state);
        });
        return this.downArrow.click(function() {
          if (_this.state !== _this._states.down) {
            _this.voteCount(originalvotesnum - 1);
            _this.state = _this._states.down;
          } else {
            _this.voteCount(originalvotesnum);
            _this.state = _this._states.none;
          }
          votetext.text(_this.voteCount());
          $(_this.element).trigger('votetextChanged', [parseInt(votetext.text()), _this.voteCount()]);
          _this.setImages();
          if (_this.state === _this._states.down) {
            _this.options.callback(",incorrect");
          }
          return $(_this.element).trigger('downArrowPressed', _this.state);
        });
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
