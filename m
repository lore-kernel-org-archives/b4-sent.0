From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 27 Aug 2026 03:16:03 -0700
Subject: [PATCH v6 1/2] ceph: wake up i_cap_wq waiters on inode shutdown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-lazyio-v6-1-2755b379b8de@clyso.com>
References: <20260827-lazyio-v6-0-2755b379b8de@clyso.com>
In-Reply-To: <20260827-lazyio-v6-0-2755b379b8de@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787825763; l=1160;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=wOzreLw8o1CmL+OtUmksL+iiCd6T7ivHrgbY3g5NRtM=;
 b=RrrSt9Q/ciUxfmOZJ9+OMrK7qDcWQ2dMILOZtiH3YIz3VA+PbgbRlnmTvf+f3Ad2oLsAtQyLf
 ESKO/7quyY8DHbVz8eGmX0l5FZ/xJEJipBHPjqW6gsFaR6JSyeDUX3g
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_inode_shutdown() purges every cap on the inode but never wakes
i_cap_wq, unlike remove_session_caps_cb() which does so after the same
kind of purge.  Anyone blocked in ceph_get_caps() is waiting on that
queue for caps that are now gone for good, so the wait only ends when
the task is killed.

Wake the queue after purging so the waiters get a chance to notice the
shutdown and bail out.

Link: https://tracker.ceph.com/issues/77594
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/inode.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index d52e2b389e0b..153a5242080f 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -3252,6 +3252,13 @@ void ceph_inode_shutdown(struct inode *inode)
 	}
 	spin_unlock(&ci->i_ceph_lock);
 
+	/*
+	 * The caps are gone now, so wake up anyone waiting for them -- they
+	 * are never coming back and the waiters need to notice the shutdown
+	 * instead.  remove_session_caps_cb() does the same after purging.
+	 */
+	wake_up_all(&ci->i_cap_wq);
+
 	if (invalidate)
 		ceph_queue_invalidate(inode);
 	while (iputs--)

-- 
2.53.0

