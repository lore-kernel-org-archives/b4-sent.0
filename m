From: Xiubo Li <xiubo.li@clyso.com>
Date: Fri, 30 Oct 2026 09:07:35 +0100
Subject: [PATCH v4 3/5] ceph: write back only the dirty bytes of a lazy I/O
 write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-b4-wip-ceph-lazyio-fix-v4-3-f734a26bbaab@clyso.com>
References: <20261030-b4-wip-ceph-lazyio-fix-v4-0-f734a26bbaab@clyso.com>
In-Reply-To: <20261030-b4-wip-ceph-lazyio-fix-v4-0-f734a26bbaab@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793347670; l=26462;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=xuqOVcC/wji2mHxvmKrfNbghk3fwt7MPV8X1RThISpo=;
 b=WJouRMdtYfWxaTioM0HJifo29oeCrwLG6B+9BkxO3c9+7mc//+Luhqebll6YuLrGFqXqVVbpV
 2OAAbZ5TonmCWWPq/T0u48a2P8AOqgc2+cHtoeDr9P9t5DQotKd/8R2
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With the lazyio mount option several clients buffer writes to one
shared file.  A write that covers only part of a page dirties the whole
page, so writeback sends the bytes around it too: whatever the page held
from its read-before-write, or zeros beyond the local EOF.  Those stale
bytes overwrite the records other clients wrote next to it, and io500
ior-hard (47008-byte records interleaved across nodes) fails its read
verification.

Keep the dirty byte range of a page that a lazy I/O write dirtied only
part of: ceph_write_end() hangs a small struct holding the snap context
and the range off folio->private, tagged with bit 1 (bit 0 is netfs's
NETFS_FOLIO_INFO), and widens the range on later writes to the dirty
folio, which it no longer marks dirty again.  Writeback then starts an
extent where a range starts (with the in-page offset as the data
alignment) and ends it where a range ends.  A write without lazy I/O
starts no range: this client holds the buffer cap, the rest of the page
is current, and the page goes out whole as before, which avoids the
unaligned OSD writes that cost buffered sub-page overwrites 5-9% IOPS.

The corner cases:
 - a write covering the whole page, a failed allocation, an encrypted
   inode, or an mmap/GUP dirtying of a dirty page leaves (or makes) the
   page dirty as a whole;
 - a page that may be pinned for writing (GUP) starts no range: a pin
   older than the last writeback may write any byte of it, and its
   unpin does not dirty an already dirty page again.  The pin is looked
   for before the write dirties the page, with the page locked, so that
   an unpin cannot slip in between;
 - the cache (fsc) gets whole pages from the start of the page, as
   cachefiles rejects a write that starts inside one and would leave its
   old copy to be read back; the OSD write keeps to the range;
 - a write that copied nothing does not dirty the page;
 - a lazy I/O write apart from the range first writes the page back, so
   that the range never spans bytes this client did not write;
 - a truncate that cuts into the range clips it; a range that a
   truncate drops entirely, or that EOF (read when the page is checked,
   not when the pass began) has moved below, leaves the page clean
   (its snap context, buffer cap ref and dirty folio count dropped), as
   the bytes in front of the range are not this client's to send;
 - a page that would need an extent beyond the request's ops is left
   dirty before it is cleaned, since redirtying it would lose the range.

The struct is freed with kfree_rcu(), so that the writeback waiters,
which look at the snap context of pages under writeback without locking
them, and the unlocked redirtying can peek under RCU.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c | 417 ++++++++++++++++++++++++++++++++++++++++++++++++++++-----
 1 file changed, 381 insertions(+), 36 deletions(-)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index dd2bd8ed2424..68cae8e15367 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -68,10 +68,158 @@
 static int ceph_netfs_check_write_begin(struct file *file, loff_t pos, unsigned int len,
 					struct folio **foliop, void **_fsdata);
 
