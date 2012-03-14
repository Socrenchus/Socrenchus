
(function($) {
  return $.widget("ui.omnipost", {
    _create: function() {
      var collapse, link, linkBox, post, selectedImageLink, text,
        _this = this;
      collapse = $("<img alt='x' title='x' id='ui-omniPostCollapse'>");
      collapse.attr('src', 'http://officeimg.vo.msecnd.net/en-us/images/MB900432537.jpg');
      link = $("<img alt='a' title='attach a link' id='ui-omniPostAttach'>");
      link.attr('src', 'http://b.dryicons.com/images/icon_sets/coquette_part_2_icons_set/png/128x128/attachment.png');
      text = $("<textarea id='ui-omniPostText'></textarea>");
      text.autoResize({
        extraSpace: 50
      }).addClass('ui-omniPost');
      linkBox = $("<textarea id='ui-omniPostLink'></textarea>");
      linkBox.height(25);
      linkBox.width(500);
      selectedImageLink = $("<img alt='x' title='your linked image' id='ui-omniPostImage'>");
      selectedImageLink.hide();
      this.element.append(collapse);
      this.element.append(link);
      this.element.append(text);
      this.element.append(linkBox);
      this.element.append(selectedImageLink);
      this.element.append($('<br/>'));
      post = $("<button id='ui-omniPostSubmit'>Post</button>");
      this.element.append(post);
      this.element.addClass('ui-omniPost');
      this.element.focusin(function() {
        if (!text.attr('readonly')) {
          post.show();
          collapse.show();
          link.show();
          if (text.height() < 50) text.height(50);
        }
        text.removeClass('ui-omniPostActive');
        if (text.val() === _this.element.attr('title')) return text.val('');
      });
      linkBox.change(function() {
        selectedImageLink.show();
        return selectedImageLink.attr('src', linkBox.val());
      });
      collapse.click(function() {
        post.hide();
        text.val(_this.element.attr('title'));
        text.addClass('ui-omniPostActive');
        text.height(28);
        collapse.hide();
        link.hide();
        linkBox.val('');
        linkBox.hide();
        return selectedImageLink.hide();
      }).click();
      this.element.focusout(function() {
        if (text.val() === '' && !linkBox.visible()) return collapse.click();
      });
      return link.click(function() {
        return linkBox.show();
      });
    },
    destroy: function() {
      return this.element.remove();
    },
    _setOption: function(option, value) {
      return $.Widget.prototype._setOption.apply(this, arguments);
    }
  });
})(jQuery);

$("#myPostBox").omnipost();
