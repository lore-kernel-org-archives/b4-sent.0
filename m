From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH v2 0/5] ceph: reduce mdsc->mutex contention in the cephfs
 kclient
Date: Wed, 15 Jul 2026 11:58:40 +0800
Message-Id: <20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NTQ6CMBBGr2K6dgzlV115D8OiHUYZYylpCwEJd
 7fgBVy+5H3vW4Qnx+TF9bAIRyN7tl2E9HgQ2KruScBNZJEmaZlUMgOkvgXTeAQzBJrA9oENf1S
 IQ6ioypUutcazFjHRO3rwtOfv9Y/9oF+EYWtuRss+WDfv/6PcvD+vRgkJXBQVCmVWYJbf8D17e
 0JrRL2u6xdlbKp12gAAAA==
X-Change-ID: 20260713-ceph-mdsc-mutex-optimization-7e74ab6bbc8b
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784087938; l=3516;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Hc9bUFcsUJX8/T86MZ5M9JViEBLi0BZRTLXRNXkgsiY=;
 b=cjKbi7U5KF2avkkJlzNdrHUsTz0/GHS5pgHRSN475L3CPLDSitgiAPv58HlBy6L3o1/W71VPy
 DQ8zYuptr/jDVuakO/Prk/x0ByHRxQrw7tFiQSyWT25CMBO86SZU7+D
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

---
Xiubo Li (5):
      ceph: convert oldest_tid to atomic64_t
      ceph: replace the request_tree rbtree with an xarray keyed by r_tid.
      ceph: add wait_list_lock for wait-list serialization
      ceph: move mdsc->mutex into __do_request()
      ceph: narrow mdsc->mutex scope in replay_unsafe_requests

 fs/ceph/debugfs.c    |   9 ++
 fs/ceph/mds_client.c | 292 +++++++++++++++++++++++++++++++++++++++++++--------
 fs/ceph/mds_client.h |  15 ++-
 3 files changed, 268 insertions(+), 48 deletions(-)
---
base-commit: 7e1f9e2cd2d0e780c394a4402c40e125109fec72
change-id: 20260713-ceph-mdsc-mutex-optimization-7e74ab6bbc8b

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

