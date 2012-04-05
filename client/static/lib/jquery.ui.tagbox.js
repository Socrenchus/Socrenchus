(function() {
  ;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($, window, document) {
    var Plugin, defaults, pluginName;
    pluginName = 'tagbox';
    defaults = {
      editing: true,
      tags: []
    };
    Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.createcompletetags = __bind(this.createcompletetags, this);
        this.deformtag = __bind(this.deformtag, this);
        this.formtag = __bind(this.formtag, this);
        this.makenewtag = __bind(this.makenewtag, this);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'tagbox';
        this.init();
      }

      Plugin.prototype.init = function() {
        var addtagstext, editingoldtag, tagIcon, tagsdiv,
          _this = this;
        this.alltags = [];
        editingoldtag = false;
        addtagstext = 'Tag the above post here...';
        if (this.options.editing) {
          tagsdiv = $("<div class='ui-tagbox'></div>");
          this.tagtext = $("<div class='ui-tagtext' contentEditable='false'></div>");
          tagsdiv.append(this.tagtext);
          $(this.element).append(tagsdiv);
          tagIcon = $("<div contentEditable='false'><img src = '/images/tag.png' id = 'ui-tagicon'/></div>");
          this.currenttag = $("<div class='ui-individualtag' contentEditable='true'></div>");
          this.message = $("<div class='ui-tagmessage'>" + addtagstext + "</div>");
          this.tagtext.append(tagIcon);
          this.tagtext.append(this.message);
          this.tagtext.append(this.currenttag);
          this.tagtext.focusout(function() {
            if (_this.alltags.length === 0 && _this.currenttag.text() === '') {
              return _this.message.show();
            }
          });
          this.tagtext.keydown(function(event) {
            if (event.keyCode === 13 || event.keyCode === 188) {
              event.preventDefault();
              return _this.makenewtag(_this.currenttag);
            }
          });
          return this.tagtext.click(function() {
            if (!_this.editingoldtag) {
              _this.message.hide();
              return _this.currenttag.focus();
            }
          });
        } else {
          return this.createcompletetags(this.options.tags);
        }
      };

      Plugin.prototype.removeFromArray = function(array, toremove) {
        var index;
        index = array.indexOf(toremove);
        if (index > -1) return array.splice(index, 1);
      };

      Plugin.prototype.makenewtag = function(tagdiv) {
        var newtag,
          _this = this;
        this.currenttag.text($.trim(this.currenttag.text()));
        if (this.currenttag.text() !== '') {
          tagdiv.focusout(function() {
            return _this.formtag(tagdiv);
          });
          newtag = $("<div class='ui-individualtag' contentEditable='true'></div>");
          this.tagtext.append(newtag);
          this.currenttag = newtag;
          return newtag.focus();
        }
      };

      Plugin.prototype.formtag = function(tagdiv) {
        var deletetagicon,
          _this = this;
        this.editingoldtag = false;
        tagdiv.text($.trim(tagdiv.text()));
        deletetagicon = $("<img width = '16px' class='delete-imageicon' src = '/images/collapse.png'>");
        tagdiv.append(deletetagicon);
        deletetagicon.click(function() {
          _this.removeFromArray(_this.alltags, deletetagicon.parent());
          return deletetagicon.parent().remove();
        });
        tagdiv.click(function() {
          return _this.deformtag(tagdiv);
        });
        tagdiv.attr('contentEditable', 'false');
        tagdiv.css('background-image', 'url("/images/tagOutline.png")');
        tagdiv.css('background-repeat', 'no-repeat');
        tagdiv.css('background-size', '100% 100%');
        return this.alltags.push(tagdiv);
      };

      Plugin.prototype.deformtag = function(tagdiv) {
        var deleteicon, deleteiconclass;
        this.editingoldtag = true;
        tagdiv.attr('contentEditable', 'true');
        tagdiv.css('background-image', 'none');
        tagdiv.css('background-repeat', 'no-repeat');
        tagdiv.css('background-size', '100% 100%');
        deleteiconclass = $('.delete-imageicon');
        deleteicon = $(tagdiv.find(deleteiconclass)[0]);
        deleteicon.remove();
        this.removeFromArray(this.alltags, tagdiv);
        return tagdiv.focus();
      };

      Plugin.prototype.createcompletetags = function(tags) {
        var currenttag, tag, tagsdiv, _i, _len;
        tagsdiv = $("<div class='ui-tagbox'></div>");
        for (_i = 0, _len = tags.length; _i < _len; _i++) {
          tag = tags[_i];
          currenttag = $("<div class='ui-individualtag'>" + tag + "</div>");
          currenttag.css('background-image', 'url("/images/tagOutline.png")');
          currenttag.css('background-repeat', 'no-repeat');
          currenttag.css('background-size', '100% 100%');
          tagsdiv.append(currenttag);
        }
        return $(this.element).append(tagsdiv);
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
