From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH v6 0/5] ceph: reduce mdsc->mutex contention in the cephfs
 kclient
Date: Sat, 29 Aug 2026 04:35:00 -0700
Message-Id: <20260829-ceph-mdsc-mutex-optimization-v6-0-466936ccbd9d@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43Ny07DMBQE0F+pvMbI18+EFf+BWPhxQ4xIHcVu1
 FLl33HKgkhZhOVIM2fuJOMUMZOX051MOMcc07kG/XQivrfnD6Qx1Ew445oZENTj2NMhZE+HS8E
 rTWOJQ/y2pQ6pQSOt0875xpFKjBN28frg395/c764T/RlNddGH3NJ0+3xP8Pa++fVDJTR1qKyH
 oTyQr76r1tOzz4NZL2a+RZTBxhfMYYNOMO14TtM/GENwAEmKhaYAAApoe12mNxi/ACTFeu8Fc5
 Izbt2h6kt1hxgqmImCKGssBCY22LLsvwAFkVUcg4CAAA=
X-Change-ID: 20260713-ceph-mdsc-mutex-optimization-7e74ab6bbc8b
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788003303; l=11052;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=iXY8OQV9CG5FQSTQU5cbYVtSRXcHYHW8p2VsYCNoln4=;
 b=v5/xf0hLj7EjGGTLbiejUo2NvFhGlH6Kd/GzW6jVf7BUOiEvvkyoqNECXYgA3qJu2d8UXwn8N
 RMOMFIAwoR+C8qxLCAA5PhpLSFSwdS+5PODYDoF17WRRbloEo46MQKT
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series reduces mdsc->mutex hold times from hundreds of
microseconds to tens of microseconds on the hot request-submit and
reply-handling paths.

The approach is incremental:
  1. Convert oldest_tid to atomic64_t so that __prepare_send_request()
     and __send_request() no longer need the mutex.
  2. Replace the request_tree rbtree with an xarray for O(1) lookups
     and internally-locked iteration.
  3. Add a dedicated wait_list_lock spinlock so wait-list operations
     no longer depend on the global mutex.
  4. Move mdsc->mutex acquisition inside __do_request(), then release
     it during the send phase (message construction and path walking),
     leaving only the brief setup/teardown under the lock.
  5. Narrow the mutex scope in replay_unsafe_requests() similarly.

Tested with concurrent readdir + stat on a 5000-file directory
(32 threads).  bpftrace measurements show:

                 before         after
  __do_request   354-2327 us    10-68 us    (34x)
  handle_reply   51-416 us     10-32 us    (13x)
  submit_request 89-211 us     10-41 us    (5x)

Benchmark results from test_i_caps (aggregate cache test):

  | Test                | Before   | After    | Improvement |
  |---------------------|----------|----------|-------------|
  | stat storm ST       | 692k/s   | 1,420k/s | +105% (2.1x)|
  | stat storm MT       | 722k/s   | 1,373k/s | +90%  (1.9x)|
  | open/close          | 403k/s   | 524k/s   | +30%        |
  | stat hot (cache)    | 353k/s   | 540k/s   | +53%        |
  | readdir             | 877/s    | 832/s    | ~0%         |
  | Total time          | 195s     | 121s     | -38%  (1.6x)|

The 2x stat throughput gain comes from __do_request() no longer
holding mdsc->mutex during the __send_request() phase, so dentry
path walking and message encoding in create_request_message()
run outside the lock.

No functional changes intended.

Testing for 24+ hours:

The runtime validation ran on a vstart cluster (3 active + 3 standby
MDS) with a 32-thread metadata load generator and a kernel built with
CONFIG_PROVE_LOCKING, CONFIG_DEBUG_LIST and CONFIG_DETECT_HUNG_TASK:

- fsstress + dbench smoke runs: clean.
- r1, single-MDS failover churn: 108 failovers across 4 runs, every
  session reconnected, no lost wakeups, no hangs.
- r2, double "ceph mds fail" chaos: ~90 double-fail cycles across
  2 runs, zero hangs, zero kernel warnings, clean teardown.
- r3, double-fail plus victim processes SIGKILLed every 50-400 ms
  (5084 kills in one run) to exercise the request abort path: zero
  warnings, zero list-corruption reports, zero refcount issues.
