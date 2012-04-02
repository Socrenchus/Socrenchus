(function() {
  ;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($, window, document) {
    var Plugin, defaults, pluginName;
    pluginName = 'votebox';
    defaults = {
      votesnum: 0
    };
    Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.voteCount = __bind(this.voteCount, this);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'votebox';
        this.init();
      }

      Plugin.prototype.init = function() {
        var currentArrowImage, downArrow, downpressed, originalvotesnum, upArrow, uppressed, votetext,
          _this = this;
        uppressed = false;
        downpressed = false;
        originalvotesnum = this._defaults.votesnum;
        currentArrowImage = "images/votearrow.png";
        upArrow = $("<img alt='^' title='vote up' id='ui-upvote'>");
        upArrow.attr('src', 'images/votearrow.png');
        upArrow.attr('onmouseover', 'src="images/votearrowover.png"');
        upArrow.attr('onmousedown', 'src="images/votearrowdown.png"');
        upArrow.attr('onmouseout', 'src="images/votearrow.png"');
        upArrow.attr('onmouseup', 'src="images/votearrow.png"');
        $(this.element).append(upArrow);
        votetext = $("<h2 id='ui-votetext'>" + this._defaults.votesnum + "</h2>");
        $(this.element).append(votetext);
        downArrow = $("<img alt='v' title='vote down' id='ui-downvote'>");
        downArrow.attr('src', 'images/votearrow.png');
        downArrow.attr('onmouseover', 'src="images/votearrowover.png"');
        downArrow.attr('onmousedown', 'src="images/votearrowdown.png"');
        downArrow.attr('onmouseout', 'src="images/votearrow.png"');
        downArrow.attr('onmouseup', 'src="images/votearrow.png"');
        $(this.element).append(downArrow);
        upArrow.click(function() {
          if (uppressed === false) {
            _this.voteCount(originalvotesnum + 1);
            upArrow.attr('src', 'images/votearrowcomplete.png');
            upArrow.attr('onmouseout', 'src="images/votearrowcomplete.png"');
            upArrow.attr('onmouseup', 'src="images/votearrowcomplete.png"');
            uppressed = true;
          } else {
            _this.voteCount(originalvotesnum);
            upArrow.attr('src', 'images/votearrow.png');
            upArrow.attr('onmouseout', 'src="images/votearrow.png"');
            upArrow.attr('onmouseup', 'src="images/votearrow.png"');
            uppressed = false;
          }
          votetext.text(_this.voteCount());
          downArrow.attr('src', 'images/votearrow.png');
          downArrow.attr('onmouseout', 'src="images/votearrow.png"');
          downArrow.attr('onmouseup', 'src="images/votearrow.png"');
          return downpressed = false;
        });
        return downArrow.click(function() {
          if (downpressed === false) {
            _this.voteCount(originalvotesnum - 1);
            downArrow.attr('src', 'images/votearrowcomplete.png');
            downArrow.attr('onmouseout', 'src="images/votearrowcomplete.png"');
            downArrow.attr('onmouseup', 'src="images/votearrowcomplete.png"');
            downpressed = true;
          } else {
            _this.voteCount(originalvotesnum);
            downArrow.attr('src', 'images/votearrow.png');
            downArrow.attr('onmouseout', 'src="images/votearrow.png"');
            downArrow.attr('onmouseup', 'src="images/votearrow.png"');
            downpressed = false;
          }
          votetext.text(_this.voteCount());
          upArrow.attr('src', 'images/votearrow.png');
          upArrow.attr('onmouseout', 'src="images/votearrow.png"');
          upArrow.attr('onmouseup', 'src="images/votearrow.png"');
          return uppressed = false;
        });
      };

      Plugin.prototype.voteCount = function(newVotesNum) {
        if (newVotesNum == null) newVotesNum = null;
        if (newVotesNum === null) {
          return this._defaults.votesnum;
        } else {
          return this._defaults.votesnum = newVotesNum;
        }
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
