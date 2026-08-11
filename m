From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH v3 0/5] ceph: reduce mdsc->mutex contention in the cephfs
 kclient
Date: Tue, 11 Aug 2026 13:17:44 +0800
Message-Id: <20260811-ceph-mdsc-mutex-optimization-v3-0-d031114419f4@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NTQ6CMBQE4KuQrq2h5afoynsYF+3jKTVCCS0NS
 Li7LW50pctJZr5ZiMVBoyXHZCEDem216ULIdgmBRnY3pLoOmfCUl6lgGQXsG9rWFmg7Opyo6Z1
 u9VO6MKQCRS5VqRRUigSiH/Cqp40/X97ZjuqO4KIZG422zgzz9u9Z7P155RlN6UFiIYFlBWT5C
 R6zNXswLYlXnn9ixQ+MRyzFiinBS8G/sHVdX75A+3knAQAA
X-Change-ID: 20260713-ceph-mdsc-mutex-optimization-7e74ab6bbc8b
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786425473; l=4810;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=n1jT7e5mreJc0GffZUYf3wd9i4swpWsdI04Qzoj8pBc=;
 b=WOJftx7Svm7qweaynd0K+Il0cL/PncoDpxvt6/KCqlfA8/cHqvy1lg7VREgSiNHYQwSgriSpR
 //ClcgYKcXrADPjLVa56f4Z5K/ONFONn2XZidC4mgiqSq9tPO9Nsx82
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

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
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
 fs/ceph/mds_client.c | 253 +++++++++++++++++++++++++++++----------------------
 fs/ceph/mds_client.h |   6 +-
 4 files changed, 154 insertions(+), 112 deletions(-)
---
base-commit: 30c0913a2b44a66dc17283a88489b3f3e12f4327
change-id: 20260713-ceph-mdsc-mutex-optimization-7e74ab6bbc8b

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

