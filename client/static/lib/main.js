(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  $(function() {
    /*
      # Core Model and Logic
    */
    var App, Post, PostView, Posts, StreamView, Templates, Workspace, app_router, e, postCollection, _i, _len, _ref;
    Post = (function(_super) {

      __extends(Post, _super);

      function Post() {
        this.respond = __bind(this.respond, this);
        Post.__super__.constructor.apply(this, arguments);
      }

      Post.prototype.respond = function(content) {
        var p, responseArray;
        p = new Post({
          parentID: this.id,
          id: '' + this.id + this.get('responses').length,
          editing: false,
          content: content,
          votecount: 0,
          tags: ["kaiji", "san"],
          parents: [this.id],
          responses: []
        });
        responseArray = this.get('responses');
        responseArray.push(p.get('id'));
        this.save({
          responses: responseArray
        });
        return postCollection.create(p);
      };

      return Post;

    })(Backbone.Model);
    Posts = (function(_super) {

      __extends(Posts, _super);

      function Posts() {
        Posts.__super__.constructor.apply(this, arguments);
      }

      Posts.prototype.model = Post;

      Posts.prototype.localStorage = new Store('posts');

      return Posts;

    })(Backbone.Collection);
    /*
      # View
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
        PostView.__super__.constructor.apply(this, arguments);
      }

      PostView.prototype.tagName = 'li';

      PostView.prototype.className = 'post';

      PostView.prototype.template = Templates.post;

      PostView.prototype.events = function() {};

      PostView.prototype.initialize = function() {
        return this.id = this.model.id;
      };

      PostView.prototype.renderPostContent = function() {
        var postcontentdiv;
        postcontentdiv = $("<div class = 'ui-postcontent'></div>");
        postcontentdiv.append($(this.model.get('content').linkdata));
        postcontentdiv.append('<br />');
        postcontentdiv.append(this.model.get('content').posttext);
        return $(this.el).find('.inner-question').append(postcontentdiv);
      };

      PostView.prototype.render = function() {
        var indicatortext, lockedpostsdiv, percent, progressbardiv, progressindicatordiv, responsediv, textinline;
        $(this.el).html(this.template);
        $(this.el).find('.inner-question').votebox({
          votesnum: this.model.get('votecount')
        });
        this.renderPostContent();
        $(this.el).find('.inner-question').tagbox({
          editing: true,
          tags: this.model.get('tags')
        });
        $(this.el).find('.inner-question').omnipost({
          callback: this.model.respond,
          editing: true
        });
        responsediv = $("<div id = 'response" + this.id + "'></div>");
        $(this.el).find('.inner-question').append(responsediv);
        if (this.model.get('parents').length === 0) {
          lockedpostsdiv = $("<div class='locked-posts'></div>");
          progressbardiv = $("<div class='progressbar'></div>");
          percent = Math.floor(Math.random() * 100);
          textinline = true;
          indicatortext = $('<p>Unlock ' + Math.floor(2 + Math.random() * 7) + ' posts</p>');
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
          $(this.el).find('.inner-question').append(lockedpostsdiv);
        }
        return $(this.el);
      };

      return PostView;

    })(Backbone.View);
    StreamView = (function(_super) {

      __extends(StreamView, _super);

      function StreamView() {
        this.render = __bind(this.render, this);
        StreamView.__super__.constructor.apply(this, arguments);
      }

      StreamView.prototype.initialize = function() {
        this.streamviewRendered = false;
        postCollection.bind('add', this.addOne, this);
        postCollection.bind('reset', this.addAll, this);
        postCollection.bind('all', this.render, this);
        return postCollection.fetch();
      };

      StreamView.prototype.addOne = function(item) {
        var post;
        post = new PostView({
          model: item
        });
        if (document.getElementById('response' + item.get('parentID'))) {
          return $('#response' + item.get('parentID')).prepend(post.render());
        } else {
          return $('#assignments').append(post.render());
        }
      };

      StreamView.prototype.addAll = function() {
        return postCollection.each(this.addOne);
      };

      StreamView.prototype.deleteOne = function(item) {
        return item.destroy();
      };

      StreamView.prototype.deleteAll = function() {
        postCollection.fetch();
        return postCollection.each(this.deleteOne);
      };

      StreamView.prototype.render = function() {
        var profileshowing,
          _this = this;
        if (!this.streamviewRendered) {
          $('#collapseable-profile').hide();
          profileshowing = false;
          $('#dropdown-panel').click(function() {
            profileshowing = !profileshowing;
            return $('#collapseable-profile').slideToggle("fast", (function() {
              $(window).trigger('scroll');
              if (profileshowing) {
                return $('#dropdown-panel').attr('src', '/images/dropdownreversed.png');
              } else {
                return $('#dropdown-panel').attr('src', '/images/dropdown.png');
              }
            }));
          });
          $('#notification-box').hide();
          $('#notification-counter').click(function() {
            return $('#notification-box').toggle();
          });
          $(document).ready(function() {
            return $(window).trigger('scroll');
          });
          $('#notification-counter').click(function() {
            if (!_this.notificationTipInvisible) $('#dropdown-panel').qtip("show");
            $('#notification-counter').qtip("hide");
            return _this.notificationTipInvisible = true;
          });
          $('#notification-counter').qtip({
            content: 'Unviewed Notifications.  Click on it to reveal the notifications.',
            position: {
              corner: {
                tooltip: 'leftMiddle',
                target: 'rightMiddle'
              }
            },
            show: {
              when: false,
              ready: true
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
          $('#dropdown-panel').click(function() {
            if (!_this.dropdownTipInvisible) $('.ui-votebox:first').qtip("show");
            $('#dropdown-panel').qtip("hide");
            return _this.dropdownTipInvisible = true;
          });
          $('#dropdown-panel').qtip({
            content: 'Click to view your profile.',
            position: {
              corner: {
                tooltip: 'topLeft',
                target: 'bottomRight'
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
          $('.ui-votebox').click(function() {
            if (!_this.voteboxTipInvisible) $('.ui-tagbox:first').qtip("show");
            $('.ui-votebox:first').qtip("hide");
            return _this.voteboxTipInvisible = true;
          });
          $('.ui-votebox #ui-upvote').click(function() {
            if (!_this.voteboxTipInvisible) $('.ui-tagbox:first').qtip("show");
            $('.ui-votebox:first').qtip("hide");
            return _this.voteboxTipInvisible = true;
          });
          $('.ui-votebox #ui-downvote').click(function() {
            if (!_this.voteboxTipInvisible) $('.ui-tagbox:first').qtip("show");
            $('.ui-votebox:first').qtip("hide");
            return _this.voteboxTipInvisible = true;
          });
          $('.ui-votebox:first').qtip({
            content: 'Click up or down to set the score of a post.',
            position: {
              corner: {
                tooltip: 'rightMiddle',
                target: 'leftMiddle'
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
          $('.ui-tagbox:first').keydown(function() {
            if (event.keyCode === 188 || event.keyCode === 13) {
              if (!_this.tagboxTip2Invisible) $('#ui-omniContainer').qtip("show");
              $('.ui-tagbox:first').qtip("hide");
              return _this.tagboxTip2Invisible = true;
            }
          });
          $('.ui-tagbox:first').click(function() {
            if (!_this.tagboxTipInvisible) {
              $('.ui-tagbox:first').qtip('api').updateContent('Tags can be multiple words, and are seperated by pressing enter or the comma key.');
            }
            return _this.tagboxTipInvisible = true;
          });
          $('.ui-tagbox:first').qtip({
            content: 'You can tag a post with a list of topics.',
            position: {
              corner: {
                tooltip: 'rightMiddle',
                target: 'leftMiddle'
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
          $('.ui-omnipost:first').click(function() {
            return $('#ui-omniContainer').qtip("hide");
          });
          $('#ui-omniContainer').qtip({
            content: 'Make a post.  Text, images, and links are already included, and video posting will be included shortly.',
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
        '/:id': 'assign',
        'unpopulate': 'unpopulate',
        'populate': 'populate'
      };

      Workspace.prototype.assign = function(id) {
        postCollection.get(id);
        return postCollection.fetch();
      };

      Workspace.prototype.unpopulate = function() {
        return App.deleteAll();
      };

      Workspace.prototype.populate = function() {
        var data, p, p1;
        data = {
          posttext: 'This is an example post.',
          linkdata: '<img src = "http://m-27.com/wp-content/lol/kaiji.jpg" width = "350" height = "auto">'
        };
        p = new Post({
          id: 1,
          editing: false,
          content: data,
          votecount: 25,
          tags: ["kaiji", "san"],
          parents: '',
          responses: []
        });
        postCollection.create(p);
        data = {
          posttext: 'This is an example post.',
          linkdata: '<a href = "http://www.imdb.com">www.imdb.com</a>'
        };
        p1 = new Post({
          id: 2,
          editing: false,
          content: data,
          tags: ["do", "re", "mi", "fa", "so"],
          parents: '',
          responses: []
        });
        return postCollection.create(p1);
      };

      return Workspace;

    })(Backbone.Router);
    postCollection = new Posts();
    App = new StreamView({
      el: $('#learn')
    });
    app_router = new Workspace();
    return Backbone.history.start();
  });

}).call(this);
