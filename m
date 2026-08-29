From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 29 Aug 2026 05:28:00 -0700
Subject: [PATCH v2 2/2] ceph: don't wait forever for undrainable dirty refs
 in vmtruncate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-b4-ceph-fix-null-oldest-snapc-new-v2-2-71fb4aa49968@clyso.com>
References: <20260829-b4-ceph-fix-null-oldest-snapc-new-v2-0-71fb4aa49968@clyso.com>
In-Reply-To: <20260829-b4-ceph-fix-null-oldest-snapc-new-v2-0-71fb4aa49968@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, Sage Weil <sage@newdream.net>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788006479; l=3073;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=9a3HsBuwTPgOP5z1+94cCYsCp9toglPrah46KIsV2Vs=;
 b=rxokNK7vuqrMhJnHCmuCtU+X2bPSReQnMp+IKA9037NojxQHfRb0q2Qx/kx6p2dqBHJFVXkym
 tvNbBQHXHtvCepq/sxMUo6j7g1uyRraWUfXK5Y8J4QGu+vPQNpLk6wk
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a session is lost, ceph_purge_inode_cap() removes all cap_snaps
of the inode, but the dirty folios referencing their snap contexts
survive in the page cache.  Their refs are left in i_wrbuffer_ref
while no cap_snap owns them, so i_wrbuffer_ref_head stays below
i_wrbuffer_ref forever, and the flush in __ceph_do_pending_vmtruncate()
can never drain them: get_oldest_context() returns NULL and
ceph_writepages_start() bails out with -ENODATA without writing
anything.  The retry loop then spins forever while holding
i_truncate_mutex, starving concurrent truncates and unlinks on the
same inode.

Detect the orphaned refs (i_wrbuffer_ref - i_wrbuffer_ref_head exceeds
the sum of the cap_snaps' dirty_pages) and skip the flush in that
case: there is no snapped data left to preserve, and
truncate_pagecache() below discards the folios and drops the refs,
which ceph_put_wrbuffer_cap_refs() tolerates for a missing cap_snap.

Fixes: 355da1eb7a1f9 ("ceph: inode operations")
Cc: stable@vger.kernel.org
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/inode.c | 37 +++++++++++++++++++++++++++++++------
 1 file changed, 31 insertions(+), 6 deletions(-)

diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index 9ea0588a18f9..44d99fab5716 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -2334,12 +2334,37 @@ void __ceph_do_pending_vmtruncate(struct inode *inode)
 	 * possibly truncate them.. so write AND block!
 	 */
 	if (ci->i_wrbuffer_ref_head < ci->i_wrbuffer_ref) {
-		spin_unlock(&ci->i_ceph_lock);
-		doutc(cl, "%p %llx.%llx flushing snaps first\n", inode,
-		      ceph_vinop(inode));
-		filemap_write_and_wait_range(&inode->i_data, 0,
-					     inode->i_sb->s_maxbytes);
-		goto retry;
+		struct ceph_cap_snap *capsnap;
+		int snap_dirty = 0;
+
+		list_for_each_entry(capsnap, &ci->i_cap_snaps, ci_item)
+			snap_dirty += capsnap->dirty_pages;
+
+		/*
+		 * i_wrbuffer_ref - i_wrbuffer_ref_head should equal
+		 * the sum of capsnap->dirty_pages.  A session loss
+		 * removes all cap_snaps (ceph_purge_inode_cap()) while
+		 * the dirty folios referencing their contexts survive
+		 * in the page cache, leaving orphaned refs that no
+		 * flush can drain: get_oldest_context() returns NULL
+		 * and ceph_writepages_start() bails out with -ENODATA.
+		 * Waiting here would spin forever while holding
+		 * i_truncate_mutex.  In that case skip the flush and let
+		 * truncate_pagecache() discard the folios and drop the
+		 * refs; ceph_put_wrbuffer_cap_refs() tolerates the
+		 * missing cap_snap.
+		 */
+		if (ci->i_wrbuffer_ref - ci->i_wrbuffer_ref_head > snap_dirty) {
+			doutc(cl, "%p %llx.%llx orphaned dirty refs\n",
+			      inode, ceph_vinop(inode));
+		} else {
+			spin_unlock(&ci->i_ceph_lock);
+			doutc(cl, "%p %llx.%llx flushing snaps first\n", inode,
+			      ceph_vinop(inode));
+			filemap_write_and_wait_range(&inode->i_data, 0,
+						     inode->i_sb->s_maxbytes);
+			goto retry;
+		}
 	}
 
 	/* there should be no reader or writer */

-- 
2.53.0

