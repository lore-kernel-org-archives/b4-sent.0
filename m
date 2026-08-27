From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 27 Aug 2026 04:08:17 -0700
Subject: [PATCH v3 2/2] ceph: keep the inode, not the name, when a dentry
 lease expires
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-b4-b4-ceph-dentry-caps-v3-2-f0619f4134e0@clyso.com>
References: <20260827-b4-b4-ceph-dentry-caps-v3-0-f0619f4134e0@clyso.com>
In-Reply-To: <20260827-b4-b4-ceph-dentry-caps-v3-0-f0619f4134e0@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, Jeff Layton <jlayton@kernel.org>, 
 David Howells <dhowells@redhat.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787828896; l=9430;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=j4YgMxx1p5DyTcNGf73hdsboxM67AqIIfi+w+T5b3pk=;
 b=QQrOKjmEt8h0TlfgAXlhxhWgsot18timdfbcngWtaa7fMTWcrhg7AkK+NMfu6srWdJR9iaEbw
 L85YcOR1WBED9/6lAMjVund/5TMMaC1TydN1kMxxTRaaWweYxrtBmD3
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_d_delete() drops a dentry once its lease expires.  Since ceph uses
inode_just_drop() for ->drop_inode, that last dput also evicts the
inode, and ceph_evict_inode() throws away a page cache that the caps
still vouch for.  A buffered write that outlasts the dentry lease (30s
by default on the MDS side) is therefore flushed and closed, and the
reopen re-reads everything from the OSDs even though both the caps and
the pages were still valid.

Commit 52dd0f1b3f94 ("ceph: use generic_delete_inode() for
->drop_inode") removed the ->drop_inode hook because "positive dentry
and corresponding inode are always accompanied in MDS reply.  So no
need to keep inode in the cache after dropping all its aliases".  That
holds for the metadata, but it ties the lifetime of the page cache to
the lifetime of a name, and the two are validated by entirely different
things: a dentry is only as good as its lease, while cached pages are
good for as long as the caps that back them.

So bring the hook back and keep a regular file's inode while it still
has cached pages and still holds real caps.  The name is unaffected: an
expired dentry is unhashed exactly as before, and the next lookup goes
to the MDS and finds the retained inode via ceph_get_inode() ->
iget5_locked(), which is keyed on the vino from the reply rather than
on any dentry.  ceph_fill_inode() then refills it without touching the
mapping.

Retention is bounded by the page cache itself, and reclaim runs in that
order rather than the other way round.  A retained inode holds no
reference of its own, but it does not sit on the inode LRU either:
mapping_shrinkable() is false while real folios are present, so the
inode shrinker never sees it.  Page reclaim frees its pages like any
other file's; emptying the mapping is what makes it shrinkable and puts
it on the LRU, and only then can the inode shrinker evict it.  Unmount
evicts it regardless, as evict_inodes() walks sb->s_inodes rather than
the LRU.

MDS cap trim needs one more thing.  trim_caps_cb() releases an unused
cap indirectly, by pruning the inode's aliases and letting the eviction
that follows call __ceph_remove_caps().  Retaining the inode breaks
that chain in both of its cases: an inode whose aliases are already
gone was never reachable that way, and after d_prune_aliases() the
iput() that ceph_iterate_session_caps() owes the inode no longer evicts
it.  Give that path an explicit override in
CEPH_I_EVICT_ON_FINAL_IPUT_BIT, which ceph_drop_inode() consumes with
test_and_clear_bit().  Being one-shot is the point: it lets the MDS
force this inode out now without permanently changing how the inode is
cached afterwards, which is why I_DONTCACHE is not used here.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/inode.c      | 59 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 fs/ceph/mds_client.c | 37 ++++++++++++++++++++++++++------
 fs/ceph/super.c      |  2 +-
 fs/ceph/super.h      |  2 ++
 4 files changed, 93 insertions(+), 7 deletions(-)

diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index d52e2b389e0b..59a3a85a5552 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -792,6 +792,65 @@ void ceph_evict_inode(struct inode *inode)
 	ceph_put_string(rcu_dereference_raw(ci->i_cached_layout.pool_ns));
 }
 