- r4 (double mds fail + evict churn + 8 victim processes killed at
  200-2000 ms): one 32-minute run FAILED -- a worker was stuck in
  truncate for ~15 minutes at shutdown, the join oracle's first hit
  across all runs.  Live-kernel forensics (drgn against /proc/kcore)
  showed the wedge is unrelated to this series: the double-fail had
  dropped the inode's dirty caps in the session-loss path (caps.c)
  without cleaning up the page wrbuffer refs, so the ceph_inode_work()
  kworker spun forever in __ceph_do_pending_vmtruncate()'s flush
  branch -- with no dirty caps, ceph_writepages_start() returns
  -ENODATA without writing, the refs never drain, and the loop holds
  i_truncate_mutex indefinitely, starving concurrent truncates (and,
  via setattr's inode lock and vfs_unlink()'s target-inode lock,
  unlinks).  Every link of that chain is in caps.c/inode.c/addr.c/VFS
  code untouched by these patches; it is a pre-existing consistency
  bug (dirty caps dropped without wrbuffer-ref cleanup on session
  loss, plus an unbounded flush loop) to be fixed separately.  (The
  r4 evict trigger was skipped in this run as debugfs was not
  mounted; session eviction itself had been exercised in earlier
  testing.)

No lockdep reports, list corruption, refcount warnings, or hung tasks
across the whole campaign.  The campaign also exposed two pre-existing
mainline bugs (a NULL oldest-snapc dereference in the writeback path
and a request abort-path use-after-free), both reproducible without
this series on a vanilla 7.2 kernel and fixed separately.

The whole test code could be find in:
https://tracker.ceph.com/issues/80086
Or
https://tracker.ceph.com/issues/80084

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Changes in v6:
- Only patch 5/5 is changed; patches 1-4 are identical to v5.
- Replace the ad-hoc r_attempts dispatch gate with an explicit
  ownership protocol.  __do_request() and replay_unsafe_requests()
  claim CEPH_MDS_R_DISPATCHING under mdsc->mutex before the unlocked
  prepare/send window and release it on exit, so only one context ever
  rebuilds and sends a request's message.  A claim consumes any
  pending CEPH_MDS_R_RESEND.
- cleanup_session_requests() and handle_forward() set
  CEPH_MDS_R_RESEND under mdsc->mutex when they see DISPATCHING held,
  instead of relying on r_attempts == 0 to trigger a resend.  Fixes
  the v5 race where cleanup_session_requests() could zero r_attempts
  while a sender was between the mutex release and __send_request(),
  letting a second __do_request() in and double ceph_msg_put() the
  request message.
- On release, the owner consumes a pending CEPH_MDS_R_RESEND
  and re-dispatches the request through __do_request() (restart label)
  as long as it is still registered in the request xarray.
- __wake_requests() now takes mdsc->mutex and splices the wait
  list under it, pinning a reference on each request in the same
  critical section as the list_del_init().  This fixes the v5 lockless
  walk of the spliced list against concurrent list_del_init() by the
  park paths, and serializes the SESSION_OPEN wake in handle_session()
  against the park decision in __do_request().
- Collector exclusivity — kick_requests(), __wake_requests()
  and replay_unsafe_requests() skip any request whose r_aux_item is
  non-empty (checked under mdsc->mutex), so two concurrent collectors
  can no longer add the same node to their local lists.
- The re-park paths in __do_request() now list_del_init() the
  request before list_add()ing it onto a wait list, so re-parking is
  idempotent (needed now that a request can re-enter __do_request()
  through the RESEND restart loop).
- __do_request() refuses to dispatch GOT_UNSAFE requests,
  clearing any pending RESEND/DISPATCHING bits, so an unsafe request
  is never parked on a wait list.  Together with the exclusivity
  predicate this guarantees a request is never both wait-listed and on
  session->s_unsafe, and replay_unsafe_requests() remains the only
  replayer of unsafe requests.
- replay_unsafe_requests() claims DISPATCHING in both collect
  loops, and after __send_request() consumes a pending RESEND and
  re-dispatches through __do_request().
- send_mds_reconnect() drops snap_rwsem before calling
  __wake_requests(), which now takes mdsc->mutex internally (lock
  order).
