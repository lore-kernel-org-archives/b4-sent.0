From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 02 Sep 2026 23:59:01 -0700
Subject: [PATCH v7 1/2] ceph: wake up i_cap_wq waiters on inode shutdown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-lazyio-v7-1-18c2afa06352@clyso.com>
References: <20260902-lazyio-v7-0-18c2afa06352@clyso.com>
In-Reply-To: <20260902-lazyio-v7-0-18c2afa06352@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788418742; l=1160;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=/w+13aDT7byuE64KSZZv8Qvteagzw9g49d8Bw9ILBEg=;
 b=Wd2gkxu4c96IAMJZwP9U5PTF/BKNol+7CKZej5rUGleR6M7qAg/xDl9TxxEtTCQXWsrOTdbjc
 YaEEDI20Q3rDLfcN8aYhMXtcg5NzEEd9m/fnHZWRPvNA/nuWUdqsQaO
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
index 209e8972287d..619a429f0d45 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -3323,6 +3323,13 @@ void ceph_inode_shutdown(struct inode *inode)
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

