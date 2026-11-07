From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 07 Nov 2026 03:51:27 +0100
Subject: [PATCH 1/2] ceph: don't read a folio in for a partial lazy I/O
 write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-ceph-lazyio-noread-v1-1-d04369c70ab7@clyso.com>
References: <20261107-ceph-lazyio-noread-v1-0-d04369c70ab7@clyso.com>
In-Reply-To: <20261107-ceph-lazyio-noread-v1-0-d04369c70ab7@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794019887; l=11624;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Ny2BjT9xaaNusyZ9ywvf2oZMGMLPZCsix6kOeCz7BGk=;
 b=p+Mnb+SdXhYML4Dm6+wEj4w8k7XQ0Z9EkaDuaNscc9/RJPtGSBn6/FaoIKtNv3nhdM9A9Fr5Y
 j1plm4Qkf16CVtEr02iJ1JIVRcSQdocR+S1B5qX+Qf2/B6hP1aNJfOC
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A buffered write into part of a folio that is not uptodate reads the
folio from the OSDs first, synchronously, under the inode's i_rwsem.
With lazy I/O that read buys nothing: only the dirty range of such a
folio goes out on writeback, and the bytes around it may be another
client's data, stale here anyway.  But it serialises every writer of
the file on this client behind one OSD round trip per unaligned edge.

Several processes per client writing small unaligned records of one
shared file spend most of their time this way: in a 60 s sample of 16
writers on 4 clients, 75% of the time in ceph_write_iter() went to
waiting for i_rwsem, and 88% of the time it was held went to these
reads.

Leave such a folio not uptodate instead, with only its dirty range
valid.  A later write next to the range widens it as before; one apart
from it writes the folio back first, as before.  Anything that reads
the folio (read_folio, or netfs_write_begin() for a write that is not
lazy) writes it back first, so it is read whole from the OSDs, and the
writeback completion no longer warns about it.  Encrypted inodes and
inodes with fscache keep reading the folio.

16 writers on 4 lazyio mounts, each writing 47008-byte records
interleaved with the others' into one shared file (IOR, -t 47008
-b 47008), mean of 2 runs each, data read back and verified:

+--------------------+-------+---------+---------+---------+
| metric             | unit  |    base |   patch | speedup |
+--------------------+-------+---------+---------+---------+
| write bandwidth    | GiB/s |   0.272 |   0.710 |   2.61x |
| data check         |       |    PASS |    PASS |         |
+--------------------+-------+---------+---------+---------+

write() latency in ms:

+-------+-----+-----+-----+-------+---------+-----------+------+
|       | p50 | p90 | p95 | p99   | p99.9   | p99.99    | max  |
+-------+-----+-----+-----+-------+---------+-----------+------+
| base  | 0.5 | 3.1 | 3.5 | 5.5   | 131-262 | 1049-2097 | 8314 |
| patch | 0.2 | 0.2 | 0.2 | 16-33 | 66-131  | 524-1049  | 6326 |
+-------+-----+-----+-----+-------+---------+-----------+------+

p99 is higher because the writers now reach the dirty limit: a writer
throttled in balance_dirty_pages() holds i_rwsem, and the other writers
of the file wait for it.