+/*
+ * Decide whether to keep an inode once its last reference is gone.
+ *
+ * Dropping it here runs ceph_evict_inode(), which throws away the page
+ * cache along with the caps that still vouch for it.  Keep a regular
+ * file's inode while it has cached pages and still holds real caps, so
+ * that a close and reopen can serve reads from the page cache instead
+ * of re-reading everything from the OSDs.
+ *
+ * Such an inode is not pinned: it holds no reference of its own, and
+ * page reclaim frees its pages like any other file's.  It is not on the
+ * inode LRU either, since mapping_shrinkable() is false while real
+ * folios are present; emptying the mapping is what puts it there for
+ * the inode shrinker.  Unmount evicts it regardless, since
+ * evict_inodes() walks sb->s_inodes rather than the LRU.
+ *
+ * The retention is bypassed whenever fscrypt requires the inode to be
+ * evicted, e.g. after its encryption key has been removed: the page
+ * cache holds plaintext, so it has to go with the key.
+ * FS_IOC_REMOVE_ENCRYPTION_KEY relies on that, as it evicts the
+ * dentries and then expects the inodes to follow.  fscrypt is
+ * therefore asked before any of the retention below, and its answer is
+ * never overridden by it.
+ *
+ * Handing caps back to the MDS used to fall out of this eviction, so
+ * trim_caps_cb() sets CEPH_I_EVICT_ON_FINAL_IPUT_BIT to override the
+ * retention for one put when the MDS asks for its caps back.
+ *
+ * ->drop_inode() is called with inode->i_lock held, so i_ceph_lock
+ * cannot be taken here and i_caps is tested racily.  That is good
+ * enough: either answer only keeps or drops an inode that could have
+ * gone the other way.
+ */
+int ceph_drop_inode(struct inode *inode)
+{
+	struct ceph_inode_info *ci = ceph_inode(inode);
+
+	/* the MDS asked for this one back */
+	if (test_and_clear_bit(CEPH_I_EVICT_ON_FINAL_IPUT_BIT,
+			       &ci->i_ceph_flags))
+		return 1;
+
+	if (inode_generic_drop(inode))
+		return 1;
+
+	if (fscrypt_drop_inode(inode))
+		return 1;
+
+	if (ceph_inode_is_shutdown(inode))
+		return 1;
+
+	/* nothing here worth keeping the inode for */
+	if (!S_ISREG(inode->i_mode) || !inode->i_data.nrpages)
+		return 1;
+
+	/* keep the pages only while the inode still holds real caps */
+	return !__ceph_is_any_real_caps(ci);
+}
+
 static inline blkcnt_t calc_inode_blocks(u64 size)
 {
 	return (size + (1<<9) - 1) >> 9;
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 2fdef73b28f4..f5d0590df8b2 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -2254,8 +2254,9 @@ static bool drop_negative_children(struct dentry *dentry)
  * Trim old(er) caps.
  *
  * Because we can't cache an inode without one or more caps, we do
- * this indirectly: if a cap is unused, we prune its aliases, at which
- * point the inode will hopefully get dropped to.
+ * this indirectly: if a cap is unused, we prune its aliases and mark
+ * the inode for eviction, at which point the inode will hopefully get
+ * dropped too, releasing the cap with it.
  *
  * Yes, this is a bit sloppy.  Our only real goal here is to respond to
  * memory pressure from the MDS, though, so it needn't be perfect.
@@ -2316,20 +2317,44 @@ static int trim_caps_cb(struct inode *inode, int mds, void *arg)
 		(*remaining)--;
 	} else {
 		struct dentry *dentry;
+		bool pruned = false;
+
 		/* try dropping referring dentries */
 		spin_unlock(&ci->i_ceph_lock);
 		dentry = d_find_any_alias(inode);
-		if (dentry && drop_negative_children(dentry)) {
-			int count;
+		if (!dentry) {
+			/* nothing refers to it in the first place */
+			pruned = true;
+		} else if (drop_negative_children(dentry)) {
 			dput(dentry);
 			d_prune_aliases(inode);
+			pruned = true;
+		} else {
+			dput(dentry);
+		}
+
+		if (pruned) {
+			int count;
+
+			/*
+			 * ceph_drop_inode() keeps a regular file's inode
+			 * alive while it still has cached pages, so pruning
+			 * the aliases is no longer enough on its own to get
+			 * this cap back.  Mirror that condition here and ask
+			 * for a one-shot eviction: the iput() that
+			 * ceph_iterate_session_caps() still owes this inode
+			 * then runs ceph_evict_inode(), which is what hands
+			 * the cap back.
+			 */
+			if (S_ISREG(inode->i_mode) && inode->i_data.nrpages)
+				set_bit(CEPH_I_EVICT_ON_FINAL_IPUT_BIT,
+					&ci->i_ceph_flags);
+
 			count = icount_read_once(inode);
 			if (count == 1)
 				(*remaining)--;
 			doutc(cl, "%p %llx.%llx cap %p pruned, count now %d\n",
 			      inode, ceph_vinop(inode), cap, count);
-		} else {
-			dput(dentry);
 		}
 		return 0;
 	}
diff --git a/fs/ceph/super.c b/fs/ceph/super.c
index 88ea9aa53adc..150d05d685bd 100644
--- a/fs/ceph/super.c
+++ b/fs/ceph/super.c
@@ -1052,7 +1052,7 @@ static const struct super_operations ceph_super_ops = {
 	.alloc_inode	= ceph_alloc_inode,
 	.free_inode	= ceph_free_inode,
 	.write_inode    = ceph_write_inode,
-	.drop_inode	= inode_just_drop,
+	.drop_inode	= ceph_drop_inode,
 	.evict_inode	= ceph_evict_inode,
 	.sync_fs        = ceph_sync_fs,
 	.put_super	= ceph_put_super,
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index 72d4e30304dc..ff736fbf1fe9 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -713,6 +713,7 @@ static inline struct inode *ceph_find_inode(struct super_block *sb,
 					      * force a cap message to the MDS once
 					      * the deferred work completes
 					      */
+#define CEPH_I_EVICT_ON_FINAL_IPUT_BIT	(16) /* evict at the final iput() */
 
 #define CEPH_I_DIR_ORDERED		(1 << CEPH_I_DIR_ORDERED_BIT)
 #define CEPH_I_FLUSH			(1 << CEPH_I_FLUSH_BIT)
@@ -1100,6 +1101,7 @@ struct ceph_acl_sec_ctx;
 extern const struct inode_operations ceph_file_iops;
 
 extern struct inode *ceph_alloc_inode(struct super_block *sb);
+extern int ceph_drop_inode(struct inode *inode);
 extern void ceph_evict_inode(struct inode *inode);
 extern void ceph_free_inode(struct inode *inode);
 

-- 
2.53.0

