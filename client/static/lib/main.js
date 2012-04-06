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
          responses: [],
          hidden: false
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
        if (!this.model.get('hidden')) {
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
        }
        return $(this.el);
      };

      return PostView;

    })(Backbone.View);
    StreamView = (function(_super) {

      __extends(StreamView, _super);

      function StreamView() {
        this.render = __bind(this.render, this);
        this.storyPart4Done = __bind(this.storyPart4Done, this);
        this.storyPart3Done = __bind(this.storyPart3Done, this);
        this.storyPart2Done = __bind(this.storyPart2Done, this);
        StreamView.__super__.constructor.apply(this, arguments);
      }

      StreamView.prototype.initialize = function() {
        this.streamviewRendered = false;
        this.selectedStory = '#story-part1';
        postCollection.bind('add', this.addOne, this);
        postCollection.bind('reset', this.addAll, this);
        postCollection.fetch();
        return this.render();
      };

      StreamView.prototype.setStoryPart = function(storyPart) {
        $(this.selectedStory).css('border-style', 'none');
        $(this.selectedStory).css('background', 'none');
        this.selectedStory = storyPart;
        $(this.selectedStory).css('border', '2px solid blue');
        $(this.selectedStory).css('background', '#9999FF');
        $(this.selectedStory).css('-webkit-border-radius', '8px');
        $(this.selectedStory).css(' -moz-border-radius', '8px');
        return $(this.selectedStory).css('border-radius', '8px');
      };

      StreamView.prototype.storyPart2Done = function() {
        var post, pv,
          _this = this;
        this.setStoryPart('#story-part3');
        $('.ui-omnipost:first #ui-omniPostSubmit').click();
        post = postCollection.get(2);
        post.set("hidden", false);
        pv = new PostView({
          model: post
        });
        $('.post:first #response1').append(pv.render());
        $('.post:first #response1 .ui-tagbox:eq(1)').qtip({
          content: 'Click here next.',
          position: {
            corner: {
              tooltip: 'rightMiddle',
              target: 'leftMiddle'
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
        return $('.post:first #response1 .ui-tagbox:eq(1)').click(function() {
          $('.post:first #response1 .ui-tagbox:eq(1) .ui-individualtag:first').text('Reggies candy bar ');
          return $('.post:first #response1 .ui-tagbox:eq(1) .ui-individualtag:first').typewriter(_this.storyPart3Done);
        });
      };

      StreamView.prototype.storyPart3Done = function() {
        var _this = this;
        this.setStoryPart('#story-part4');
        e = jQuery.Event('keydown');
        e.keyCode = 13;
        $('.post:first #response1 .ui-tagbox:eq(1) .ui-tagtext').trigger(e);
        $('.post:first #response1 .ui-tagbox:eq(1)').qtip("hide");
        $('.post:first #response1 .ui-omnipost:eq(1)').qtip({
          content: 'Now click here',
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
        return $('.post:first #response1 .ui-omnipost:eq(1)').focusin(function() {
          event.stopPropagation();
          $('.post:first #response1 .ui-omnipost:eq(1) #ui-omniPostVideoAttach').click();
          $('.post:first #response1 .ui-omnipost:eq(1) .ui-videobox .ui-omniPostLink').val('http://www.youtube.com/watch?v=2F_PxO1QJ1c');
          return $('.post:first #response1 .ui-omnipost:eq(1) .ui-videobox .ui-omniPostLink').textareatypewriter(_this.storyPart4Done);
        });
      };

      StreamView.prototype.storyPart4Done = function() {
        var i, post, pv, _j, _len2, _ref2,
          _this = this;
        this.setStoryPart('#story-part5');
        _ref2 = [3, 4];
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          i = _ref2[_j];
          post = postCollection.get(i);
          post.set("hidden", false);
          pv = new PostView({
            model: post
          });
          $('.post:first #response1 #response2').append(pv.render());
        }
        $('.post:first #response1 .ui-omnipost:eq(1)').remove();
        $('#notification-counter').qtip({
          content: 'Now click here',
          position: {
            corner: {
              tooltip: 'rightMiddle',
              target: 'leftMiddle'
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
        return $('#notification-counter').click(function() {
          return $('#notification-counter').qtip("hide");
        });
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
        return postCollection.each(this.deleteOne);
      };

      StreamView.prototype.render = function() {
        var profileshowing,
          _this = this;
        if (!this.streamviewRendered) {
          $('#collapsible-profile').hide();
          profileshowing = false;
          $('#dropdown-panel').click(function() {
            profileshowing = !profileshowing;
            return $('#collapsible-profile').slideToggle("fast", (function() {
              return $(window).trigger('scroll');
            }));
          });
          if (postCollection.length === 0) $('#dropdown-panel').click();
          $('#notification-box').hide();
          $('#notification-counter').click(function() {
            return $('#notification-box').toggle();
          });
          $(document).ready(function() {
            return $(window).trigger('scroll');
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
          $('#ui-omniContainer').qtip("show");
          $('.ui-omnipost:first').click(function() {
            if (!_this.omniboxTipInvisible) {
              $('#ui-omniContainer').qtip("hide");
              _this.setStoryPart('#story-part2');
              $('.ui-omnipost:first #ui-omniPostText').val('I remember my mother cooking breakfast while my sister, my father, and I listened to the radio as FDR began another one of his fireside chats. It was september of 1939 and the topic was the European War.');
              $('.ui-omnipost:first #ui-omniPostText').textareatypewriter(_this.storyPart2Done);
            }
            return _this.omniboxTipInvisible = true;
          });
          $(document).click(function() {});
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

      Workspace.prototype.deleteOne = function(item) {
        return item.destroy();
      };

      Workspace.prototype.unpopulate = function() {
        postCollection.fetch();
        return postCollection.each(this.deleteOne);
      };

      Workspace.prototype.populate = function() {
        var data, data1, data2, data3, p, p1, p2, p3;
        data = {
          posttext: 'What is your earliest memory of WWII?',
          linkdata: '<img src = "http://www.historyplace.com/unitedstates/pacificwar/2156.jpg" width = "350" height = "auto">'
        };
        p = new Post({
          id: 1,
          editing: false,
          content: data,
          votecount: 25,
          tags: ["world war II"],
          parents: '',
          responses: [],
          hidden: false
        });
        postCollection.create(p);
        data1 = {
          posttext: 'Does anyone remember these delicious candybars?',
          linkdata: '<iframe width="350" height="275" src="http://www.youtube.com/embed/PjcDkdfe6tg" frameborder="0" allowfullscreen></iframe>'
        };
        p1 = new Post({
          id: 2,
          editing: false,
          content: data1,
          votecount: 13,
          tags: ["Reggies candy bar"],
          parents: [p],
          responses: [],
          hidden: true
        });
        postCollection.create(p1);
        data2 = {
          posttext: '',
          linkdata: '<iframe width="350" height="275" src="http://www.youtube.com/embed/2F_PxO1QJ1c" frameborder="0" allowfullscreen></iframe>'
        };
        p2 = new Post({
          id: 3,
          editing: false,
          content: data2,
          votecount: 4,
          tags: ["Reggies candy bar, World war II"],
          parents: [p1],
          responses: [],
          hidden: true
        });
        postCollection.create(p2);
        data3 = {
          posttext: 'Wow, I completely forgot about this candy.  Its part of a candy wrapper museum now.',
          linkdata: '<a href="http://www.candywrappermuseum.com/reggiejackson.html">Candy Bar Museum</a>'
        };
        p3 = new Post({
          id: 4,
          editing: false,
          content: data3,
          votecount: 3,
          tags: ["Reggies candy bar, World war II"],
          parents: [p1],
          responses: [],
          hidden: true
        });
        return postCollection.create(p3);
      };

      return Workspace;

    })(Backbone.Router);
    postCollection = new Posts();
    app_router = new Workspace();
    Backbone.history.start();
    return App = new StreamView({
      el: $('#learn')
    });
  });

}).call(this);
