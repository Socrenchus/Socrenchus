(function() {
  ;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($, window, document) {
    var Plugin, defaults, pluginName, states;
    pluginName = 'notify';
    defaults = {
      notificationCount: 0,
      position: 'topleft',
      messages: ['fake message', 'and another']
    };
    states = {
      none: 0,
      open: 1
    };
    Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.addMessages = __bind(this.addMessages, this);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'notify';
        this._states = states;
        this.init();
      }

      Plugin.prototype.init = function() {
        var notifycounter,
          _this = this;
        this.state = this._states.none;
        notifycounter = $("<h3 id='notification-counter' title='Notifications'>" + this.options.notificationCount + "</h3>");
        this.notifypanel = $("<div id='notification-box'></div>");
        this.notifypanel.append($("<h3 id='notify-text'>Notifications</h3>"));
        this.addMessages();
        this.notifypanel.hide();
        $(this.element).append(notifycounter);
        $(this.element).append(this.notifypanel);
        notifycounter.click(function(event) {
          _this.notifypanel.fadeToggle("slow");
          if (_this.state === _this._states.none) {
            _this.state = _this._states.open;
          } else if (_this.state === _this._states.open) {
            _this.state = _this._states.none;
          }
          $(_this.element).trigger('notifyClicked', _this.state);
          return event.stopPropagation();
        });
        $(document).click(function() {
          _this.notifypanel.hide();
          _this.state = _this._states.none;
          return $(_this.element).trigger('documentClicked', _this.state);
        });
        return this.notifypanel.load(function() {
          if (_this.options.position === 'lefttop') {
            _this.notifypanel.css("left", notifycounter.outerWidth());
            return _this.notifypanel.css("top", -notifycounter.outerHeight());
          } else if (_this.options.position === 'topright') {
            return _this.notifypanel.css("left", -_this.notifypanel.width() + notifycounter.outerWidth());
          } else if (_this.options.position === 'righttop') {
            _this.notifypanel.css("left", -_this.notifypanel.width());
            return _this.notifypanel.css("top", -notifycounter.outerHeight());
          } else if (_this.options.position === 'bottomright') {
            _this.notifypanel.css("left", -_this.notifypanel.width() + notifycounter.outerWidth());
            return _this.notifypanel.css("top", -_this.notifypanel.height() - notifycounter.outerHeight());
          } else if (_this.options.position === 'rightbottom') {
            _this.notifypanel.css("left", -_this.notifypanel.width());
            return _this.notifypanel.css("top", -_this.notifypanel.height());
          } else if (_this.options.position === 'bottomleft') {
            _this.notifypanel.css("left", 0);
            return _this.notifypanel.css("top", -_this.notifypanel.height() - notifycounter.outerHeight());
          } else if (_this.options.position === 'leftbottom') {
            _this.notifypanel.css("left", notifycounter.outerWidth());
            return _this.notifypanel.css("top", -_this.notifypanel.height());
          }
        });
      };

      Plugin.prototype.addMessages = function() {
        var message, messagediv, _i, _len, _ref, _results;
        _ref = this.options.messages;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          message = _ref[_i];
          messagediv = $("<h4 class='notify-message'>" + message + "</h4>");
          _results.push(this.notifypanel.append(messagediv));
        }
        return _results;
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
