(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  $(function() {
    /*
      # Core Model and Logic
    */
    var App, Post, PostView, Posts, StreamView, Templates, Workspace, app_router, e, postCollection, _i, _len, _ref;
    Post = (function(_super) {

      __extends(Post, _super);

      function Post() {
        Post.__super__.constructor.apply(this, arguments);
      }

      Post.prototype.respond = function(response) {
        var p;
        p = new Post({
          value: response
        });
        return this.save({
          responses: this.get('responses').push(p.cid)
        });
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

      PostView.prototype.events = function() {
        return {
          'click button#reply': 'replyToPost'
        };
      };

      PostView.prototype.initialize = function() {
        return this.id = this.model.id;
      };

      PostView.prototype.render = function() {
        $(this.el).html(this.template);
        $(this.el).find('.inner-question').votebox({
          votesnum: this.model.get('votecount')
        });
        $(this.el).find('.inner-question').omnipost({
          editing: this.model.get('editing'),
          postcontent: this.model.get('content'),
          linkedcontent: this.model.get('linkedcontent')
        });
        $(this.el).find('.inner-question').tagbox({
          editing: this.model.get('editing'),
          tags: this.model.get('tags')
        });
        $(this.el).append("<button id='reply'>Reply</button>");
        return $(this.el);
      };

      PostView.prototype.replyToPost = function() {
        var replyPost, replyView;
        replyPost = new Post({
          editing: true,
          content: '',
          linkedcontent: '',
          votecount: 0,
          tags: [],
          parents: this.model,
          responses: ''
        });
        replyView = new PostView({
          model: replyPost
        });
        return $(this.el).append(replyView.render());
      };

      return PostView;

    })(Backbone.View);
    StreamView = (function(_super) {

      __extends(StreamView, _super);

      function StreamView() {
        StreamView.__super__.constructor.apply(this, arguments);
      }

      StreamView.prototype.initialize = function() {
        postCollection.bind('add', this.addOne, this);
        postCollection.bind('reset', this.addAll, this);
        return postCollection.fetch();
      };

      StreamView.prototype.addOne = function(item) {
        var post;
        post = new PostView({
          model: item
        });
        return $(post.render()).appendTo();
      };

      StreamView.prototype.addAll = function() {
        return postCollection.each(this.addOne);
      };

      return StreamView;

    })(Backbone.View);
    postCollection = new Posts();
    App = new StreamView({
      el: $('#learn')
    });
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
        'mockup': 'mockup'
      };

      Workspace.prototype.assign = function(id) {
        postCollection.get(id);
        return postCollection.fetch();
      };

      Workspace.prototype.mockup = function() {
        var p, p1, pv, pv1;
        p = new Post({
          editing: false,
          content: 'This is an example post.',
          linkedcontent: '<img src="http://m-27.com/wp-content/lol/kaiji.jpg" alt=""/>',
          votecount: 25,
          tags: ["kaiji", "san"],
          parents: '',
          responses: ''
        });
        pv = new PostView({
          model: p
        });
        $('#assignments').append(pv.render());
        p1 = new Post({
          editing: false,
          content: 'This is an example post.',
          linkedcontent: '<img src="http://m-27.com/wp-content/lol/kaiji.jpg" alt=""/>',
          tags: ["do", "re", "mi", "fa", "so"],
          parents: '',
          responses: ''
        });
        pv1 = new PostView({
          model: p1
        });
        return $('#assignments').append(pv1.render());
      };

      return Workspace;

    })(Backbone.Router);
    app_router = new Workspace();
    return Backbone.history.start();
  });

}).call(this);
