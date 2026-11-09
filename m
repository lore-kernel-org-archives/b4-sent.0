From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 09 Nov 2026 01:27:19 +0100
Subject: [PATCH 2/2] ceph: drop the dirty folios that a shut down mount
 cannot write back
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ceph-shutdown-dirty-folios-v1-2-34600e8dab20@clyso.com>
References: <20261109-ceph-shutdown-dirty-folios-v1-0-34600e8dab20@clyso.com>
In-Reply-To: <20261109-ceph-shutdown-dirty-folios-v1-0-34600e8dab20@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, 
 Christian Brauner <brauner@kernel.org>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794184042; l=3297;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=apUGUAugMMqkzlDQq7ZBOtMNcuBWkirzNCz7wqu3KjU=;
 b=azC8ejpzs7pUV5FvwNmYgF0qXFQc6onGrB/Eo8qFBp+qNRpyI9JMZiVibAw0v0H918RqrmJgy
 VPFIEa1hU1OANkmw04/+oFXbnlsfL4bn9DDtmxH0i3vV+8XKzg6soOz
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the MDS closes the session of a client (e.g. it evicts it), the
caps go, with any dirty cap state, but the dirty folios stay in the
page cache: the inode is not shut down then, so ceph_purge_inode_cap()
does not have them invalidated, and they are left for writeback.  If
the mount is then shut down by a forced umount before they were written
back, they never are: ceph_writepages_start() only sets -EIO on the
mapping and returns, so they stay dirty for good.  Each keeps its count
in mdsc->dirty_folios and its Fb cap ref, which holds a reference to
the inode, so umount waits until mount_timeout and then finds the inode
busy:

  ceph: ... dropping dirty Fw state for ... 10000000001.fffffffffffffffe
  ceph: ... 10000000001.fffffffffffffffe 1099511627777 forced umount
  ceph: ... umount timed out, 0
  VFS: Busy inodes after unmount of ceph (ceph)
  kernel BUG at fs/super.c:731!

Have the page cache of such an inode invalidated there instead, which
for a shut down inode truncates it, as ceph_purge_inode_cap() does.
That has to happen from the inode work, not from writeback: putting the
last Fb cap ref may put the last reference to the inode, and evicting
it would wait for the writeback that does it.  Then ceph_kill_sb()
flushes the inode work after syncing the fs, so that the folios and
their references are gone before the inodes are evicted.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c  | 14 ++++++++++++++
 fs/ceph/super.c |  8 ++++++++
 2 files changed, 22 insertions(+)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index 2abed478a4ad..2202906f4e18 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -2097,6 +2097,20 @@ static int ceph_writepages_start(struct address_space *mapping,
 	      (wbc->sync_mode == WB_SYNC_ALL ? "ALL" : "HOLD"));
 
 	if (is_forced_umount(mapping)) {
+		/*
+		 * What is dirty here can never be written back now.  Left
+		 * dirty, each folio keeps its Fb cap ref, which holds the
+		 * inode, and its count in the dirty folios that umount
+		 * waits for.  ceph_purge_inode_cap() has them invalidated
+		 * when it removes the caps of a shut down inode, but the
+		 * session may have been closed (the client evicted), and
+		 * the caps removed, before the shut down.  Have them
+		 * dropped now, but not from here: putting the last Fb cap
+		 * ref may put the last reference to the inode, and its
+		 * eviction would wait for this writeback.
+		 */
+		if (mapping_tagged(mapping, PAGECACHE_TAG_DIRTY))
+			ceph_queue_invalidate(inode);
 		ceph_blog_exit(&__ji);
 		return -EIO;
 	}
diff --git a/fs/ceph/super.c b/fs/ceph/super.c
index 40be4b16e486..bb5591c1e154 100644
--- a/fs/ceph/super.c
+++ b/fs/ceph/super.c
@@ -1634,6 +1634,14 @@ static void ceph_kill_sb(struct super_block *s)
 	 */
 	sync_filesystem(s);
 
+	/*
+	 * A shut down mount can't write back its dirty folios, and
+	 * writeback queued their invalidation instead: let it drop them,
+	 * and the references they hold to the inodes, before the inodes
+	 * get evicted.
+	 */
+	flush_workqueue(fsc->inode_wq);
+
 	if (atomic64_read(&mdsc->dirty_folios) > 0) {
 		wait_queue_head_t *wq = &mdsc->flush_end_wq;
 		long timeleft = wait_event_killable_timeout(*wq,

-- 
2.53.0

