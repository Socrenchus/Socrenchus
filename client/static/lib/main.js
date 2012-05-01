(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  $(function() {
    /*
      # Core Models and Logic
    */
    var App, Post, PostView, Posts, StreamView, Tag, TagView, Tags, Templates, Workspace, app_router, e, postCollection, tagCollection, _i, _len, _ref;
    Post = (function(_super) {

      __extends(Post, _super);

      function Post() {
        this.maketag = __bind(this.maketag, this);
        this.respond = __bind(this.respond, this);
        Post.__super__.constructor.apply(this, arguments);
      }

      Post.prototype.urlRoot = '/posts';

      Post.prototype.respond = function(content) {
        var p;
        p = new Post({
          parent: this.get('id'),
          content: content
        });
        return postCollection.create(p);
      };

      Post.prototype.maketag = function(content) {
        var t;
        t = new Tag({
          parent: this.get('id'),
          title: content,
          xp: 0
        });
        return tagCollection.create(t);
      };

      return Post;

    })(Backbone.Model);
    Posts = (function(_super) {

      __extends(Posts, _super);

      function Posts() {
        Posts.__super__.constructor.apply(this, arguments);
      }

      Posts.prototype.model = Post;

      Posts.prototype.url = '/posts';

      return Posts;

    })(Backbone.Collection);
    Tag = (function(_super) {

      __extends(Tag, _super);

      function Tag() {
        this.respond = __bind(this.respond, this);
        Tag.__super__.constructor.apply(this, arguments);
      }

      Tag.prototype.respond = function(content) {
        var t;
        t = new Tag({
          title: content,
          xp: 0
        });
        return tagCollection.create(t);
      };

      return Tag;

    })(Backbone.Model);
    Tags = (function(_super) {

      __extends(Tags, _super);

      function Tags() {
        Tags.__super__.constructor.apply(this, arguments);
      }

      Tags.prototype.model = Tag;

      Tags.prototype.url = '/tags';

      return Tags;

    })(Backbone.Collection);
    /*
      # Views
    */
    Templates = {};
    _ref = $('#templates').children();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      Templates[e.id] = $(e).html();
    }
    PostView = (function(_super) {

      __extends(PostView, _super);

      function PostView() {
        this.render = __bind(this.render, this);
        this.renderProgressBar = __bind(this.renderProgressBar, this);
        this.renderPostContent = __bind(this.renderPostContent, this);
        PostView.__super__.constructor.apply(this, arguments);
      }

      PostView.prototype.tagName = 'li';

      PostView.prototype.className = 'post';

      PostView.prototype.template = Templates.post;

      PostView.prototype.events = function() {};

      PostView.prototype.initialize = function() {
        this.id = this.model.id;
        this.model.bind('change', this.render);
        this.expstep = 25;
        return this.postreveal = 5;
      };

      PostView.prototype.renderPostContent = function() {
        var jsondata, postcontentdiv;
        jsondata = jQuery.parseJSON(this.model.get('content'));
        postcontentdiv = $("<div class = 'ui-postcontent'></div>");
        postcontentdiv.append($(jsondata.linkdata));
        postcontentdiv.append('<br />');
        postcontentdiv.append(jsondata.posttext);
        return $(this.el).find('.inner-question').append(postcontentdiv);
      };

      PostView.prototype.renderProgressBar = function() {
        var indicatortext, lockedpostsdiv, percent, progressbardiv, progressindicatordiv, textinline;
        if (this.model.get('parent') === '') {
          lockedpostsdiv = $("<div class='locked-posts'></div>");
          progressbardiv = $("<div class='progressbar'></div>");
          percent = this.model.get('newxp') % this.expstep / this.expstep * 100;
          textinline = true;
          indicatortext = $('<p id="indicator-text">Unlock ' + Math.floor(5) + ' posts</p>');
          if (percent < 100.0 / 350.0 * 100) textinline = false;
          if (textinline) {
            progressindicatordiv = $("<div class='progress-indicator' style='width:" + percent + "%'></div>");
            progressindicatordiv.append(indicatortext);
            progressbardiv.append(progressindicatordiv);
          } else {
            progressindicatordiv = $("<div class='progress-indicator' style='width:" + percent + "%'></div>");
            progressbardiv.append(progressindicatordiv);
            progressbardiv.append(indicatortext);
          }
          lockedpostsdiv.append(progressbardiv);
          return $(this.el).find('.inner-question').append(lockedpostsdiv);
        }
      };

      PostView.prototype.render = function() {
        var responsediv, tagsdiv;
        $(this.el).html(this.template);
        $(this.el).find('.inner-question').votebox({
          votesnum: this.model.get('score'),
          callback: this.model.maketag
        });
        this.renderPostContent();
        tagsdiv = $("<div id='tagscontainer'><div id = 'tags" + (this.model.get('id')) + "'></div></div>");
        $(this.el).find('.inner-question').append(tagsdiv);
        $(this.el).find('.inner-question').tagbox({
          callback: this.model.maketag
        });
        responsediv = $("<div id = 'response" + (this.model.get('id')) + "'></div>");
        $(this.el).find('.inner-question').append(responsediv);
        if (postCollection.where({
          parent: this.id
        }).length > 0) {
          this.renderProgressBar();
        } else {
          $(this.el).find('.inner-question').omnipost({
            callback: this.model.respond
          });
        }
        return $(this.el);
      };

      return PostView;

    })(Backbone.View);
    TagView = (function(_super) {

      __extends(TagView, _super);

      function TagView() {
        TagView.__super__.constructor.apply(this, arguments);
      }

      TagView.prototype.tagName = 'p';

      TagView.prototype.className = 'tag';

      TagView.prototype.template = Templates.post;

      TagView.prototype.events = function() {};

      TagView.prototype.initialize = function() {
        return this.id = this.model.get('parent');
      };

      TagView.prototype.render = function() {
        var tagdiv;
        tagdiv = $("<div class = 'ui-tag'>" + (this.model.get('title')) + "</div>");
        tagdiv.css('background-image', 'url("/images/tagOutline.png")');
        tagdiv.css('background-repeat', 'no-repeat');
        tagdiv.css('background-size', '100% 100%');
        return $(this.el).append(tagdiv);
      };

      return TagView;

    })(Backbone.View);
    StreamView = (function(_super) {

      __extends(StreamView, _super);

      function StreamView() {
        this.render = __bind(this.render, this);
        this.showTopicCreator = __bind(this.showTopicCreator, this);
        StreamView.__super__.constructor.apply(this, arguments);
      }

      StreamView.prototype.initialize = function() {
        this.streamviewRendered = false;
        this.selectedStory = '#story-part1';
        postCollection.bind('add', this.addOne, this);
        postCollection.bind('reset', this.addAll, this);
        postCollection.bind('all', this.render, this);
        tagCollection.bind('add', this.addTag, this);
        tagCollection.bind('reset', this.addAllTags, this);
        postCollection.fetch();
        return tagCollection.fetch();
      };

      StreamView.prototype.makePost = function(content) {
        var p;
        p = new Post({
          content: content
        });
        return postCollection.create(p);
      };

      StreamView.prototype.addOne = function(item) {
        var post;
        post = new PostView({
          model: item
        });
        if (document.getElementById('response' + item.get('parent'))) {
          return $('#response' + item.get('parent')).prepend(post.render());
        } else {
          return $('#assignments').prepend(post.render());
        }
      };

      StreamView.prototype.addAll = function() {
        return postCollection.each(this.addOne);
      };

      StreamView.prototype.deleteOne = function(item) {
        return item.destroy();
      };

      StreamView.prototype.deleteAll = function() {
        return postCollection.each(this.deleteOne);
      };

      StreamView.prototype.addTag = function(item) {
        var placeholder, tag;
        tag = new TagView({
          model: item
        });
        if (item.get('title') === ',correct') {
          return placeholder = 1;
        } else if (item.get('title') === ',incorrect') {
          return placeholder = 2;
        } else if (document.getElementById('tags' + item.get('parent')) && item.get('title') !== ',assignment') {
          return $('#tags' + item.get('parent')).append(tag.render());
        }
      };

      StreamView.prototype.addAllTags = function() {
        return tagCollection.each(this.addTag);
      };

      StreamView.prototype.showTopicCreator = function(showing) {
        if (showing) {
          return $('#post-question').show();
        } else {
          return $('#post-question').hide();
        }
      };

      StreamView.prototype.render = function() {
        var profileshowing,
          _this = this;
        if (!this.streamviewRendered) {
          $('#post-question').omnipost({
            callback: this.makePost,
            message: 'Post a topic...'
          });
          this.scrollingDiv = $('#story');
          $('#collapsible-profile').hide();
          profileshowing = false;
          $('#dropdown-panel').click(function() {
            profileshowing = !profileshowing;
            return $('#collapsible-profile').slideToggle("fast", (function() {
              return $(window).trigger('scroll');
            }));
          });
          if (postCollection.length === 0) $('#dropdown-panel').click();
          $(document).click(function() {
            return $('#notification-box').hide();
          });
          $('#notification-box').hide();
          $('#notification-counter').click(function() {
            event.stopPropagation();
            return $('#notification-box').toggle();
          });
          $(document).ready(function() {
            return $(window).trigger('scroll');
          });
          if ($('#ui-omniContainer').length !== 0) {
            $('#ui-omniContainer').qtip({
              content: 'Click here first.',
              position: {
                corner: {
                  tooltip: 'leftMiddle',
                  target: 'rightMiddle'
                }
              },
              show: {
                when: false,
                ready: false
              },
              hide: false,
              style: {
                border: {
                  width: 5,
                  radius: 10
                },
                padding: 10,
                textAlign: 'center',
                tip: true,
                'font-size': 16,
                name: 'cream'
              }
            });
          }
          $('.ui-omnipost:first #ui-omniContainer').focusin(function() {
            if (!_this.omniboxTipInvisible) $('#ui-omniContainer').qtip("hide");
            return _this.omniboxTipInvisible = true;
          });
          return this.streamviewRendered = true;
        }
      };

      return StreamView;

    })(Backbone.View);
    /*
      # Routes
    */
    Workspace = (function(_super) {

      __extends(Workspace, _super);

      function Workspace() {
        Workspace.__super__.constructor.apply(this, arguments);
      }

      Workspace.prototype.routes = {
        'new': 'new',
        ':id': 'assign'
      };

      Workspace.prototype.assign = function(id) {
        var p;
        if (id != null) {
          p = new Post({
            'id': id
          });
          return p.fetch({
            success: function() {
              return postCollection.add(p);
            }
          });
        }
      };

      Workspace.prototype["new"] = function() {
        return App.showTopicCreator(true);
      };

      return Workspace;

    })(Backbone.Router);
    postCollection = new Posts();
    tagCollection = new Tags();
    App = new StreamView({
      el: $('#learn')
    });
    app_router = new Workspace();
    return Backbone.history.start();
  });

}).call(this);