+/*
+ * With lazy I/O several clients buffer writes to one file, and the bytes
+ * of a page around what this client wrote may be stale here: another
+ * client's data, or zeros beyond what this client knows as EOF.  A page
+ * that a lazy I/O write dirtied only part of therefore carries the dirty
+ * byte range with its snap context, so that writeback sends only those
+ * bytes: folio->private then points to a struct ceph_dirty_range, tagged
+ * with CEPH_FOLIO_DIRTY_RANGE.  (Bit 0 is netfs's NETFS_FOLIO_INFO.)  A
+ * folio without one is dirty as a whole.
+ *
+ * A folio that may be pinned for writing (GUP) never starts a range.
+ *
+ * The range is set up, changed and read with the folio locked, except
+ * that a folio may be dirtied again without the lock (GUP), and the
+ * writeback waiters peek at the snap context of folios under writeback:
+ * those only set ->whole or read ->snapc, under RCU.
+ */
+#define CEPH_FOLIO_DIRTY_RANGE	0x2UL
+
+struct ceph_dirty_range {
+	struct ceph_snap_context *snapc;
+	unsigned int start, end;	/* dirty bytes within the folio */
+	bool whole;			/* dirtied as a whole after all */
+	struct rcu_head rcu;
+};
+
+static inline struct ceph_dirty_range *__ceph_dirty_range(const void *priv)
+{
+	if (!((unsigned long)priv & CEPH_FOLIO_DIRTY_RANGE))
+		return NULL;
+	return (void *)((unsigned long)priv & ~CEPH_FOLIO_DIRTY_RANGE);
+}
+
+/* With the folio locked, or under rcu_read_lock() */
 static inline
 struct ceph_snap_context *ceph_folio_snap_context(const struct folio *folio)
 {
-	return folio->private;
+	void *priv = READ_ONCE(folio->private);
+	struct ceph_dirty_range *dr = __ceph_dirty_range(priv);
+
+	return dr ? dr->snapc : priv;
+}
+
+/* Detach the snap context of a folio, and drop its dirty range. */
+static struct ceph_snap_context *ceph_folio_detach_snapc(struct folio *folio)
+{
+	void *priv = folio_detach_private(folio);
+	struct ceph_dirty_range *dr = __ceph_dirty_range(priv);
+	struct ceph_snap_context *snapc;
+
+	if (!dr)
+		return priv;
+	snapc = dr->snapc;
+	kfree_rcu(dr, rcu);
+	return snapc;
+}
+
+/*
+ * Every dirty byte of a lazy I/O folio lies beyond EOF now: there is
+ * nothing to write back, and the bytes in front of its dirty range are
+ * not this client's to send.  Drop the folio's dirty state, which the
+ * caller has already cleared, with the folio locked, and its count in
+ * the dirty folios that umount waits for.
+ */
+static void ceph_folio_drop_dirty(struct inode *inode, struct folio *folio)
+{
+	struct ceph_mds_client *mdsc = ceph_sb_to_mdsc(inode->i_sb);
+	struct ceph_snap_context *snapc = ceph_folio_detach_snapc(folio);
+
+	ceph_put_wrbuffer_cap_refs(ceph_inode(inode), 1, snapc);
+	ceph_put_snap_context(snapc);
+
+	if (atomic64_dec_return(&mdsc->dirty_folios) <= 0) {
+		wake_up_all(&mdsc->flush_end_wq);
+		WARN_ON(atomic64_read(&mdsc->dirty_folios) < 0);
+	}
+}
+
+/* The bytes of a dirty folio that writeback sends: [*start, *end) */
+static void ceph_folio_dirty_range(const struct folio *folio,
+				   size_t *start, size_t *end)
+{
+	struct ceph_dirty_range *dr = __ceph_dirty_range(folio->private);
+
+	if (dr && !READ_ONCE(dr->whole)) {
+		*start = dr->start;
+		*end = dr->end;
+	} else {
+		*start = 0;
+		*end = folio_size(folio);
+	}
+}
+
+/* Any byte of the folio may be dirty now (mmap or GUP writes). */
+static void ceph_folio_dirty_whole(struct folio *folio)
+{
+	struct ceph_dirty_range *dr;
+
+	rcu_read_lock();
+	dr = __ceph_dirty_range(READ_ONCE(folio->private));
+	if (dr)
+		WRITE_ONCE(dr->whole, true);
+	rcu_read_unlock();
+}
+
+/*
+ * Note a write of @copied bytes at @pos into @folio, which it has just
+ * dirtied; @was_dirty: the folio already was dirty before; @lazy: the
+ * write came through a lazy I/O open.
+ *
+ * Only a lazy I/O write starts a range: without lazy I/O this client
+ * holds the buffer cap, the rest of the page is current, and it may go
+ * out whole, as it always did.  A later write of any kind widens an
+ * existing range.  Nothing to save if the write covers the whole folio:
+ * not even up to the local EOF, which may be stale while other clients
+ * write beyond it.
+ */
+static void ceph_folio_note_write(struct inode *inode, struct folio *folio,
+				  bool was_dirty, loff_t pos,
+				  unsigned int copied, bool lazy)
+{
+	struct ceph_dirty_range *dr = __ceph_dirty_range(folio->private);
+	unsigned int start = offset_in_folio(folio, pos);
+	unsigned int end = start + copied;
+
+	if (!copied || IS_ENCRYPTED(inode))
+		return;
+	if (was_dirty) {
+		/* a whole dirty folio stays whole */
+		if (dr) {
+			dr->start = min(dr->start, start);
+			dr->end = max(dr->end, end);
+		}
+		return;
+	}
+	if (!lazy)
+		return;
+
+	/* a folio that was clean has just got its plain snap context */
+	if (WARN_ON_ONCE(dr || !folio->private))
+		return;
+	if (!start && end >= folio_size(folio))
+		return;
+	dr = kmalloc_obj(*dr, GFP_NOFS);
+	if (!dr)
+		return;		/* then it all goes out */
+	dr->snapc = folio_get_private(folio);
+	dr->start = start;
+	dr->end = end;
+	dr->whole = false;
+	folio_change_private(folio,
+			     (void *)((unsigned long)dr | CEPH_FOLIO_DIRTY_RANGE));
 }
 
 /*
@@ -95,6 +243,12 @@ static bool ceph_dirty_folio(struct address_space *mapping, struct folio *folio)
 		boutc(cl, "%llx.%llx %p idx %lu -- already dirty\n",
 		      ceph_vinop(inode), folio, folio->index);
 		VM_BUG_ON_FOLIO(!folio_test_private(folio), folio);
+		/*
+		 * Someone other than ceph_write_end() (which doesn't call
+		 * this on a dirty folio) dirtied it again, e.g. through a
+		 * GUP pin: that may be any byte of it.
+		 */
+		ceph_folio_dirty_whole(folio);
 		ceph_blog_exit(&__ji);
 		return false;
 	}
