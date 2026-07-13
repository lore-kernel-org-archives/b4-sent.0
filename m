From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH 0/5] ceph: reduce mdsc->mutex contention in the cephfs
 kclient
Date: Mon, 13 Jul 2026 17:46:06 +0800
Message-Id: <20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMAyA4VchPdsE0DDjqxgPa6lSk8GyDkMkv
 LsTjt/h/1cwSSoGt2qFJB81ncaC5lQBD358CWpfDG3ddrVrzsgSBwy9MYY5y4JTzBr063MJ0Ym
 7eOqI+EpQFjHJU5d9f38ctpnewvn/hG37AazjqtKAAAAA
X-Change-ID: 20260713-ceph-mdsc-mutex-optimization-7e74ab6bbc8b
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783936018; l=1882;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=KZ+fkidvi42nkXB/n0WY+0pBKs4rc6ZQHLQ2OS9bDmc=;
 b=tOSLa1c3pDIWGTzSE0WJDO+iw4bGsyaTGnd29rW2QWrNFVBo0Au4onNhidaPX4Bkik39YWolC
 luajOeZQMMNAqI+ZJpUYtdXWZ1E550nP7FX5pS9vGJZz7repKWmOlev
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

No functional changes intended.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Xiubo Li (5):
      ceph: convert oldest_tid to atomic64_t
      ceph: replace the request_tree rbtree with an xarray keyed by r_tid.
      ceph: add wait_list_lock for wait-list serialization
      ceph: move mdsc->mutex into __do_request()
      ceph: narrow mdsc->mutex scope in replay_unsafe_requests

 fs/ceph/debugfs.c    |   6 +-
 fs/ceph/mds_client.c | 207 +++++++++++++++++++++++++++------------------------
 fs/ceph/mds_client.h |   8 +-
 3 files changed, 117 insertions(+), 104 deletions(-)
---
base-commit: 7e1f9e2cd2d0e780c394a4402c40e125109fec72
change-id: 20260713-ceph-mdsc-mutex-optimization-7e74ab6bbc8b

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

