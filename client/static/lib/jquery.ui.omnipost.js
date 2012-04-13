(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  (function($, window, document) {
    var LinkPanel, Panel, Plugin, VideoPanel, defaults, pluginName, states;
    pluginName = 'omnipost';
    defaults = {
      editing: true,
      callback: ''
    };
    states = {
      none: 0,
      open: 1
    };
    Panel = (function() {

      function Panel(id, iconSrc, collapseSrc, removalCallBack) {
        this.id = id;
        this.iconSrc = iconSrc;
        this.collapseSrc = collapseSrc;
        this.removalCallBack = removalCallBack;
        this.remove = __bind(this.remove, this);
        this.isEmpty = __bind(this.isEmpty, this);
        this.hide = __bind(this.hide, this);
        this.show = __bind(this.show, this);
        this.addPanelToContainer = __bind(this.addPanelToContainer, this);
        this.init = __bind(this.init, this);
        this.init();
      }

      Panel.prototype.init = function() {
        var _this = this;
        this.slideSpeed = 200;
        this.panelcontainer = $("<div class=" + this.id + "></div>");
        this.linkIcon = $("<img class = 'ui-panelicon' src = " + this.iconSrc + " alt = 'attach'>");
        this.collapseIcon = $("<img class = 'ui-panelcollapseicon' src = " + this.collapseSrc + " alt = 'collapse'>");
        this.panelcontainer.append(this.linkIcon);
        this.panelcontainer.append(this.linkbox);
        this.panelcontainer.append(this.collapseIcon);
        this.panelcontainer.append(this.submitLink);
        return this.collapseIcon.click(function() {
          return _this.remove();
        });
      };

      Panel.prototype.addPanelToContainer = function(container) {
        return container.append(this.panelcontainer);
      };

      Panel.prototype.show = function() {
        return this.panelcontainer.show("slide", {
          direction: "up"
        }, this.slideSpeed);
      };

      Panel.prototype.hide = function() {
        return this.panelcontainer.hide();
      };

      Panel.prototype.isEmpty = function() {
        return this.linkbox.val() === '';
      };

      Panel.prototype.remove = function() {
        this.removalCallBack(this);
        return this.panelcontainer.remove();
      };

      return Panel;

    })();
    LinkPanel = (function(_super) {

      __extends(LinkPanel, _super);

      function LinkPanel() {
        this.content = __bind(this.content, this);
        this.hide = __bind(this.hide, this);
        LinkPanel.__super__.constructor.apply(this, arguments);
      }

      LinkPanel.prototype.init = function() {
        var _this = this;
        this.maximagewidth = 350;
        LinkPanel.__super__.init.apply(this, arguments).init();
        this.linkbox = $("<textarea class='ui-omniPostLink'></textarea>");
        this.submitLink = $("<button class='ui-submitLink'>Add</button>");
        this.displayedContent = 'none';
        this.attachedImage = $("<img width = '" + this.maximagewidth + "' height = 'auto' class = 'ui-attachedImage' src = '' alt = 'attach'>");
        this.linktosite = $("<a href = " + (this.linkbox.val()) + " class = 'ui-linkToSite'></a>");
        this.linkedcontentpreview = $("<iframe id='frame' src='' scrolling = no></iframe>");
        this.panelcontainer.append(this.linkbox);
        this.panelcontainer.append(this.submitLink);
        this.panelcontainer.append(this.attachedImage);
        this.panelcontainer.append(this.linktosite);
        this.panelcontainer.append(this.linkedcontentpreview);
        this.attachedImage.hide();
        this.linkedcontentpreview.hide();
        this.linkbox.change(function() {
          _this.displayedContent = 'image';
          _this.attachedImage.show();
          _this.linktosite.text('');
          return _this.attachedImage.attr('src', _this.linkbox.val());
        });
        return $(document).ready(function() {
          return _this.attachedImage.error(function() {
            _this.attachedImage.hide();
            if (_this.attachedImage.attr('src') !== '') {
              _this.displayedContent = 'link';
              _this.linktosite.attr('href', _this.linkbox.val());
              _this.linktosite.text(_this.linkbox.val());
              if (_this.linktosite.text().indexOf("http://") !== 0) {
                _this.linktosite.attr('href', 'http://' + _this.linktosite.attr('href'));
              }
              _this.linkedcontentpreview.show();
              return _this.linkedcontentpreview.attr('src', _this.linktosite.attr('href'));
            }
          });
        });
      };

      LinkPanel.prototype.hide = function() {
        LinkPanel.__super__.hide.apply(this, arguments).hide();
        this.linkbox.val('');
        this.attachedImage.attr('src', '');
        this.linktosite.text('');
        this.linkedcontentpreview.attr('src', '');
        return this.linkedcontentpreview.hide();
      };

      LinkPanel.prototype.content = function() {
        if (this.displayedContent === 'image') {
          return $.trim(this.attachedImage[0].outerHTML);
        } else if (this.displayedContent === 'link') {
          return $.trim(this.linktosite[0].outerHTML);
        } else {
          return null;
        }
      };

      return LinkPanel;

    })(Panel);
    VideoPanel = (function(_super) {

      __extends(VideoPanel, _super);

      function VideoPanel() {
        VideoPanel.__super__.constructor.apply(this, arguments);
      }

      VideoPanel.prototype.init = function() {
        VideoPanel.__super__.init.apply(this, arguments).init();
        this.linkbox = $("<textarea class='ui-omniPostLink'></textarea>");
        this.submitLink = $("<button class='ui-submitLink'>Add</button>");
        this.panelcontainer.append(this.linkbox);
        return this.panelcontainer.append(this.submitLink);
      };

      return VideoPanel;

    })(Panel);
    return Plugin = (function() {

      function Plugin(element, options) {
        this.element = element;
        this.removeElementFromPanelList = __bind(this.removeElementFromPanelList, this);
        this.removeAllPanels = __bind(this.removeAllPanels, this);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'tagbox';
        this._states = states;
        this.init();
      }

      Plugin.prototype.init = function() {
        var collapse, link, message, omnicontainer, omnipostdiv, paneldiv, panelselectors, post, selectedImageLink, text, videolink,
          _this = this;
        this.state = this._states.none;
        this.panelList = [];
        message = 'Post your reply here...';
        omnipostdiv = $("<div class = 'ui-omnipost'></div>");
        collapse = $("<img alt='x' title='x' id='ui-omniPostCollapse'>");
        collapse.attr('src', '/images/collapse.png');
        link = $("<img alt='a' title='attach a link' id='ui-omniPostAttach'>");
        link.attr('src', '/images/linkAttach.png');
        videolink = $("<img alt='a' title='attach a link' id='ui-omniPostVideoAttach'>");
        videolink.attr('src', '/images/videoAttach.png');
        panelselectors = $("<div id = 'ui-panelSelectors'></div>");
        panelselectors.append(videolink);
        panelselectors.append(link);
        omnicontainer = $("<div id='ui-omniContainer'></div>");
        text = $("<textarea id='ui-omniPostText'></textarea>");
        text.autoResize({
          extraSpace: 50
        }).addClass('ui-omniPost');
        selectedImageLink = $("<img alt='x' title='your linked image' id='ui-omniPostImage'>");
        selectedImageLink.hide();
        omnicontainer.append(text);
        omnicontainer.append(collapse);
        omnicontainer.append(panelselectors);
        omnipostdiv.append(omnicontainer);
        $(this.element).append(selectedImageLink);
        paneldiv = $("<div id='panels-container'></div>");
        omnipostdiv.append(paneldiv);
        $(this.element).append($('<br/>'));
        post = $("<button id='ui-omniPostSubmit'>Post</button>");
        omnipostdiv.append(post);
        $(this.element).append(omnipostdiv);
        $(this.element).addClass('ui-omniPost');
        omnicontainer.click(function() {
          if (!text.attr('readonly')) {
            post.show();
            collapse.show();
            panelselectors.show();
            if (text.height() < 50) text.height(50);
          }
          text.removeClass('ui-omniPostActive');
          if (text.val() === message) text.val('');
          text.focus();
          if (_this.state === _this._states.none) _this.state = _this._states.open;
          return $(_this.element).trigger('omnicontainerOpened', _this.state);
        });
        collapse.click(function(event) {
          post.hide();
          text.val(message);
          text.addClass('ui-omniPostActive');
          text.height(28);
          collapse.hide();
          panelselectors.hide();
          _this.removeAllPanels();
          event.stopPropagation();
          _this.state = _this._states.none;
          return $(_this.element).trigger('omnicontainerClosed', _this.state);
        });
        collapse.click();
        link.click(function(event) {
          var linkPanel;
          event.stopPropagation();
          linkPanel = new LinkPanel('ui-linkbox', '/images/linkAttach.png', '/images/collapse.png', _this.removeElementFromPanelList);
          linkPanel.addPanelToContainer(paneldiv);
          linkPanel.hide();
          linkPanel.show();
          _this.panelList.push(linkPanel);
          return $(_this.element).trigger('panelsChanged', _this.panelList.length);
        });
        videolink.click(function(event) {
          var videoPanel;
          event.stopPropagation();
          videoPanel = new VideoPanel('ui-videobox', '/images/videoAttach.png', '/images/collapse.png', _this.removeElementFromPanelList);
          videoPanel.addPanelToContainer(paneldiv);
          videoPanel.hide();
          videoPanel.show();
          _this.panelList.push(videoPanel);
          return $(_this.element).trigger('panelsChanged', _this.panelList.length);
        });
        return post.click(function() {
          var allPanelContent, data, panel, _i, _len, _ref;
          allPanelContent = $("<div id='rich-content'></div>");
          _ref = _this.panelList;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            panel = _ref[_i];
            allPanelContent.append(panel.content());
          }
          data = {
            posttext: $.trim(text.val()),
            linkdata: allPanelContent[0].outerHTML
          };
          omnipostdiv.remove();
          return _this.options.callback(data);
        });
      };

      Plugin.prototype.removeAllPanels = function() {
        var panel, removedPanels, _i, _j, _len, _len2, _ref;
        removedPanels = [];
        _ref = this.panelList;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          panel = _ref[_i];
          removedPanels.push(panel);
        }
        for (_j = 0, _len2 = removedPanels.length; _j < _len2; _j++) {
          panel = removedPanels[_j];
          panel.remove();
        }
        return $(this.element).trigger('panelsChanged', this.panelList.length);
      };

      Plugin.prototype.removeElementFromPanelList = function(element) {
        var index;
        index = this.panelList.indexOf(element);
        if (index > -1) this.panelList.splice(index, 1);
        return $(this.element).trigger('panelsChanged', this.panelList.length);
      };

      Plugin.prototype.destroy = function() {
        return $(this.element).remove();
      };

      Plugin.prototype._setOption = function(option, value) {
        return $.Widget.prototype._setOption.apply(this, arguments);
      };

      $.fn[pluginName] = function(options) {
        return this.each(function() {
          if (!$.data(this, "plugin_" + pluginName)) {
            return $.data(this, "plugin_" + pluginName, new Plugin(this, options));
          }
        });
      };

      return Plugin;

    })();
  })(jQuery, window, document);

}).call(this);
