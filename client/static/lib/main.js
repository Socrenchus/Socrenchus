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
        this.depth = __bind(this.depth, this);
        this.initialize = __bind(this.initialize, this);
        Post.__super__.constructor.apply(this, arguments);
      }

      Post.prototype.urlRoot = '/posts';

      Post.prototype.initialize = function() {};

      Post.prototype.depth = function() {
        return this.get('depth') - 1;
      };

      Post.prototype.respond = function(content) {
        var p;
        p = new Post({
          parent: this.get('id'),
          content: content
        });
        postCollection.create(p);
        return postCollection.fetch();
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
        this.addChild = __bind(this.addChild, this);
        this.render = __bind(this.render, this);
        this.renderLineToParent = __bind(this.renderLineToParent, this);
        this.renderInnerContents = __bind(this.renderInnerContents, this);
        this.postDOMrender = __bind(this.postDOMrender, this);
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
        return this.model.view = this;
      };

      PostView.prototype.renderPostContent = function() {
        var contentdiv, jsondata;
        jsondata = jQuery.parseJSON(this.model.get('content'));
        contentdiv = $(this.el).find('#content');
        return contentdiv.val(jsondata.posttext);
      };

      PostView.prototype.postDOMrender = function() {
        if (postCollection.where({
          parent: this.id
        }).length > 0) {
          if ($('#' + this.model.get('id')).find('.locked-posts').length === 0) {
            $(this.el).find('#progress-bar').progressbar({
              value: this.model.get('progress')
            });
          }
        }
        return $(this.el).find('#content').autosize();
      };

      PostView.prototype.renderInnerContents = function() {
        $(this.el).find('.inner-question').find('#votebox').votebox({
          votesnum: this.model.get('score'),
          callback: this.model.maketag
        });
        this.renderPostContent();
        $(this.el).find('.inner-question').find('#tagbox').tagbox({
          callback: this.model.maketag
        });
        if (!(postCollection.where({
          parent: this.id
        }).length > 0)) {
          return $(this.el).find('.inner-question').find('#omnipost').omnipost({
            removeOnSubmit: true,
            callback: this.model.respond
          });
        }
      };

      PostView.prototype.renderLineToParent = function() {
        var linediv, x1, x2, y1, y2;
        if ($('#line' + this.model.get('id')).length === 0) {
          x1 = $('#' + this.model.get('id')).offset().left;
          y1 = $('#' + this.model.get('id')).offset().top;
          x2 = $('#' + this.model.get('parent')).offset().left + $('#' + this.model.get('parent')).width();
          y2 = $('#' + this.model.get('parent')).offset().top + $('#' + this.model.get('parent')).height();
          linediv = $("<img id ='line" + (this.model.get("id")) + "' src='/images/diagonalLine.png'></img>");
          linediv.css("position", "absolute");
          linediv.css("left", x1);
          linediv.css("top", y1);
          linediv.css("width", x2 - x1);
          linediv.css("height", y2 - y1);
          linediv.css("z-index", 0);
          return $('body').append(linediv);
        }
      };

      PostView.prototype.render = function() {
        $(this.el).html(this.template);
        $(this.el).find('.inner-question').attr('id', this.model.get('id'));
        this.renderInnerContents();
        return $(this.el);
      };

      PostView.prototype.addChild = function(child) {
        var base, root;
        if ((this.model.depth() % App.maxlevel) === (App.maxlevel - 1)) {
          root = this;
          while ((root.model.depth() % App.maxlevel) !== 0) {
            root = root.parent;
          }
          base = $(root.el);
          base.before(child.render());
          $(parent.el).addClass('parent');
          return $(child.el).addClass('reply');
        } else {
          base = $(this.el).find('#response:first');
          return base.prepend(child.render());
        }
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
        this.setTopicCreatorVisibility = __bind(this.setTopicCreatorVisibility, this);
        this.setview = __bind(this.setview, this);
        this.addOne = __bind(this.addOne, this);
        this.reset = __bind(this.reset, this);
        StreamView.__super__.constructor.apply(this, arguments);
      }

      StreamView.prototype.initialize = function() {
        this.id = 0;
        this.maxlevel = 4;
        this.streamviewRendered = false;
        this.topic_creator_showing = false;
        this.selectedStory = '#story-part1';
        postCollection.bind('add', this.addOne, this);
        postCollection.bind('reset', this.addAll, this);
        postCollection.bind('all', this.render, this);
        tagCollection.bind('add', this.addTag, this);
        this.reset();
        return tagCollection.bind('reset', this.addAllTags, this);
      };

      StreamView.prototype.reset = function() {
        return $.getJSON('/stream', (function(data) {
          this.id = data['id'];
          postCollection.add(data['assignments']);
          return tagCollection.add(data['tags']);
        }));
      };

      StreamView.prototype.makePost = function(content) {
        var p;
        p = new Post({
          content: content
        });
        postCollection.create(p);
        return postCollection.fetch();
      };

      StreamView.prototype.addOne = function(item) {
        var post;
        post = null;
        if (!item.view) {
          post = new PostView({
            model: item
          });
        } else {
          post = item.view;
        }
        if (!document.getElementById(item.get('id'))) {
          post.parent = postCollection.where({
            id: item.get('parent')
          });
          if (post.parent.length > 0) {
            post.parent = post.parent[0].view;
            post.parent.addChild(post);
          } else {
            $('#assignments').prepend(post.render());
          }
          return post.postDOMrender();
        }
      };

      StreamView.prototype.setview = function(item) {
        var post;
        return post = new PostView({
          model: item
        });
      };

      StreamView.prototype.addAll = function() {
        postCollection.each(this.setview);
        return postCollection.each(this.addOne);
      };

      StreamView.prototype.deleteOne = function(item) {
        return item.destroy();
      };

      StreamView.prototype.deleteAll = function() {
        return postCollection.each(this.deleteOne);
      };

      StreamView.prototype.addTag = function(item) {
        var tag;
        return tag = new TagView({
          model: item
        });
      };

      StreamView.prototype.addAllTags = function() {
        return tagCollection.each(this.addTag);
      };

      StreamView.prototype.setTopicCreatorVisibility = function() {
        if (this.topic_creator_showing) {
          return $('#post-question').show();
        } else {
          return $('#post-question').hide();
        }
      };

      StreamView.prototype.showTopicCreator = function(showing) {
        this.topic_creator_showing = showing;
        return this.setTopicCreatorVisibility();
      };

      StreamView.prototype.render = function() {
        var profileshowing,
          _this = this;
        if (!this.streamviewRendered) {
          $('#post-question').omnipost({
            callback: this.makePost,
            message: 'Post a topic...'
          });
          this.setTopicCreatorVisibility();
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
