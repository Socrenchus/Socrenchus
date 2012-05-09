(function() {
  ;
  (function($, window, document) {
    var Plugin, defaults, pluginName;
    pluginName = 'voteBox';
    defaults = {
      property: 'value'
    };
    Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'voteBox';
        this.init();
      }

      Plugin.prototype.init = function() {};

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