@@ -158,8 +312,24 @@ static void ceph_invalidate_folio(struct folio *folio, size_t offset,
 
 
 	if (offset != 0 || length != folio_size(folio)) {
+		struct ceph_dirty_range *dr = __ceph_dirty_range(folio->private);
+
 		boutc(cl, "%llx.%llx idx %lu partial dirty page %zu~%zu\n",
 		      ceph_vinop(inode), folio->index, offset, length);
+		/*
+		 * A truncate (or a hole punched up to the end of the folio)
+		 * drops the tail: keep the dirty range inside what is left,
+		 * or, if nothing of it is, the folio is no longer dirty.  It
+		 * must not go out whole: the bytes in front of the range may
+		 * be stale here.
+		 */
+		if (dr && !READ_ONCE(dr->whole) &&
+		    offset + length == folio_size(folio)) {
+			dr->end = min_t(unsigned int, dr->end, offset);
+			if (dr->start >= dr->end &&
+			    folio_clear_dirty_for_io(folio))
+				ceph_folio_drop_dirty(inode, folio);
+		}
 		ceph_blog_exit(&__ji);
 		return;
 	}
@@ -169,7 +339,7 @@ static void ceph_invalidate_folio(struct folio *folio, size_t offset,
 		boutc(cl, "%llx.%llx idx %lu full dirty page\n",
 		      ceph_vinop(inode), folio->index);
 
-		snapc = folio_detach_private(folio);
+		snapc = ceph_folio_detach_snapc(folio);
 		ceph_put_wrbuffer_cap_refs(ci, 1, snapc);
 		ceph_put_snap_context(snapc);
 	}
@@ -639,8 +809,17 @@ static void ceph_fscache_write_to_cache(struct inode *inode, u64 off, u64 len, b
 {
 	struct ceph_inode_info *ci = ceph_inode(inode);
 	struct fscache_cookie *cookie = ceph_fscache_cookie(ci);
+	u64 start = round_down(off, PAGE_SIZE);
 
-	fscache_write_to_cache(cookie, inode->i_mapping, off, len, i_size_read(inode),
+	/*
+	 * The extent of a lazy I/O dirty range may start inside a page,
+	 * and the cache rejects that, leaving its old copy of the page to
+	 * be read back.  Write the cache whole pages, as the page cache
+	 * holds them: the cache only serves this client, and is
+	 * invalidated along with its page cache.
+	 */
+	fscache_write_to_cache(cookie, inode->i_mapping, start, off + len - start,
+			       i_size_read(inode),
 			       ceph_fscache_write_terminated, inode, true, caching);
 }
 #else
@@ -807,6 +986,7 @@ static int write_folio_nounlock(struct folio *folio,
 	loff_t page_off = folio_pos(folio);
 	int err;
 	loff_t len = folio_size(folio);
+	size_t start, end;
 	loff_t wlen;
 	struct ceph_writeback_ctl ceph_wbc;
 	struct ceph_osd_client *osdc = &fsc->client->osdc;
@@ -847,6 +1027,17 @@ static int write_folio_nounlock(struct folio *folio,
 		return 0;
 	}
 
+	/* only the dirty range of the folio goes out */
+	ceph_folio_dirty_range(folio, &start, &end);
+	if (page_off + start >= ceph_wbc.i_size) {
+		boutc(cl, "%llx.%llx folio at %lu dirty range beyond eof %llu\n",
+		      ceph_vinop(inode), folio->index, ceph_wbc.i_size);
+		ceph_folio_drop_dirty(inode, folio);
+		return 0;
+	}
+	page_off += start;
+	len = end - start;
+
 	if (ceph_wbc.i_size < page_off + len)
 		len = ceph_wbc.i_size - page_off;
 
@@ -899,9 +1090,10 @@ static int write_folio_nounlock(struct folio *folio,
 	}
 
 	/* it may be a short write due to an object boundary */
-	WARN_ON_ONCE(len > folio_size(folio));
+	WARN_ON_ONCE(start + len > folio_size(folio));
 	page = bounce_page ? bounce_page : &folio->page;
-	osd_req_op_extent_osd_data_pages(req, 0, &page, wlen, 0, false, false);
+	osd_req_op_extent_osd_data_pages(req, 0, &page, wlen, start, false,
+					 false);
 	boutc(cl, "%llx.%llx %llu~%llu (%llu bytes, %sencrypted)\n",
 	      ceph_vinop(inode), page_off, len, wlen,
 	      IS_ENCRYPTED(inode) ? "" : "not ");
@@ -947,7 +1139,7 @@ static int write_folio_nounlock(struct folio *folio,
 		      ceph_vinop(inode), folio);
 		err = 0;  /* vfs expects us to return 0 */
 	}
-	oldest = folio_detach_private(folio);
+	oldest = ceph_folio_detach_snapc(folio);
 	WARN_ON_ONCE(oldest != snapc);
 	folio_end_writeback(folio);
 	ceph_put_wrbuffer_cap_refs(ci, 1, snapc);
@@ -1036,7 +1228,7 @@ static void writepages_finish(struct ceph_osd_request *req)
 					fsc->mount_options->congestion_kb))
 				fsc->write_congested = false;
 
-			ceph_put_snap_context(folio_detach_private(folio));
+			ceph_put_snap_context(ceph_folio_detach_snapc(folio));
 			folio_end_writeback(folio);
 
 			if (atomic64_dec_return(&mdsc->dirty_folios) <= 0) {
@@ -1278,6 +1470,30 @@ int ceph_check_folio_before_write(struct address_space *mapping,
 		return -ENODATA;
 	}
 
+	/*
+	 * A dirty range that a truncate moved EOF below (before the page
+	 * cache got truncated): nothing of it is to be written, and the
+	 * clean bytes in front of it, which may be zeros or stale data of
+	 * another lazy I/O writer, must not go out either.  The head's EOF
+	 * is read now, not when this pass began: writes that extended the
+	 * file since then (into this folio too, which is locked now) must
+	 * not look like a truncate.
+	 */
+	{
+		loff_t isize = ceph_wbc->size_stable ? ceph_wbc->i_size :
+						       i_size_read(inode);
+		size_t start, end;
+
+		ceph_folio_dirty_range(folio, &start, &end);
+		if (folio_pos(folio) + start >= isize) {
+			boutc(cl, "folio at %lu dirty range beyond eof %llu\n",
+			      folio->index, isize);
+			if (folio_clear_dirty_for_io(folio))
+				ceph_folio_drop_dirty(inode, folio);
+			return -ENODATA;
+		}
+	}
+
 	if (ceph_wbc->strip_unit_end &&
 	    (folio->index > ceph_wbc->strip_unit_end)) {
 		boutc(cl, "end of strip unit %p\n", folio);
@@ -1326,11 +1542,25 @@ void ceph_allocate_page_array(struct address_space *mapping,
 	ceph_wbc->len = 0;
 }
 
+/* The file range writeback sends of a dirty folio: [*start, *end) */
+static void ceph_folio_write_range(const struct folio *folio,
+				   u64 *start, u64 *end)
+{
+	size_t s, e;
+
+	ceph_folio_dirty_range(folio, &s, &e);
+	*start = folio_pos(folio) + s;
+	*end = folio_pos(folio) + e;
+}
+
 static inline
 bool is_folio_index_contiguous(const struct ceph_writeback_ctl *ceph_wbc,
 			      const struct folio *folio)
 {
-	return folio->index == (ceph_wbc->offset + ceph_wbc->len) >> PAGE_SHIFT;
+	u64 start, end;
+
+	ceph_folio_write_range(folio, &start, &end);
+	return start == ceph_wbc->offset + ceph_wbc->len;
 }
 
 static inline
@@ -1395,6 +1625,7 @@ void ceph_process_folio_batch(struct address_space *mapping,
 	struct ceph_fs_client *fsc = ceph_inode_to_fs_client(inode);
 	struct ceph_client *cl = fsc->client;
 	struct folio *folio = NULL;
+	u64 start, end;
 	unsigned i;
 	int rc;
 
@@ -1435,6 +1666,18 @@ void ceph_process_folio_batch(struct address_space *mapping,
 			break;
 		}
 
+		/*
+		 * Nor may it need an extent beyond the request's ops: check
+		 * that before the folio is cleaned, as redirtying it would
+		 * lose its dirty range.
+		 */
+		if (ceph_wbc->locked_pages &&
+		    !is_folio_index_contiguous(ceph_wbc, folio) &&
+		    is_num_ops_too_big(ceph_wbc)) {
+			folio_unlock(folio);
+			break;
+		}
+
 		if (!folio_clear_dirty_for_io(folio)) {
 			boutc(cl, "%p !folio_clear_dirty_for_io\n", folio);
 			folio_unlock(folio);
@@ -1451,15 +1694,12 @@ void ceph_process_folio_batch(struct address_space *mapping,
 		 */
 		if (ceph_wbc->locked_pages == 0) {
 			ceph_allocate_page_array(mapping, ceph_wbc, folio);
+			/* the first op starts where the folio's range does */
+			ceph_folio_write_range(folio, &ceph_wbc->offset, &end);
 		} else if (!is_folio_index_contiguous(ceph_wbc, folio)) {
-			if (is_num_ops_too_big(ceph_wbc)) {
-				folio_redirty_for_writepage(wbc, folio);
-				folio_unlock(folio);
-				break;
-			}
-
 			ceph_wbc->num_ops++;
-			ceph_wbc->offset = (u64)folio_pos(folio);
+			ceph_folio_write_range(folio, &ceph_wbc->offset,
+					       &end);
 			ceph_wbc->len = 0;
 		}
 
@@ -1483,7 +1723,8 @@ void ceph_process_folio_batch(struct address_space *mapping,
 			fsc->write_congested = true;
 
 		ceph_wbc->fbatch.folios[i] = NULL;
-		ceph_wbc->len += folio_size(folio);
+		ceph_folio_write_range(folio, &start, &end);
+		ceph_wbc->len += end - start;
 	}
 
 	ceph_wbc->processed_in_fbatch = i;
@@ -1511,7 +1752,7 @@ void ceph_shift_unused_folios_left(struct folio_batch *fbatch)
 
 static void ceph_undo_wrbuffer_claim(struct inode *inode, struct folio *folio)
 {
-	struct ceph_snap_context *snapc = folio_detach_private(folio);
+	struct ceph_snap_context *snapc = ceph_folio_detach_snapc(folio);
 
 	if (!snapc)
 		return;
@@ -1532,12 +1773,13 @@ int ceph_submit_write(struct address_space *mapping,
 	struct ceph_osd_request *req = NULL;
 	struct folio *folio = NULL;
 	bool caching = ceph_is_cache_enabled(inode);
-	u64 offset;
+	u64 offset, start, end, last_len = 0;
 	u64 len;
-	unsigned i;
+	unsigned int i, align;
 
 new_request:
-	offset = ceph_fscrypt_folio_offset(page_folio(ceph_wbc->pages[0]));
+	folio = ceph_fscrypt_pagecache_folio(page_folio(ceph_wbc->pages[0]));
+	ceph_folio_write_range(folio, &offset, &end);
 	len = ceph_wbc->wsize;
 
 	req = ceph_osdc_new_request(&fsc->client->osdc,
@@ -1561,8 +1803,10 @@ int ceph_submit_write(struct address_space *mapping,
 		BUG_ON(IS_ERR(req));
 	}
 
-	folio = page_folio(ceph_wbc->pages[ceph_wbc->locked_pages - 1]);
-	BUG_ON(len < ceph_fscrypt_folio_offset(folio) + folio_size(folio) - offset);
+	folio = ceph_fscrypt_pagecache_folio(
+			page_folio(ceph_wbc->pages[ceph_wbc->locked_pages - 1]));
+	ceph_folio_write_range(folio, &start, &end);
+	BUG_ON(len < end - offset);
 
 	if (!ceph_inc_osd_stopping_blocker(fsc->mdsc)) {
 		for (i = 0; i < ceph_wbc->locked_pages; i++) {
@@ -1602,11 +1846,12 @@ int ceph_submit_write(struct address_space *mapping,
 	len = 0;
 	ceph_wbc->data_pages = ceph_wbc->pages;
 	ceph_wbc->op_idx = 0;
+	align = offset_in_page(offset);
 	for (i = 0; i < ceph_wbc->locked_pages; i++) {
 		u64 cur_offset;
 
 		folio = ceph_fscrypt_pagecache_folio(page_folio(ceph_wbc->pages[i]));
-		cur_offset = folio_pos(folio);
+		ceph_folio_write_range(folio, &cur_offset, &end);
 
 		/*
 		 * Discontinuity in page range? Ceph can handle that by just passing
@@ -1628,13 +1873,14 @@ int ceph_submit_write(struct address_space *mapping,
 
 			osd_req_op_extent_osd_data_pages(req, ceph_wbc->op_idx,
 							 ceph_wbc->data_pages,
-							 len, 0,
+							 len, align,
 							 ceph_wbc->from_pool,
 							 false);
 			osd_req_op_extent_update(req, ceph_wbc->op_idx, len);
 
 			len = 0;
 			offset = cur_offset;
+			align = offset_in_page(offset);
 			ceph_wbc->data_pages = ceph_wbc->pages + i;
 			ceph_wbc->op_idx++;
 		}
@@ -1644,7 +1890,8 @@ int ceph_submit_write(struct address_space *mapping,
 		if (caching)
 			ceph_folio_start_fscache(folio);
 
-		len += folio_size(folio);
+		last_len = end - cur_offset;
+		len += last_len;
 	}
 
 	ceph_fscache_write_to_cache(inode, offset, len, caching);
@@ -1655,10 +1902,11 @@ int ceph_submit_write(struct address_space *mapping,
 		/* writepages_finish() clears writeback pages
 		 * according to the data length, so make sure
 		 * data length covers all locked pages */
-		u64 min_len = len + 1 - folio_size(folio);
-		len = get_writepages_data_length(inode,
+		u64 min_len = len + 1 - last_len;
+
+		len = min(len, get_writepages_data_length(inode,
 						 page_folio(ceph_wbc->pages[i - 1]),
-						 offset);
+						 offset));
 		len = max(len, min_len);
 	}
 
@@ -1676,7 +1924,7 @@ int ceph_submit_write(struct address_space *mapping,
 
 	osd_req_op_extent_osd_data_pages(req, ceph_wbc->op_idx,
 					 ceph_wbc->data_pages, len,
-					 0, ceph_wbc->from_pool, false);
+					 align, ceph_wbc->from_pool, false);
 	osd_req_op_extent_update(req, ceph_wbc->op_idx, len);
 
 	BUG_ON(ceph_wbc->op_idx + 1 != req->r_num_ops);
@@ -1731,8 +1979,14 @@ void ceph_wait_until_current_writes_complete(struct address_space *mapping,
 						     PAGECACHE_TAG_WRITEBACK,
 						     &ceph_wbc->fbatch))) {
 			for (i = 0; i < nr; i++) {
+				struct ceph_snap_context *snapc;
+
 				folio = ceph_wbc->fbatch.folios[i];
-				if (ceph_folio_snap_context(folio) != ceph_wbc->snapc)
+				/* not locked: the range may go away meanwhile */
+				rcu_read_lock();
+				snapc = ceph_folio_snap_context(folio);
+				rcu_read_unlock();
+				if (snapc != ceph_wbc->snapc)
 					continue;
 				folio_wait_writeback(folio);
 			}
@@ -1992,6 +2246,29 @@ static int ceph_netfs_check_write_begin(struct file *file, loff_t pos, unsigned
 	return 0;
 }
 
+static bool ceph_file_is_lazy(const struct file *file)
+{
+	return ((struct ceph_file_info *)file->private_data)->fmode &
+	       CEPH_FILE_MODE_LAZY;
+}
+
+/*
+ * Would a write of [@pos, @pos + @len) into @folio leave clean bytes
+ * between it and the folio's dirty range?  The range would then grow over
+ * them, and writeback would send them too: with lazy I/O they may be stale
+ * here, another client's data that this one never wrote.
+ */
+static bool ceph_folio_write_leaves_gap(const struct folio *folio,
+					loff_t pos, size_t len)
+{
+	struct ceph_dirty_range *dr = __ceph_dirty_range(folio->private);
+	size_t start = offset_in_folio(folio, pos);
+
+	if (!folio_test_dirty(folio) || !dr || dr->whole)
+		return false;
+	return start + len < dr->start || start > dr->end;
+}
+
 /*
  * We are only allowed to write into/dirty the page if the page is
  * clean, or already dirty within the same snap context.
@@ -2005,15 +2282,41 @@ static int ceph_write_begin(const struct kiocb *iocb,
 	struct inode *inode = file_inode(file);
 	struct ceph_fs_client *fsc = ceph_inode_to_fs_client(inode);
 	struct ceph_inode_info *ci = ceph_inode(inode);
+	bool lazy = ceph_file_is_lazy(file);
 	int r;
 	struct ceph_journal_info __ji;
 
 	ceph_blog_enter(fsc, &__ji);
 
-	r = netfs_write_begin(&ci->netfs, file, inode->i_mapping, pos, len, foliop, NULL);
-	if (r < 0) {
-		ceph_blog_exit(&__ji);
-		return r;
+	for (;;) {
+		struct folio *folio;
+		loff_t fpos, fend;
+
+		r = netfs_write_begin(&ci->netfs, file, inode->i_mapping, pos,
+				      len, foliop, NULL);
+		if (r < 0) {
+			ceph_blog_exit(&__ji);
+			return r;
+		}
+		folio = *foliop;
+		if (!lazy || !ceph_folio_write_leaves_gap(folio, pos, len))
+			break;
+
+		/*
+		 * A lazy I/O write apart from the folio's dirty range:
+		 * write the folio back first, so that its range never
+		 * spans bytes this client did not write.
+		 */
+		fpos = folio_pos(folio);
+		fend = fpos + folio_size(folio) - 1;
+		folio_unlock(folio);
+		folio_put(folio);
+		*foliop = NULL;
+		r = filemap_write_and_wait_range(mapping, fpos, fend);
+		if (r < 0) {
+			ceph_blog_exit(&__ji);
+			return r;
+		}
 	}
 
 	folio_wait_private_2(*foliop); /* [DEPRECATED] */
@@ -2035,7 +2338,7 @@ static int ceph_write_end(const struct kiocb *iocb,
 	struct inode *inode = file_inode(file);
 	struct ceph_fs_client *fsc = ceph_inode_to_fs_client(inode);
 	struct ceph_client *cl = ceph_inode_to_client(inode);
-	bool check_cap = false;
+	bool check_cap = false, was_dirty, lazy = ceph_file_is_lazy(file);
 	struct ceph_journal_info __ji;
 
 	ceph_blog_enter_gfp(fsc, &__ji, GFP_ATOMIC);
@@ -2052,11 +2355,52 @@ static int ceph_write_end(const struct kiocb *iocb,
 		folio_mark_uptodate(folio);
 	}
 
+	/*
+	 * Nothing copied (the user buffer faulted; the write is retried):
+	 * dirtying the folio now would give it no dirty range, and it
+	 * would go out as a whole.
+	 */
+	if (!copied)
+		goto out;
+
+	/*
+	 * A short copy of a lazy I/O write that ceph_write_begin() found
+	 * next to the dirty range may still stop short of it: say nothing
+	 * was copied, and the write is retried (and checked) again.
+	 */
+	if (lazy && ceph_folio_write_leaves_gap(folio, pos, copied)) {
+		copied = 0;
+		goto out;
+	}
+
 	/* did file size increase? */
 	if (pos+copied > i_size_read(inode))
 		check_cap = ceph_inode_set_size(inode, pos+copied);
 
-	folio_mark_dirty(folio);
+	/*
+	 * A dirty folio only gets its dirty range widened, and only a lazy
+	 * I/O write starts one: a clean folio dirtied without lazy I/O
+	 * goes out whole, with nothing to note.
+	 */
+	was_dirty = folio_test_dirty(folio);
+	if (!was_dirty) {
+		/*
+		 * A writable pin (GUP) on the folio may be older than its
+		 * last writeback, and may write any byte of it.  Its unpin
+		 * dirties the folio only if it finds it clean, so look for
+		 * the pin before dirtying it: an unpin that has found it
+		 * clean waits for the folio lock with the pin still counted,
+		 * and one that finished before found it clean and dirtied it
+		 * as a whole.  A pin taken from now on write-faults first, in
+		 * ceph_page_mkwrite(), which makes the range whole.
+		 */
+		if (lazy && folio_maybe_dma_pinned(folio))
+			lazy = false;
+		folio_mark_dirty(folio);
+	}
+	if (was_dirty || lazy)
+		ceph_folio_note_write(inode, folio, was_dirty, pos, copied,
+				      lazy);
 
 out:
 	folio_unlock(folio);
@@ -2395,6 +2739,7 @@ static vm_fault_t ceph_page_mkwrite(struct vm_fault *vmf)
 		if (!snapc) {
 			/* success.  we'll keep the folio locked. */
 			folio_mark_dirty(folio);
+			ceph_folio_dirty_whole(folio);
 			ret = VM_FAULT_LOCKED;
 			break;
 		}

-- 
2.53.0

