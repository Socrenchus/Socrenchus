(function() {
  ;
  (function($, window, document) {
    var Plugin, defaults, pluginName;
    pluginName = 'tagbox';
    defaults = {
      property: 'value'
    };
    Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'tagbox';
        this.init();
      }

      Plugin.prototype.init = function() {
        var alltags, currenttag, message, tagIcon, tagtext,
          _this = this;
        alltags = [];
        tagtext = $("<div id='ui-tagtext' contentEditable='false'></div>");
        $(this.element).append(tagtext);
        tagIcon = $("<div contentEditable='false'><img src = 'images/tag.png' id = 'ui-tagicon'/></div>");
        currenttag = $("<div class='ui-individualtag' contentEditable='true'></div>");
        message = $("<div class='ui-tagmessage'>" + ($(this.element).attr('title')) + "</div>");
        tagtext.append(tagIcon);
        tagtext.append(currenttag);
        tagtext.append(message);
        tagtext.focusout(function() {
          if (alltags.length === 0) {
            message = $("<div class='ui-tagmessage'>" + ($(_this.element).attr('title')) + "</div>");
            return tagtext.append(message);
          }
        });
        tagtext.keydown(function(event) {
          var newtag, tagToRemove;
          if (event.keyCode === 13 || event.keyCode === 188) {
            event.preventDefault();
            if (currenttag.text() !== '') {
              currenttag.attr('contentEditable', 'false');
              currenttag.css('background-image', 'url("images/tagOutline.png")');
              currenttag.css('background-repeat', 'no-repeat');
              currenttag.css('background-size', '100% 100%');
              alltags.push(currenttag);
              newtag = $("<div class='ui-individualtag' contentEditable='true'></div>");
              tagtext.append(newtag);
              newtag.focus();
              currenttag = newtag;
            }
          }
          if (event.keyCode === 8) {
            if (currenttag.text() === '' && alltags.length > 0) {
              tagToRemove = alltags[alltags.length - 1];
              tagToRemove.remove();
              return alltags.splice(alltags.length - 1, 1);
            }
          }
        });
        $('.ui-individualtag').click(function() {
          return $(this).remove();
        });
        return tagtext.click(function() {
          $("div.ui-tagmessage").remove();
          return currenttag.focus();
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