- Link to v5: https://patch.msgid.link/20260818-ceph-mdsc-mutex-optimization-v5-0-7d335a3a1d0b@clyso.com

Changes in v5:
- patch 4: add INIT_LIST_HEAD(&req->r_aux_item) in ceph_mdsc_create_request().
- patch 5: keep requests on session->s_unsafe during replay; use r_aux_item
  only as a walk list.
- Link to v4: https://patch.msgid.link/20260812-ceph-mdsc-mutex-optimization-v4-0-fca3b7462f94@clyso.com

Changes in v4:
- Fix ref leak in __register_request() xa_store error path
- Fix r_attempts data race: move r_attempts++ from
  __prepare_send_request() (lockless) into __do_request() and
  replay_unsafe_requests() under mdsc->mutex.  Adjust the retry
  overflow check accordingly.
- Fix kick_requests() list corruption: detach r_wait from the local
  kick_list before calling __do_request().
- Fix collect-then-replay list-node races in both kick_requests()
  and replay_unsafe_requests(): introduce r_aux_item, a dedicated
  list_head for temporary local list iteration, so that concurrent
  __unregister_request() cannot corrupt the iterator.
- Link to v3: https://patch.msgid.link/20260811-ceph-mdsc-mutex-optimization-v3-0-d031114419f4@clyso.com

Changes in v3:
- Restrict CEPH_FS to 64BIT to prevent xarray index truncation of
  u64 transaction IDs on 32-bit platforms, instead of the previous
  #if BITS_PER_LONG guard.  There are no 32-bit users.
  The survey: https://lore.kernel.org/ceph-devel/CAOJNxR+XiUxR1GNUgd8T18x2KH8kstWtpxwL-mwwE0i_qospJA@mail.gmail.com/T/#t
- Fix two plain reads of oldest_tid in the writer paths to use
  READ_ONCE() for consistency with the lockless read side.
- Replace the original replay_unsafe_requests() change with a
  proper collect-then-replay pattern: unsafe list entries and
  matching old xarray entries are gathered under the mutex with a
  reference taken, then replayed outside it.  Taking a reference
  ensures a concurrent reply handler cannot free an entry out
  from under the local-list iterator.
- Rewrite all commit messages as descriptive prose, focusing on
  the problem and the approach rather than enumerating modified
  functions.
- Link to v2: https://patch.msgid.link/20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com

Changes in v2:
- Add xa_store() error handling and bail out on failure in the submit path
- Guard xarray conversion with BITS_PER_LONG==64, fall back to rbtree on 32-bit
- Fix missing mutex_unlock on early-return path in __do_request()
- Move mutex_unlock before __wake_requests() and kick_requests() calls to
  avoid recursive lock acquisition
- Pin requests with ceph_mdsc_get_request() across lockless __send_request()
  in replay_unsafe_requests() to prevent use-after-free
- Keep mdsc->mutex held on 32-bit for rb_first()/rb_next() iteration in
  replay_unsafe_requests()
- Drop stale "called under mdsc->mutex" comment on __wake_requests()
- Add benchmark results from test_i_caps (2.1x stat throughput improvement)
- Link to v1: https://patch.msgid.link/20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com

To: Ilya Dryomov <idryomov@gmail.com>
To: Alex Markuze <amarkuze@redhat.com>
To: Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Xiubo Li (5):
      ceph: use READ_ONCE/WRITE_ONCE for oldest_tid
      ceph: replace the request_tree rbtree with an xarray keyed by r_tid
      ceph: add wait_list_lock for wait-list serialization
      ceph: move mdsc->mutex into __do_request()
      ceph: narrow mdsc->mutex scope in replay_unsafe_requests

 fs/ceph/Kconfig      |   1 +
 fs/ceph/debugfs.c    |   6 +-
 fs/ceph/mds_client.c | 530 +++++++++++++++++++++++++++++++++++++++------------
 fs/ceph/mds_client.h |  35 +++-
 4 files changed, 440 insertions(+), 132 deletions(-)
---
base-commit: dee30ce1286a0d18b14545ecac345e4cf4a80511
change-id: 20260713-ceph-mdsc-mutex-optimization-7e74ab6bbc8b

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

