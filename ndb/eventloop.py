"""An event loop.

This event loop should handle both asynchronous App Engine RPC objects
(specifically urlfetch, memcache and datastore RPC objects) and arbitrary
callback functions with an optional time delay.

Normally, event loops are singleton objects, though there is no
enforcement of this requirement.

The API here is inspired by Monocle.
"""

import collections
import logging
import os
import time

from google.appengine.api.apiproxy_rpc import RPC
from google.appengine.datastore import datastore_rpc

from . import utils

logging_debug = utils.logging_debug

IDLE = RPC.IDLE
RUNNING = RPC.RUNNING
FINISHING = RPC.FINISHING


class EventLoop(object):
  """An event loop."""

  def __init__(self):
    """Constructor."""
    self.current = collections.deque()  # FIFO list of (callback, args, kwds)
    self.idlers = collections.deque()  # Cyclic list of (callback, args, kwds)
    self.inactive = 0  # How many idlers in a row were no-ops
    self.queue = []  # Sorted list of (time, callback, args, kwds)
    self.rpcs = {}  # Map of rpc -> (callback, args, kwds)

  def insort_event_right(self, event, lo=0, hi=None):
    """Insert event in queue, and keep it sorted assuming queue is sorted.

    If event is already in queue, insert it to the right of the rightmost
    event (to keep FIFO order).

    Optional args lo (default 0) and hi (default len(a)) bound the
    slice of a to be searched.
    """

    if lo < 0:
        raise ValueError('lo must be non-negative')
    if hi is None:
        hi = len(self.queue)
    while lo < hi:
        mid = (lo + hi) // 2
        if event[0] < self.queue[mid][0]: hi = mid
        else: lo = mid + 1
    self.queue.insert(lo, event)

  # TODO: Rename to queue_callback?
  def queue_call(self, delay, callback, *args, **kwds):
    """Schedule a function call at a specific time in the future."""
    if delay is None:
      self.current.append((callback, args, kwds))
      return
    if delay < 1e9:
      when = delay + time.time()
    else:
      # Times over a billion seconds are assumed to be absolute.
      when = delay
    self.insort_event_right((when, callback, args, kwds))

  def queue_rpc(self, rpc, callback=None, *args, **kwds):
    """Schedule an RPC with an optional callback.

    The caller must have previously sent the call to the service.
    The optional callback is called with the remaining arguments.

    NOTE: If the rpc is a MultiRpc, the callback will be called once
    for each sub-RPC.  TODO: Is this a good idea?
    """
    if rpc is None:
      return
    if rpc.state not in (RUNNING, FINISHING):
      raise RuntimeError('rpc must be sent to service before queueing')
    if isinstance(rpc, datastore_rpc.MultiRpc):
      rpcs = rpc.rpcs
      if len(rpcs) > 1:
        # Don't call the callback until all sub-rpcs have completed.
        rpc.__done = False
        def help_multi_rpc_along(r=rpc, c=callback, a=args, k=kwds):
          if r.state == FINISHING and not r.__done:
            r.__done = True
            c(*a, **k)
            # TODO: And again, what about exceptions?
        callback = help_multi_rpc_along
        args = ()
        kwds = {}
    else:
      rpcs = [rpc]
    for rpc in rpcs:
      self.rpcs[rpc] = (callback, args, kwds)

  def add_idle(self, callback, *args, **kwds):
    """Add an idle callback.

    An idle callback can return True, False or None.  These mean:

    - None: remove the callback (don't reschedule)
    - False: the callback did no work; reschedule later
    - True: the callback did some work; reschedule soon

    If the callback raises an exception, the traceback is logged and
    the callback is removed.
    """
    self.idlers.append((callback, args, kwds))

  def run_idle(self):
    """Run one of the idle callbacks.

    Returns:
      True if one was called, False if no idle callback was called.
    """
    if not self.idlers or self.inactive >= len(self.idlers):
      return False
    idler = self.idlers.popleft()
    callback, args, kwds = idler
    logging_debug('idler: %s', callback.__name__)
    res = callback(*args, **kwds)
    # See add_idle() for the meaning of the callback return value.
    if res is not None:
      if res:
        self.inactive = 0
      else:
        self.inactive += 1
      self.idlers.append(idler)
    else:
      logging_debug('idler %s removed', callback.__name__)
    return True

  def run0(self):
    """Run one item (a callback or an RPC wait_any).

    Returns:
      A time to sleep if something happened (may be 0);
      None if all queues are empty.
    """
    if self.current:
      self.inactive = 0
      callback, args, kwds = self.current.popleft()
      logging_debug('nowevent: %s', callback.__name__)
      callback(*args, **kwds)
      return 0
    if self.run_idle():
      return 0
    delay = None
    if self.queue:
      delay = self.queue[0][0] - time.time()
      if delay <= 0:
        self.inactive = 0
        _, callback, args, kwds = self.queue.pop(0)
        logging_debug('event: %s', callback.__name__)
        callback(*args, **kwds)
        # TODO: What if it raises an exception?
        return 0
    if self.rpcs:
      self.inactive = 0
      rpc = datastore_rpc.MultiRpc.wait_any(self.rpcs)
      if rpc is not None:
        logging_debug('rpc: %s.%s', rpc.service, rpc.method)
        # Yes, wait_any() may return None even for a non-empty argument.
        # But no, it won't ever return an RPC not in its argument.
        if rpc not in self.rpcs:
          raise RuntimeError('rpc %r was not given to wait_any as a choice %r' %
                             (rpc, self.rpcs))
        callback, args, kwds = self.rpcs[rpc]
        del self.rpcs[rpc]
        if callback is not None:
          callback(*args, **kwds)
          # TODO: Again, what about exceptions?
      return 0
    return delay

  def run1(self):
    """Run one item (a callback or an RPC wait_any) or sleep.

    Returns:
      True if something happened; False if all queues are empty.
    """
    delay = self.run0()
    if delay is None:
      return False
    if delay > 0:
      time.sleep(delay)
    return True

  def run(self):
    """Run until there's nothing left to do."""
    # TODO: A way to stop running before the queue is empty.
    self.inactive = 0
    while True:
      if not self.run1():
        break


class _State(utils.threading_local):
  event_loop = None


_EVENT_LOOP_KEY = '__EVENT_LOOP__'

_state = _State()


def get_event_loop():
  """Return a EventLoop instance.

  A new instance is created for each new HTTP request.  We determine
  that we're in a new request by inspecting os.environ, which is reset
  at the start of each request.  Also, each thread gets its own loop.
  """
  # TODO: Make sure this works with the multithreaded Python 2.7 runtime.
  ev = None
  if os.getenv(_EVENT_LOOP_KEY):
    ev = _state.event_loop
  if ev is None:
    ev = EventLoop()
    _state.event_loop = ev
    os.environ[_EVENT_LOOP_KEY] = '1'
  return ev


def queue_call(*args, **kwds):
  ev = get_event_loop()
  ev.queue_call(*args, **kwds)


def queue_rpc(rpc, callback=None, *args, **kwds):
  ev = get_event_loop()
  ev.queue_rpc(rpc, callback, *args, **kwds)


def add_idle(callback, *args, **kwds):
  ev = get_event_loop()
  ev.add_idle(callback, *args, **kwds)


def run():
  ev = get_event_loop()
  ev.run()


def run1():
  ev = get_event_loop()
  return ev.run1()


def run0():
  ev = get_event_loop()
  return ev.run0()