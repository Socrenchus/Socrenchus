(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  $(function() {
    /*
      # Core Models and Logic
    */
    var App, Post, PostView, Posts, StreamView, Tag, Tags, Templates, Workspace, app_router, e, postCollection, tagCollection, _i, _len, _ref;
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

      Post.prototype.initialize = function() {
        return this.clusters = [];
      };

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
        postCollection.fetch();
        return $('#new-assignment').dialog('close');
      };

      Post.prototype.maketag = function(content) {
        var t;
        t = new Tag({
          parent: this.get('id'),
          title: content,
          xp: 0
        });
        tagCollection.create(t);
        return postCollection.fetch();
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
        Tag.__super__.constructor.apply(this, arguments);
      }

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
        this.triggerTagCall = __bind(this.triggerTagCall, this);
        this.renderInnerContents = __bind(this.renderInnerContents, this);
        this.postDOMrender = __bind(this.postDOMrender, this);
        this.renderPostContent = __bind(this.renderPostContent, this);
        this.setSiblingTags = __bind(this.setSiblingTags, this);
        PostView.__super__.constructor.apply(this, arguments);
      }

      PostView.prototype.tagName = 'li';

      PostView.prototype.className = 'post';

      PostView.prototype.template = Templates.post;

      PostView.prototype.tags = [];

      PostView.prototype.vote = null;

      PostView.prototype.events = function() {};

      PostView.prototype.initialize = function() {
        this.id = this.model.id;
        this.model.bind('change', this.render);
        this.model.view = this;
        this.siblingtags = [];
        return this.setSiblingTags();
      };

      PostView.prototype.setSiblingTags = function() {
        var sibling, siblings, tag, taglist, _j, _len2, _results;
        siblings = postCollection.where({
          parent: this.model.get('parent')
        });
        _results = [];
        for (_j = 0, _len2 = siblings.length; _j < _len2; _j++) {
          sibling = siblings[_j];
          taglist = sibling.get('tags');
          if (taglist) {
            _results.push((function() {
              var _k, _len3, _results2;
              _results2 = [];
              for (_k = 0, _len3 = taglist.length; _k < _len3; _k++) {
                tag = taglist[_k];
                if (this.siblingtags.indexOf(tag) < 0) {
                  _results2.push(this.siblingtags.push(tag));
                } else {
                  _results2.push(void 0);
                }
              }
              return _results2;
            }).call(this));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      PostView.prototype.renderPostContent = function() {
        var contentdiv, jsondata;
        jsondata = jQuery.parseJSON(this.model.get('content'));
        contentdiv = $(this.el).find('#content');
        return contentdiv.val(jsondata.posttext);
      };

      PostView.prototype.postDOMrender = function() {
        $(this.el).find('#content').autosize();
        addthis.toolbox('.addthis_toolbox');
        return $('#response > h3').unbind('click').click(function() {
          $(this).next().toggle('slow');
          return false;
        });
      };

      PostView.prototype.renderInnerContents = function() {
        var children, questionURL,
          _this = this;
        this.renderPostContent();
        children = postCollection.where({
          parent: this.id
        });
        if (!(children.length > 0)) {
          $(this.el).find('#replyButton:first').click(function() {
            $(_this.el).find('#replyButton:first').remove();
            return $(_this.el).find('#omnipost:first').omnipost({
              removeOnSubmit: true,
              callback: _this.model.respond
            });
          });
          questionURL = "http://" + window.location.host + "/#" + this.model.get('id');
          $(this.el).find('#addThis').attr('addthis:url', questionURL);
        }
        if (children.length > 0 || App.user['email'] === this.model.get('author')['email']) {
          return $(this.el).find('#replyButton:first').remove();
        }
      };

      PostView.prototype.triggerTagCall = function(tag) {
        if (tag === ",correct" || tag === ",incorrect") {
          return $(this.el).find('#votebox:first').trigger('updateScore', this.model.get('score'));
        }
      };

      PostView.prototype.render = function() {
        var postcontent, t, tag, taglist, tags, vote, _j, _len2, _ref2;
        postcontent = jQuery.parseJSON(this.model.get('content'));
        if (postcontent.posttext !== '') {
          $(this.el).html(this.template);
          $(this.el).find('.inner-question').attr('id', this.model.get('id'));
          this.renderInnerContents();
          tags = tagCollection.where({
            parent: this.model.get('id')
          });
          taglist = [];
          vote = null;
          for (_j = 0, _len2 = tags.length; _j < _len2; _j++) {
            tag = tags[_j];
            t = tag.get('title');
            if (t[0] !== ',') taglist.push(t);
            if (t === ',correct') {
              vote = true;
            } else if (t === ',incorrect') {
              vote = false;
            }
          }
          $(this.el).find('#votebox:first').votebox({
            vote: vote,
            votesnum: (_ref2 = this.model.get('score')) != null ? _ref2 : '',
            callback: this.model.maketag
          });
          $(this.el).find('#tagbox:first').tagbox({
            callback: this.model.maketag,
            tags: taglist,
            similarTagsStringList: this.siblingtags
          });
        }
        return $(this.el);
      };

      PostView.prototype.addChild = function(child, tagsToOrderBy) {
        var base, childtags, indexOfTag, newtagdiv, root, tag, tagdiv, _j, _len2, _results;
        if (tagsToOrderBy == null) tagsToOrderBy = [];
        if ((this.model.depth() % App.maxlevel) === (App.maxlevel - 1)) {
          root = this;
          while (root.parent && (root.model.depth() % App.maxlevel) !== 0) {
            root = root.parent;
          }
          base = $(root.el);
          return base.before(child.render());
        } else {
          base = $(this.el).find('#response:first');
          childtags = child.model.get('tags');
          if (childtags.length === 0) childtags.push('Incubator');
          _results = [];
          for (_j = 0, _len2 = childtags.length; _j < _len2; _j++) {
            tag = childtags[_j];
            tagdiv = base.children("#" + tag.replace(" ", ""));
            if (tagdiv.length === 0) {
              newtagdiv = $("<h3><a href='#'>" + tag + "</h3></a><div id='" + (tag.replace(" ", "")) + "'></div>");
              indexOfTag = tagsToOrderBy.indexOf(tag);
              if (indexOfTag === 0) {
                base.prepend(newtagdiv);
              } else if (indexOfTag > 0) {
                base.children("#" + tagsToOrderBy[indexOfTag - 1].replace(" ", "")).after(newtagdiv);
              } else {
                base.append(newtagdiv);
              }
              tagdiv = base.find("#" + tag.replace(" ", ""));
            }
            _results.push(tagdiv.prepend(child.render()));
          }
          return _results;
        }
      };

      return PostView;

    })(Backbone.View);
    StreamView = (function(_super) {

      __extends(StreamView, _super);

      function StreamView() {
        this.render = __bind(this.render, this);
        this.showTopicCreator = __bind(this.showTopicCreator, this);
        this.setTopicCreatorVisibility = __bind(this.setTopicCreatorVisibility, this);
        this.createModalReply = __bind(this.createModalReply, this);
        this.addOne = __bind(this.addOne, this);
        this.makeView = __bind(this.makeView, this);
        this.reset = __bind(this.reset, this);
        this.initialize = __bind(this.initialize, this);
        StreamView.__super__.constructor.apply(this, arguments);
      }

      StreamView.prototype.initialize = function() {
        this.id = 0;
        this.user = 0;
        this.maxlevel = 4;
        this.streamviewRendered = false;
        this.topic_creator_showing = false;
        this.selectedStory = '#story-part1';
        this.reset();
        postCollection.bind('sync', this.addOne, this);
        postCollection.bind('reset', this.addAll, this);
        postCollection.bind('all', this.render, this);
        tagCollection.fetch();
        return postCollection.fetch();
      };

      StreamView.prototype.reset = function() {
        var _this = this;
        return $.getJSON('/stream', (function(data) {
          _this.id = data['id'];
          _this.user = data['user'];
          tagCollection.add(data['tags']);
          return postCollection.add(data['assignments']);
        }));
      };

      StreamView.prototype.makePost = function(content) {
        var p;
        p = new Post({
          content: content
        });
        postCollection.create(p);
        postCollection.fetch();
        return $('#new-assignment').dialog('close');
      };

      StreamView.prototype.makeView = function(item) {
        var post;
        post = new PostView({
          model: item
        });
        post.parent = postCollection.where({
          id: item.get('parent')
        });
        if (post.parent.length > 0) post.parent[0].clusters = post.siblingtags;
        return post;
      };

      StreamView.prototype.addOne = function(item) {
        var child, children, mychild, post, _j, _k, _len2, _len3;
        post = item.view;
                if (post != null) {
          post;
        } else {
          ({
            post: post = this.makeView(item)
          });
        };
        children = postCollection.where({
          parent: item.get('id')
        });
        if (item.depth() === 0) $('#assignments').prepend(post.render());
        mychild = null;
        for (_j = 0, _len2 = children.length; _j < _len2; _j++) {
          child = children[_j];
          if (this.user['email'] === child.get('author')['email']) mychild = child;
        }
        for (_k = 0, _len3 = children.length; _k < _len3; _k++) {
          child = children[_k];
          if (child.view === void 0) child.view = this.makeView(child);
          if (mychild === void 0 || mychild === null) {
            post.addChild(child.view);
          } else {
            post.addChild(child.view, mychild.get('tags'));
          }
        }
        return post.postDOMrender();
      };

      StreamView.prototype.addAll = function() {
        var a, b;
        b = $('#assignments');
        a = b.clone();
        a.empty();
        b.before(a);
        postCollection.each(this.makeView);
        postCollection.each(this.addOne);
        return b.remove();
      };

      StreamView.prototype.deleteOne = function(item) {
        return item.destroy();
      };

      StreamView.prototype.deleteAll = function() {
        return postCollection.each(this.deleteOne);
      };

      StreamView.prototype.createModalReply = function(titlemessage, omnimessage, callback) {
        var new_assignment;
        new_assignment = $('#new-assignment').dialog({
          title: titlemessage,
          modal: true,
          draggable: false,
          resizable: false,
          minWidth: 320
        });
        return new_assignment.find('#new-post').omnipost({
          removeOnSubmit: true,
          callback: callback,
          message: omnimessage
        });
      };

      StreamView.prototype.setTopicCreatorVisibility = function() {
        if (this.topic_creator_showing) {
          return this.createModalReply("New Topic", "Post a reply...", this.makePost);
        } else {
          return $('#new-assignment').hide();
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
          this.setTopicCreatorVisibility();
          this.notifications = null;
          $.getJSON('/notifications', (function(data) {
            var message, messages, notification, _j, _len2, _ref2;
            _this.notifications = data;
            messages = [];
            _ref2 = _this.notifications;
            for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
              notification = _ref2[_j];
              message = "";
              if (notification['points'] > 0) message = "+";
              if (notification['points'] !== 0) {
                message += "" + notification['points'] + " - ";
              }
              switch (notification['kind']) {
                case 0:
                  message += "You tagged a <a href='#post/" + notification['item'] + "'>post</a>";
                  break;
                case 1:
                  message += "Someone agreed with your tag of this <a href='#post/" + notification['item'] + "'>post</a>";
                  break;
                case 2:
                  message += "Your <a href='#post/" + notification['item'] + "'>post</a> was upvoted";
                  break;
                case 3:
                  message += "Your <a href='#post/" + notification['item'] + "'>post</a> has been replied to";
              }
              message += "\n" + notification['timestamp'];
              messages.push(message);
            }
            return $('#notifications').notify({
              notificationCount: messages.length,
              messages: messages
            });
          }));
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
        ':id': 'assign',
        'post/:id': 'post'
      };

      Workspace.prototype.post = function(id) {
        var p;
        if (id != null) {
          p = postCollection.where({
            id: id
          });
          $('#assignments li').remove();
          if (p.length !== 0) return App.addOne(p[0]);
        }
      };

      Workspace.prototype.assign = function(id) {
        var p;
        if (id != null) {
          p = new Post({
            'id': id
          });
          return p.fetch({
            success: function() {
              var postcontent;
              postcontent = jQuery.parseJSON(p.get('content'))['posttext'];
              return App.createModalReply(postcontent, "Post a reply...", p.respond);
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
      el: $('#stream')
    });
    app_router = new Workspace();
    return Backbone.history.start();
  });

}).call(this);
