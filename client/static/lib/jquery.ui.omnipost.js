(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  (function($, window, document) {
    var LinkPanel, Panel, Plugin, VideoPanel, defaults, pluginName;
    pluginName = 'omnipost';
    defaults = {
      editing: true,
      postcontent: '',
      linkedcontent: ''
    };
    Panel = (function() {

      function Panel(id, iconSrc, collapseSrc) {
        this.id = id;
        this.iconSrc = iconSrc;
        this.collapseSrc = collapseSrc;
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
          return _this.hide();
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
        this.maximagewidth = 300;
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
          return this.attachedImage;
        } else if (this.displayedContent === 'link') {
          return this.linktosite;
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
        this.createcompletepost = __bind(this.createcompletepost, this);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = 'tagbox';
        this.init();
      }

      Plugin.prototype.init = function() {
        var collapse, link, linkPanel, omnicontainer, panelselectors, post, selectedImageLink, text, videoPanel, videolink,
          _this = this;
        if (this.options.editing) {
          linkPanel = new LinkPanel('ui-linkbox', 'images/linkAttach.png', 'images/collapse.png');
          videoPanel = new VideoPanel('ui-linkbox', 'images/videoAttach.png', 'images/collapse.png');
          collapse = $("<img alt='x' title='x' id='ui-omniPostCollapse'>");
          collapse.attr('src', 'images/collapse.png');
          link = $("<img alt='a' title='attach a link' id='ui-omniPostAttach'>");
          link.attr('src', 'images/linkAttach.png');
          videolink = $("<img alt='a' title='attach a link' id='ui-omniPostVideoAttach'>");
          videolink.attr('src', 'images/videoAttach.png');
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
          $(this.element).append(omnicontainer);
          linkPanel.addPanelToContainer($(this.element));
          linkPanel.hide();
          videoPanel.addPanelToContainer($(this.element));
          videoPanel.hide();
          $(this.element).append(selectedImageLink);
          $(this.element).append($('<br/>'));
          post = $("<button id='ui-omniPostSubmit'>Post</button>");
          $(this.element).append(post);
          $(this.element).addClass('ui-omniPost');
          $(this.element).focusin(function() {
            if (!text.attr('readonly')) {
              post.show();
              collapse.show();
              panelselectors.show();
              if (text.height() < 50) text.height(50);
            }
            text.removeClass('ui-omniPostActive');
            if (text.val() === $(_this.element).attr('title')) return text.val('');
          });
          collapse.click(function() {
            post.hide();
            text.val($(_this.element).attr('title'));
            text.addClass('ui-omniPostActive');
            text.height(28);
            collapse.hide();
            panelselectors.hide();
            linkPanel.hide();
            return videoPanel.hide();
          }).click();
          link.click(function() {
            return linkPanel.show();
          });
          videolink.click(function() {
            return videoPanel.show();
          });
          return post.click(function() {
            var linkedcontent, textcontent;
            if (text.val() !== '' || !linkPanel.isEmpty()) {
              post.remove();
              textcontent = text.val();
              text.remove();
              linkedcontent = linkPanel.content();
              linkPanel.remove();
              videoPanel.remove();
              collapse.remove();
              panelselectors.remove();
              return _this.createcompletepost(textcontent, linkedcontent);
            }
          });
        } else {
          return this.createcompletepost(this.options.postcontent, this.options.linkedcontent);
        }
      };

      Plugin.prototype.createcompletepost = function(postcontent, linkedcontent) {
        var linkedelement, posttext,
          _this = this;
        posttext = $("<p class = 'posttext'>" + postcontent + "</p>");
        linkedelement = $("<img src = " + linkedcontent + " alt = 'linked content' />");
        $(document).ready(function() {
          return linkedelement.error(function() {
            var linkedcontentpreview;
            linkedelement.remove();
            linkedelement = $("<a href = " + linkedcontent + ">" + linkedcontent + "</a>");
            if (linkedcontent.indexOf("http://") !== 0) {
              linkedelement.attr('href', 'http://' + linkedelement.attr('href'));
            }
            linkedcontentpreview = $("<iframe id='frame' src=" + (linkedelement.attr('href')) + " scrolling = no></iframe>");
            _this.omnifinaldiv.prepend(linkedelement);
            return _this.omnifinaldiv.prepend(linkedcontentpreview);
          });
        });
        this.omnifinaldiv = $("<div id = 'ui-postedcontent'></div>");
        if (linkedcontent !== null) this.omnifinaldiv.append(linkedelement);
        if (postcontent !== '') this.omnifinaldiv.append(posttext);
        return $(this.element).append(this.omnifinaldiv);
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
