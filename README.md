**  
 

**  
 

**  
   
**Socrenchus  
**   
_motivating the world's information

_

* * *

_

 

_

   
  
Summary

High Level Design

Users

Questions

Topic Tags

Answers

Vote Box

Rubric Tags

Positive and Negative

Score

Grade

Followups

Topic Tags

Moderation

Hierarchy

Classes

Other Media

User Interface

Stream

Posts

Replies

Filters

Profile

Skill Map

Course Work

Badges

Server

Persistent Storage

Inference

Workflow

Github

Code Review

Coding Style

CoffeeScript

Python

Linters

Testing

  
#

# Summary

  
Socrenchus is reinventing education with technologies that have totally
transformed many other parts of our lives. By putting a fun and intuitive
platform between the student and teacher, Socrenchus will be able to collect
enough data to optimize away every last frustration. Things like manual
grading, being bored with the same material a hundred times and being afraid
to ask for fear of sounding stupid will immediately become a thing of the
past. When teachers and students are able to pry themselves away from the most
enjoyable learning experience yet, they will have more time to focus on what's
important.

  
# High Level Design

  
The top level component of Socrenchus is the stream. The stream is where all
Socrenchus content flows and can be filter to focus on certain topics or
classes.

  
## Users

  
Just like in the real world, a user is both a student and a teacher. Users can
follow other users, topic tags, or classes.

  
## Questions

  
Questions are the smallest unit of coherent information that Socrenchus has to
offer. Akin to a status update on Facebook, the question, most often posed by
the teacher, is the basic unit of learning via the Socratic method.

  
### Topic Tags

  
See Topic Tags section below.

  
### Answers

  
Answers provide the interaction for students and are essential for to
providing assessment and direction to the students. Once a student answers a
question, they are given other student's questions to make sense of.

  
#### Vote Box

  
A vote box allows a student to mark an answer as correct or incorrect.
Socrenchus uses the vote combined with the user's experience in the topics to
adjust the score of the associated rubric tags.

  
#### Rubric Tags

  
Rubric tags allow thousands of answers to be grouped into basic categories
that will help Socrenchus decide what to ask the student next. Students chose
from a list of tags, with the option to create their own. Like in any good
game, the student who went with the most popular tags gets the most points.

  
##### Positive and Negative

  
Rubric tags come in two flavors, the red '-' tag, which means that the tag is
pointing out something wrong with the answer, and the green '+' tag, which
points out something good about the answer.

  
##### Score

  
Determined by votes on associated answers' correctness, the score is used to
grade the answer..

  
#### Grade

  
Answers are graded by taking each rubric tag's score and weighting it with how
many people thought that tag applied.

  
### Followups

  
Followup questions can be attached to existing questions, and optionally a
specific rubric tag (or set of rubric tags). When a student answers a question
in a certain way, the choice of what question to answer next is tailored
specifically to them.

  
## Topic Tags

  
A question can be tagged with any number of topics, in a detailed view of
points earned in Socrenchus, people can see which topics their points are in.
People can also follow topics and see new questions on the topic in their
stream.

  
### Moderation

  
As you gain a reputation in a certain topic, you get more moderation powers
(like Stack Overflow). People who are more invested in the platform and a
specific topic, are less likely to pollute it.

  
### Hierarchy

  
Topic tags are hierarchical with multiple inheritance. This means you can tag
a topic tag with other topic tags. This most closely models the actual state
of academia, things are never as clean cut as we like to think they are.

  
## Classes

  
A class can be set up by anyone the way you would set up a facebook page. When
a class is set up and students are subscribed, the teacher will be able to
assign and grade to the class.

  
## Other Media

  
Any kind of multi-media can be posted to a topic, specifically lecture videos.
While there are no immediate plans to host rich media content, embedded
content from other sites will become an integral part of the learning
experience as-well.

  
# User Interface

  
The Socrenchus user interface is first and foremost clean. If you think back
to the real reason Google was so successful, it is because it was the only
search engine to give clean results. Besides that it needs to be simple, there
should never be too many things up on the screen at once, the user should
always have a couple specific things they should be focused on. The
implementation currently makes use of CoffeeScript, jQuery, and Backbone.js.

  
## Stream

  
The stream is a common concept used in Facebook, Twitter, and Google+. It is
the one page that animates the constant flow of information.

  
### Posts

  
Like much of the Socrenchus UI, posts are nothing new. The only deviation from
a regular social network that Socrenchus posts make, is that they allow you to
post questions.

  
#### Replies

  
Posts are reply-able but replies and comments are only displayed after the
user engages a post. With a question, answering constitutes engagement, with
something like a video, it might be viewing, or even just clicking.

  
### Filters

  
The stream should be filterable by many things, but at the very least it
should filter by topic tag.

  
## Profile

  
In a world where Socrenchus has entirely overtaken the education market, the
profile might be used in place of a resume. There is no need to ask the user
about themselves though because their behaviors on the platform will tell
their stories.

  
### Skill Map

  
The skill map is a Google Maps API view of your experience by topic tags.

  
### Course Work

  
The course work section will have visualizations of ongoing classes, along
with summaries of completed classes.

  
### Badges

  
Badges are a fun way to spice things up. They are meant to surprise people by
patting them on the back for something they didn't realize was worth one.

  
# Server

  
The server is responsible for persistent storage and inference. Right now it
is written using Python App Engine's new database (NDB).

  
## Persistent Storage

  
Persistent storage is easy, just validate incoming models and dump them in the
database.

  
## Inference

  
Inference is done on various levels across the Socrenchus, it would be nice to
eventually build some kind of generic inference engine, but for now we can do
everything the same way as experiment 1.

  
# Workflow

  
The goal of our work flow is to make working in a team with the tools at hand
as effective as possible.

  
## Github

  
The github workflow is simple and effective, just fork the repository, make
changes, then click pull request.

  
### Code Review

  
Every change must be reviewed (and ok'd [LGTM]) by at least one other person
before being accepted upstream. Github provides tools to make this easy.

  
## Coding Style

  
Coding style is not optional, linters will be used, commits that fail the lint
will not be accepted upstream.

  
### CoffeeScript

  
CoffeeScript style guide can be found [here](https://github.com/Socrenchus
/coffeescript-style-guide).

  
### Python

  
Socrenchus does not yet have its own style guide for Python, for now just use
[Google's guidelines](http://google-
styleguide.googlecode.com/svn/trunk/pyguide.html) with two spaces for code
blocks instead of four.

  
### Linters

  
Don't have them yet, but we will.

  
## Testing

  
Every commit should have a test associated with it. If time is of the essence,
testing can be put off to a more suitable point in the development cycle.

_Socrenchus Confidential ~ _

