(function() {
  ;
  (function($, window, document) {
    var Plugin, defaults, pluginName;
    pluginName = 'notify';
    defaults = {
      notificationCount: 0,
      position: 'topleft'
    };
    Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'notify';
        this.init();
      }

      Plugin.prototype.init = function() {
        var imagepanel, notifycounter, notifydiv,
          _this = this;
        notifydiv = $("<div class = 'ui-notifybox'></div>");
        notifycounter = $("<h3 id='notification-counter' title='Notifications'>" + this.options.notificationCount + "</h3>");
        imagepanel = $("<img id='notification-box' src='/images/notifications.png'>");
        imagepanel.hide();
        notifydiv.append(notifycounter);
        notifydiv.append(imagepanel);
        $(this.element).append(notifydiv);
        notifycounter.click(function() {
          imagepanel.fadeToggle("slow");
          return event.stopPropagation();
        });
        $(document).click(function() {
          return imagepanel.hide();
        });
        return imagepanel.load(function() {
          if (_this.options.position === 'lefttop') {
            imagepanel.css("left", notifycounter.outerWidth());
            return imagepanel.css("top", -notifycounter.outerHeight());
          } else if (_this.options.position === 'topright') {
            return imagepanel.css("left", -imagepanel.width() + notifycounter.outerWidth());
          } else if (_this.options.position === 'righttop') {
            imagepanel.css("left", -imagepanel.width());
            return imagepanel.css("top", -notifycounter.outerHeight());
          } else if (_this.options.position === 'bottomright') {
            imagepanel.css("left", -imagepanel.width() + notifycounter.outerWidth());
            return imagepanel.css("top", -imagepanel.height() - notifycounter.outerHeight());
          } else if (_this.options.position === 'rightbottom') {
            imagepanel.css("left", -imagepanel.width());
            return imagepanel.css("top", -imagepanel.height());
          } else if (_this.options.position === 'bottomleft') {
            imagepanel.css("left", 0);
            return imagepanel.css("top", -imagepanel.height() - notifycounter.outerHeight());
          } else if (_this.options.position === 'leftbottom') {
            imagepanel.css("left", notifycounter.outerWidth());
            return imagepanel.css("top", -imagepanel.height());
          }
        });
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
