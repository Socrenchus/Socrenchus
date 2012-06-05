;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

(function($, window, document) {
  var Plugin, defaults, pluginName, states;
  pluginName = 'notify';
  defaults = {
    notificationCount: 0,
    position: 'topleft',
    messages: []
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
      var html, notifycounter, template, templatedata,
        _this = this;
      this.state = this._states.none;
      template = "<h3 id='notification-counter' title='Notifications'>                    {{notificationCount}}                   </h3>                   <div id='notification-box'></div>                  ";
      templatedata = {
        notificationCount: this.options.notificationCount
      };
      html = Mustache.to_html(template, templatedata);
      $(this.element).html(html);
      notifycounter = $(this.element).find("#notification-counter");
      this.notifypanel = $(this.element).find("#notification-box");
      this.notifypanel.hide();
      this.addMessages();
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
      var message, messagediv, params, _i, _len, _ref;
      _ref = this.options.messages;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        message = _ref[_i];
        messagediv = $("<li class='notify-message'>" + message + "</li>");
        this.notifypanel.append(messagediv);
      }
      params = {
        messages: this.options.messages,
        messagecount: this.options.notificationCount
      };
      return $(this.element).trigger('messagesadded', params);
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
