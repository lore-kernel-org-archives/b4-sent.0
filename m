From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 09 Nov 2026 01:27:18 +0100
Subject: [PATCH 1/2] ceph: count a dirty folio out wherever it stops being
 dirty
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ceph-shutdown-dirty-folios-v1-1-34600e8dab20@clyso.com>
References: <20261109-ceph-shutdown-dirty-folios-v1-0-34600e8dab20@clyso.com>
In-Reply-To: <20261109-ceph-shutdown-dirty-folios-v1-0-34600e8dab20@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, 
 Christian Brauner <brauner@kernel.org>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794184042; l=3807;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=INWE3Vox69f5KmDexh7azfR2ub5l95HDLYAiPuZXyAY=;
 b=eMbn3Nlh7jlWsIYwOUjO1Yw2xwCp1n3T5X1NFs7VVn6+/2kKTUtnkd9LmbWvT44WLBbfQqEkD
 9wHwIqCpH0cAHKFfqZNdO5Qp4aqggqnQGbLQlS17ixsBXWRC7GL1s1r
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_dirty_folio() counts every folio that becomes dirty in
mdsc->dirty_folios, and ceph_kill_sb() waits for that count to reach
zero before it goes on.  writepages_finish() takes a folio out of the
count when it has been written, but two other places that end a
folio's dirty state only put its snap context and Fb cap ref:

 - ceph_invalidate_folio(), which drops a dirty folio when it is
   truncated or invalidated as a whole;
 - write_folio_nounlock(), which writes back a single folio that is
   dirty in an older snap context than the one a new write needs.

Every such folio stays in the count for good, so after e.g. a truncate
of dirty data, umount waits until mount_timeout:

  ceph: [<fsid> <client>]: umount timed out, 0

Take the folio out of the count there too: ceph_invalidate_folio() now
drops it with ceph_folio_drop_dirty(), which does all of it.

Fixes: fd7449d937e7 ("ceph: fix generic/421 test failure")
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c | 29 +++++++++++++++++++----------
 1 file changed, 19 insertions(+), 10 deletions(-)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index b0f06d21ca72..2abed478a4ad 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -126,11 +126,14 @@ static struct ceph_snap_context *ceph_folio_detach_snapc(struct folio *folio)
 }
 
 /*
- * Every dirty byte of a lazy I/O folio lies beyond EOF now: there is
- * nothing to write back, and the bytes in front of its dirty range are
- * not this client's to send.  Drop the folio's dirty state, which the
- * caller has already cleared, with the folio locked, and its count in
- * the dirty folios that umount waits for.
+ * Drop the dirty state of a folio that will not be written back, with
+ * the folio locked: its snap context and dirty range, its Fb cap ref and
+ * its count in the dirty folios that umount waits for.  The caller has
+ * cleared the dirty flag already, or is about to (invalidate_folio).
+ *
+ * E.g. every dirty byte of a lazy I/O folio lies beyond EOF now: there
+ * is nothing to write back, and the bytes in front of its dirty range
+ * are not this client's to send.
  */
 static void ceph_folio_drop_dirty(struct inode *inode, struct folio *folio)
 {
@@ -304,8 +307,6 @@ static void ceph_invalidate_folio(struct folio *folio, size_t offset,
 	struct inode *inode = folio->mapping->host;
 	struct ceph_fs_client *fsc = ceph_inode_to_fs_client(inode);
 	struct ceph_client *cl = ceph_inode_to_client(inode);
-	struct ceph_inode_info *ci = ceph_inode(inode);
-	struct ceph_snap_context *snapc;
 	struct ceph_journal_info __ji;
 
 	ceph_blog_enter_gfp(fsc, &__ji, GFP_ATOMIC);
@@ -339,9 +340,12 @@ static void ceph_invalidate_folio(struct folio *folio, size_t offset,
 		boutc(cl, "%llx.%llx idx %lu full dirty page\n",
 		      ceph_vinop(inode), folio->index);
 
-		snapc = ceph_folio_detach_snapc(folio);
-		ceph_put_wrbuffer_cap_refs(ci, 1, snapc);
-		ceph_put_snap_context(snapc);
+		/*
+		 * The folio goes away dirty (a truncate, or a shut down
+		 * mount): it must leave the dirty folios count too, or
+		 * umount waits for it until mount_timeout.
+		 */
+		ceph_folio_drop_dirty(inode, folio);
 	}
 
 	netfs_invalidate_folio(folio, offset, length);
@@ -1211,6 +1215,11 @@ static int write_folio_nounlock(struct folio *folio,
 	ceph_put_wrbuffer_cap_refs(ci, 1, snapc);
 	ceph_put_snap_context(snapc);  /* page's reference */
 
+	if (atomic64_dec_return(&fsc->mdsc->dirty_folios) <= 0) {
+		wake_up_all(&fsc->mdsc->flush_end_wq);
+		WARN_ON(atomic64_read(&fsc->mdsc->dirty_folios) < 0);
+	}
+
 	if (atomic_long_dec_return(&fsc->writeback_count) <
 	    CONGESTION_OFF_THRESH(fsc->mount_options->congestion_kb))
 		fsc->write_congested = false;

-- 
2.53.0

