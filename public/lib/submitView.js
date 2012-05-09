(function() {
  ;
  (function($, window, document) {
    var Plugin, defaults, pluginName;
    pluginName = 'submitView';
    defaults = {
      tools: $()
    };
    Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'submitView';
        this.init();
      }

      Plugin.prototype.init = function() {
        var _this = this;
        this.element = $(this.element);
        return this.element.focusin(function() {
          if (_this.element.attr('readonly') == null) {
            _this.options['tools'].show();
          }
          _this.element.removeClass('defaultTextActive');
          if (_this.element.val() === _this.element.attr('title')) {
            return _this.element.text('');
          }
        }).focusout(function() {
          if (_this.element.val() === '') {
            _this.options['tools'].hide();
            _this.element.text(_this.element.attr('title'));
            return _this.element.addClass('defaultTextActive');
          }
        }).focusout();
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
