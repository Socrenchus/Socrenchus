(function() {
  ;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($, window, document) {
    var Plugin, defaults, pluginName, states;
    pluginName = 'tagbox';
    states = {
      none: 0,
      typing: 1,
      altering: 2
    };
    defaults = {
      editing: true,
      tags: [],
      callback: ''
    };
    Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.maketags = __bind(this.maketags, this);
        this.getAllTags = __bind(this.getAllTags, this);
        this.createcompletetags = __bind(this.createcompletetags, this);
        this.deformtag = __bind(this.deformtag, this);
        this.formtag = __bind(this.formtag, this);
        this.makenewtag = __bind(this.makenewtag, this);
        this.removeFromArray = __bind(this.removeFromArray, this);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._states = states;
        this.state = states.none;
        this._name = 'tagbox';
        this.init();
      }

      Plugin.prototype.init = function() {
        var addtagstext, editingoldtag, tagIcon,
          _this = this;
        this.alltags = [];
        editingoldtag = false;
        addtagstext = 'Tag the above post here...';
        if (this.options.editing) {
          this.tagsdiv = $("<div class='ui-tagbox'></div>");
          this.tagtext = $("<div class='ui-tagtext' contentEditable='false'></div>");
          this.tagsdiv.append(this.tagtext);
          $(this.element).append(this.tagsdiv);
          tagIcon = $("<div contentEditable='false'><img src = '/images/tag.png' id = 'ui-tagicon'/></div>");
          this.currenttag = $("<div class='ui-individualtag' contentEditable='true'></div>");
          this.message = $("<div class='ui-tagmessage'>" + addtagstext + "</div>");
          this.tagtext.append(tagIcon);
          this.tagtext.append(this.message);
          this.tagtext.append(this.currenttag);
          this.submit = $("<button id='ui-tagboxSubmit'>Submit Tags</button>");
          this.tagsdiv.append(this.submit);
          this.submit.hide();
          this.submit.click(function() {
            var tags;
            return tags = _this.maketags();
          });
          this.tagtext.focusout(function() {
            if (_this.alltags.length === 0 && _this.currenttag.text() === '') {
              _this.message.show();
              _this.submit.hide();
            }
            _this.state = _this._states.none;
            return $(_this.element).trigger('unfocusingTagBox', _this.state);
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
              _this.currenttag.focus();
              _this.submit.show();
              _this.state = _this._states.typing;
              return $(_this.element).trigger('typingTag', _this.state);
            }
          });
        } else {
          return this.createcompletetags(this.options.tags);
        }
      };

      Plugin.prototype.removeFromArray = function(toremove) {
        var index;
        index = this.alltags.indexOf(toremove);
        if (index > -1) this.alltags.splice(index, 1);
        return $(this.element).trigger('tagRemoved', this.alltags.length);
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
          _this.removeFromArray(tagdiv);
          return deletetagicon.parent().remove();
        });
        tagdiv.click(function() {
          var state;
          _this.deformtag(tagdiv);
          return state = states.altering;
        });
        tagdiv.attr('contentEditable', 'false');
        tagdiv.css('background-image', 'url("/images/tagOutline.png")');
        tagdiv.css('background-repeat', 'no-repeat');
        tagdiv.css('background-size', '100% 100%');
        this.alltags.push(tagdiv);
        return $(this.element).trigger('tagAdded', this.alltags.length);
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
        this.removeFromArray(tagdiv);
        tagdiv.focus();
        this.state = this._states.altering;
        return $(this.element).trigger('alteringTag', this.state);
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

      Plugin.prototype.getAllTags = function() {
        var tag, tags, _i, _len, _ref;
        tags = [];
        _ref = this.alltags;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          tag = _ref[_i];
          tags.push(tag.text());
        }
        return tags;
      };

      Plugin.prototype.maketags = function() {
        var individualTag, tag, tags, _i, _j, _len, _len2, _ref, _results;
        tags = this.getAllTags();
        for (_i = 0, _len = tags.length; _i < _len; _i++) {
          tag = tags[_i];
          this.options.callback(tag);
        }
        _ref = this.alltags;
        _results = [];
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          individualTag = _ref[_j];
          _results.push(individualTag.find('.delete-imageicon').click());
        }
        return _results;
      };

      Plugin.setCurrentTag = function(text) {
        return Plugin.currenttag.text(text);
      };

      return Plugin;

    }).call(this);
    return $.fn[pluginName] = function(options) {
      return this.each(function() {
        if (!$.data(this, "plugin_" + pluginName)) {
          return $.data(this, "plugin_" + pluginName, new Plugin(this, options));
        }
      });
    };
  })(jQuery, window, document);

}).call(this);