Writes that cover whole folios, and writes that do not use lazy I/O,
take the same path as before.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c | 163 ++++++++++++++++++++++++++++++++++++++++++++++++++++-----
 1 file changed, 150 insertions(+), 13 deletions(-)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index b0f06d21ca72..e33d39a5a373 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -176,7 +176,8 @@ static void ceph_folio_dirty_whole(struct folio *folio)
 /*
  * Note a write of @copied bytes at @pos into @folio, which it has just
  * dirtied; @was_dirty: the folio already was dirty before; @lazy: the
- * write came through a lazy I/O open.
+ * write came through a lazy I/O open; *@prealloc: a range to use instead
+ * of allocating one, taken (set to NULL) if used.
  *
  * Only a lazy I/O write starts a range: without lazy I/O this client
  * holds the buffer cap, the rest of the page is current, and it may go
@@ -187,7 +188,8 @@ static void ceph_folio_dirty_whole(struct folio *folio)
  */
 static void ceph_folio_note_write(struct inode *inode, struct folio *folio,
 				  bool was_dirty, loff_t pos,
-				  unsigned int copied, bool lazy)
+				  unsigned int copied, bool lazy,
+				  struct ceph_dirty_range **prealloc)
 {
 	struct ceph_dirty_range *dr = __ceph_dirty_range(folio->private);
 	unsigned int start = offset_in_folio(folio, pos);
@@ -211,7 +213,10 @@ static void ceph_folio_note_write(struct inode *inode, struct folio *folio,
 		return;
 	if (!start && end >= folio_size(folio))
 		return;
-	dr = kmalloc_obj(*dr, GFP_NOFS);
+	dr = *prealloc;
+	*prealloc = NULL;
+	if (!dr)
+		dr = kmalloc_obj(*dr, GFP_NOFS);
 	if (!dr)
 		return;		/* then it all goes out */
 	dr->snapc = folio_get_private(folio);
@@ -1287,7 +1292,8 @@ static void writepages_finish(struct ceph_osd_request *req)
 				fscrypt_free_bounce_page(osd_data->pages[j]);
 				osd_data->pages[j] = &folio->page;
 			}
-			WARN_ON(!folio_test_uptodate(folio));
+			WARN_ON(!folio_test_uptodate(folio) &&
+				!__ceph_dirty_range(folio->private));
 
 			if (atomic_long_dec_return(&fsc->writeback_count) <
 			     CONGESTION_OFF_THRESH(
@@ -2281,8 +2287,12 @@ ceph_find_incompatible(struct folio *folio)
 	return NULL;
 }
 
-static int ceph_netfs_check_write_begin(struct file *file, uoff_t pos, unsigned int len,
-					struct folio **foliop, void **_fsdata)
+/*
+ * Wait until the locked *@foliop may be dirtied in the current snap
+ * context.  If that means dropping it, *@foliop is cleared and 0 (or an
+ * error) returned: the caller grabs the folio again and rechecks it.
+ */
+static int __ceph_check_write_begin(struct file *file, struct folio **foliop)
 {
 	struct inode *inode = file_inode(file);
 	struct ceph_inode_info *ci = ceph_inode(inode);
@@ -2312,6 +2322,94 @@ static int ceph_netfs_check_write_begin(struct file *file, uoff_t pos, unsigned
 	return 0;
 }
 
+/*
+ * Unlock a dirty folio that is not uptodate, and write it back: only its
+ * dirty range is valid (see ceph_write_begin_noread()), so it has to go
+ * out before the folio is read.
+ */
+static int ceph_writeback_partial_folio(struct folio *folio)
+{
+	struct address_space *mapping = folio->mapping;
+	loff_t start = folio_pos(folio);
+	loff_t end = start + folio_size(folio) - 1;
+
+	folio_unlock(folio);
+	return filemap_write_and_wait_range(mapping, start, end);
+}
+
+static int ceph_netfs_check_write_begin(struct file *file, uoff_t pos, unsigned int len,
+					struct folio **foliop, void **_fsdata)
+{
+	if (!folio_test_uptodate(*foliop) && folio_test_dirty(*foliop)) {
+		struct folio *folio = *foliop;
+		int r;
+
+		/* netfs_write_begin() would read it over the dirty range */
+		*foliop = NULL;
+		r = ceph_writeback_partial_folio(folio);
+		folio_put(folio);
+		return r;
+	}
+	return __ceph_check_write_begin(file, foliop);
+}
+
+/*
+ * A lazy I/O write into part of a folio that is not uptodate: grab the
+ * folio without reading it from the OSDs first.  Its other bytes may be
+ * another client's data here, so they would be stale anyway, and only
+ * the dirty range of the folio goes out on writeback.  The folio stays
+ * not uptodate, with only its dirty range valid, until it is written
+ * back or ceph_read_folio() writes it back to read it whole.
+ *
+ * *@drp is the dirty range for ceph_write_end(), allocated here.
+ * Returns 1 with *@foliop locked, 0 if the folio has to be read as
+ * usual, or an error.
+ */
+static int ceph_write_begin_noread(struct file *file,
+				   struct address_space *mapping, loff_t pos,
+				   unsigned int len, struct folio **foliop,
+				   struct ceph_dirty_range **drp)
+{
+	struct inode *inode = mapping->host;
+	struct folio *folio;
+	size_t offset;
+	int r;
+
+	if (IS_ENCRYPTED(inode) || ceph_is_cache_enabled(inode))
+		return 0;
+	if (!*drp) {
+		*drp = kmalloc_obj(**drp, GFP_NOFS);
+		if (!*drp)
+			return 0;
+	}
+	for (;;) {
+		folio = __filemap_get_folio(mapping, pos >> PAGE_SHIFT,
+					    FGP_WRITEBEGIN,
+					    mapping_gfp_mask(mapping));
+		if (IS_ERR(folio))
+			return PTR_ERR(folio);
+		offset = offset_in_folio(folio, pos);
+		if (folio_test_uptodate(folio) ||
+		    (!offset && len >= folio_size(folio))) {
+			folio_unlock(folio);
+			folio_put(folio);
+			return 0;
+		}
+		r = __ceph_check_write_begin(file, &folio);
+		if (r < 0) {
+			if (folio) {
+				folio_unlock(folio);
+				folio_put(folio);
+			}
+			return r;
+		}
+		if (folio)
+			break;
+	}
+	*foliop = folio;
+	return 1;
+}
+
 static bool ceph_file_is_lazy(const struct file *file)
 {
 	return ((struct ceph_file_info *)file->private_data)->fmode &
@@ -2348,22 +2446,32 @@ static int ceph_write_begin(const struct kiocb *iocb,
 	struct inode *inode = file_inode(file);
 	struct ceph_fs_client *fsc = ceph_inode_to_fs_client(inode);
 	struct ceph_inode_info *ci = ceph_inode(inode);
-	bool lazy = ceph_file_is_lazy(file);
+	struct ceph_dirty_range *dr = NULL;
+	bool lazy = ceph_file_is_lazy(file), noread = false;
 	int r;
 	struct ceph_journal_info __ji;
 
 	ceph_blog_enter(fsc, &__ji);
 
+	*fsdata = NULL;
 	for (;;) {
 		struct folio *folio;
 		loff_t fpos, fend;
 
-		r = netfs_write_begin(&ci->netfs, file, inode->i_mapping, pos,
-				      len, foliop, NULL);
+		r = 0;
+		if (lazy)
+			r = ceph_write_begin_noread(file, mapping, pos, len,
+						    foliop, &dr);
+		if (!r)
+			r = netfs_write_begin(&ci->netfs, file,
+					      inode->i_mapping, pos, len,
+					      foliop, NULL);
 		if (r < 0) {
+			kfree(dr);
 			ceph_blog_exit(&__ji);
 			return r;
 		}
+		noread = r > 0;
 		folio = *foliop;
 		if (!lazy || !ceph_folio_write_leaves_gap(folio, pos, len))
 			break;
@@ -2380,12 +2488,19 @@ static int ceph_write_begin(const struct kiocb *iocb,
 		*foliop = NULL;
 		r = filemap_write_and_wait_range(mapping, fpos, fend);
 		if (r < 0) {
+			kfree(dr);
 			ceph_blog_exit(&__ji);
 			return r;
 		}
 	}
 
-	folio_wait_private_2(*foliop); /* [DEPRECATED] */
+	if (noread) {
+		/* not read: ceph_write_end() starts or widens the range */
+		*fsdata = dr;
+	} else {
+		kfree(dr);
+		folio_wait_private_2(*foliop); /* [DEPRECATED] */
+	}
 	WARN_ON_ONCE(!folio_test_locked(*foliop));
 	ceph_blog_exit(&__ji);
 	return 0;
@@ -2404,6 +2519,7 @@ static int ceph_write_end(const struct kiocb *iocb,
 	struct inode *inode = file_inode(file);
 	struct ceph_fs_client *fsc = ceph_inode_to_fs_client(inode);
 	struct ceph_client *cl = ceph_inode_to_client(inode);
+	struct ceph_dirty_range *dr = fsdata;
 	bool check_cap = false, was_dirty, lazy = ceph_file_is_lazy(file);
 	struct ceph_journal_info __ji;
 
@@ -2418,7 +2534,9 @@ static int ceph_write_end(const struct kiocb *iocb,
 			copied = 0;
 			goto out;
 		}
-		folio_mark_uptodate(folio);
+		/* not read by ceph_write_begin_noread(): only the range is valid */
+		if (!dr)
+			folio_mark_uptodate(folio);
 	}
 
 	/*
@@ -2466,9 +2584,12 @@ static int ceph_write_end(const struct kiocb *iocb,
 	}
 	if (was_dirty || lazy)
 		ceph_folio_note_write(inode, folio, was_dirty, pos, copied,
-				      lazy);
+				      lazy, &dr);
+	WARN_ON_ONCE(!folio_test_uptodate(folio) &&
+		     !__ceph_dirty_range(folio->private));
 
 out:
+	kfree(dr);
 	folio_unlock(folio);
 	folio_put(folio);
 
@@ -2479,8 +2600,24 @@ static int ceph_write_end(const struct kiocb *iocb,
 	return copied;
 }
 
+/*
+ * A dirty folio that is not uptodate has only its dirty range valid (see
+ * ceph_write_begin_noread()): write it back before reading it whole.
+ */
+static int ceph_read_folio(struct file *file, struct folio *folio)
+{
+	int r;
+
+	if (unlikely(folio_test_dirty(folio))) {
+		/* the caller looks the folio up again */
+		r = ceph_writeback_partial_folio(folio);
+		return r < 0 ? r : AOP_TRUNCATED_PAGE;
+	}
+	return netfs_read_folio(file, folio);
+}
+
 const struct address_space_operations ceph_aops = {
-	.read_folio = netfs_read_folio,
+	.read_folio = ceph_read_folio,
 	.readahead = netfs_readahead,
 	.writepages = ceph_writepages_start,
 	.write_begin = ceph_write_begin,

-- 
2.53.0

