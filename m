From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Sun, 22 Nov 2026 19:19:42 +0100
Subject: [PATCH 6/7] ntfs: zero new delalloc clusters even when writeback
 allocates them
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-ntfs-delalloc-fixes-v1-6-0726f0dce403@proton.me>
References: <20261122-b4-ntfs-delalloc-fixes-v1-0-0726f0dce403@proton.me>
In-Reply-To: <20261122-b4-ntfs-delalloc-fixes-v1-0-0726f0dce403@proton.me>
To: Namjae Jeon <linkinjeon@kernel.org>, Hyunchul Lee <hyc.lee@gmail.com>, 
 Baolin Liu <liubaolin12138@163.com>
Cc: ntfs@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Zhan Xusheng <zhanxusheng1024@gmail.com>, stable@vger.kernel.org, 
 Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=9573;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=XEJQKTLIixRNBY3im1HoKIxgT03eHpIBNJyLu/JSGrU=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmxmI0u7b9dz9l2YezflCouk23Pl3exfz7NOe5q9ZIWoz
 OQPWnmqHaUsDGJcDLJiiiwd/2+E+IR8+7QsTqsPZg4rE8gQBi5OAZhI5EVGhstRM9wrDx8X01xc
 VvAzwzHVdj7jxt2xvpciPWKfzjD/Wc7wvy5mXtGNE7fnbpHcMulnguex0xaCb+vc9Rb/XdkUERz
 3jREA
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a buffered write starts or ends inside a cluster that is a hole,
ntfs_write_simple_iomap_begin_non_resident() turns the hole into an
LCN_DELALLOC run and then zeroes the part of the first and last cluster
that the write does not cover, in the page cache, so that writeback
writes whole clusters.  initialized_size already covers that part, and
the clusters writeback allocates are not zeroed on disk.

The zeroing runs after mrec_lock and the runlist lock are dropped, and
its ->iomap_valid() check, ntfs_iomap_valid(), calls the mapping stale
as soon as the run is no longer delalloc.  Writeback that runs meanwhile
(the background flusher, or FIEMAP_FLAG_SYNC and sync_file_range(),
which do not take the inode lock) picks up the folios that were zeroed
first, and ntfs_attr_map_cluster() allocates the whole delalloc run for
them.  iomap_zero_range() then stops with -EPERM from
ntfs_zero_read_iomap_end(), which the caller ignores.  The rest of the
cluster is neither in the page cache nor on disk, so reads return what
the reallocated clusters held before: data of deleted or truncated files.

Reproducer: fill a file, fsync, truncate it to 0 and back up, then write
small pieces at unaligned offsets into the holes while other threads
call FIEMAP with FIEMAP_FLAG_SYNC.  With 4 KiB and 64 KiB clusters the
old contents show up within seconds, also without the FIEMAP threads.

The validity check was there to keep the zeroing from overwriting data
that an mmap write put into the new cluster in that window.  Hold the
invalidate lock across ->iomap_begin() of a buffered write instead,
which keeps page faults out from the moment the hole becomes delalloc
until it is zeroed, and zero with the plain seek mapping, which zeroes
delalloc and mapped ranges alike, so that writeback allocating the run
no longer matters.  The error path of ->iomap_begin() now runs with the
invalidate lock held.

Fixes: b041ca562526 ("ntfs: update iomap and address space operations")
Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/ntfs/iomap.c | 127 ++++++++++++++++++++++++--------------------------------
 1 file changed, 55 insertions(+), 72 deletions(-)

diff --git a/fs/ntfs/iomap.c b/fs/ntfs/iomap.c
index 1909824c30..fd94d4b34f 100644
--- a/fs/ntfs/iomap.c
+++ b/fs/ntfs/iomap.c
@@ -297,39 +297,6 @@ static int ntfs_read_iomap_end(struct inode *inode, loff_t pos, loff_t length,
 DEFINE_IOMAP_ITER_NEXT_END(ntfs_read_iomap_next, ntfs_read_iomap_begin,
 		ntfs_read_iomap_end);
 
-/*
- * Check that the cached iomap still matches the NTFS runlist before
- * iomap_zero_range() is called. if the runlist changes while iomap is
- * iterating a cached iomap, iomap_zero_range() may overwrite folios
- * that have been already written with valid data.
- */
-static bool ntfs_iomap_valid(struct inode *inode, const struct iomap *iomap)
-{
-	struct ntfs_inode *ni = NTFS_I(inode);
-	struct runlist_element *rl;
-	s64 vcn, lcn;
-
-	if (!NInoNonResident(ni))
-		return false;
-
-	vcn = iomap->offset >> ni->vol->cluster_size_bits;
-
-	down_read(&ni->runlist.lock);
-	rl = __ntfs_attr_find_vcn_nolock(&ni->runlist, vcn);
-	if (IS_ERR(rl)) {
-		up_read(&ni->runlist.lock);
-		return false;
-	}
-	lcn = ntfs_rl_vcn_to_lcn(rl, vcn);
-	up_read(&ni->runlist.lock);
-	return lcn == LCN_DELALLOC;
-}
-
-static const struct iomap_write_ops ntfs_zero_iomap_folio_ops = {
-	.put_folio = ntfs_iomap_put_folio,
-	.iomap_valid = ntfs_iomap_valid,
-};
-
 static int ntfs_seek_iomap_begin(struct inode *inode, loff_t offset, loff_t length,
 		unsigned int flags, struct iomap *iomap, struct iomap *srcmap)
 {
@@ -337,17 +304,6 @@ static int ntfs_seek_iomap_begin(struct inode *inode, loff_t offset, loff_t leng
 			srcmap, false, false);
 }
 
-static int ntfs_zero_read_iomap_end(struct inode *inode, loff_t pos, loff_t length,
-		ssize_t written, unsigned int flags, struct iomap *iomap)
-{
-	if ((flags & IOMAP_ZERO) && (iomap->flags & IOMAP_F_STALE))
-		return -EPERM;
-	return written;
-}
-
-static DEFINE_IOMAP_ITER_NEXT_END(ntfs_zero_read_iomap_next,
-		ntfs_seek_iomap_begin, ntfs_zero_read_iomap_end);
-
 DEFINE_IOMAP_ITER_NEXT(ntfs_seek_iomap_next, ntfs_seek_iomap_begin);
 
 int ntfs_dio_zero_range(struct inode *inode, loff_t offset, loff_t length)
@@ -362,19 +318,28 @@ int ntfs_dio_zero_range(struct inode *inode, loff_t offset, loff_t length)
 				     BLKDEV_ZERO_NOUNMAP);
 }
 
+/*
+ * Zero the part of a new delalloc cluster that the buffered write does not
+ * cover, in the page cache, so that writeback writes the whole cluster.
+ * Writeback can allocate the delalloc run while this runs (the folios
+ * zeroed first are dirty), so the zeroing must not depend on the mapping
+ * staying delalloc: iomap_zero_range() zeroes delalloc and mapped ranges
+ * alike.  The caller holds the invalidate lock, which keeps page faults
+ * from putting data into the cluster meanwhile.
+ */
 static int ntfs_zero_range(struct inode *inode, loff_t offset, loff_t length)
 {
-	return iomap_zero_range(inode,
-				offset, length,
-				NULL,
-				ntfs_zero_read_iomap_next,
-				&ntfs_zero_iomap_folio_ops,
+	lockdep_assert_held_write(&inode->i_mapping->invalidate_lock);
+
+	return iomap_zero_range(inode, offset, length, NULL,
+				ntfs_seek_iomap_next, &ntfs_iomap_folio_ops,
 				NULL);
 }
 
-static void ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
-					loff_t length, ssize_t written,
-					unsigned int flags, struct iomap *iomap);
+static void __ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
+					  loff_t length, ssize_t written,
+					  unsigned int flags,
+					  struct iomap *iomap);
 
 static int ntfs_write_simple_iomap_begin_non_resident(struct inode *inode, loff_t offset,
 						      loff_t length, struct iomap *iomap)
@@ -528,8 +493,7 @@ static int ntfs_write_simple_iomap_begin_non_resident(struct inode *inode, loff_
 							      z_start,
 							      z_end - z_start);
 			}
-			if ((!err || err == -EPERM) &&
-			    max_clu_count > 1 &&
+			if (!err && max_clu_count > 1 &&
 			    (iomap->length & vol->cluster_size_mask &&
 			     end < ni->initialized_size)) {
 				loff_t z_start, z_end;
@@ -544,16 +508,15 @@ static int ntfs_write_simple_iomap_begin_non_resident(struct inode *inode, loff_
 							      z_end - z_start);
 			}
 
-			if (err == -EPERM)
-				err = 0;
 			if (err) {
 				/*
 				 * Nothing will be copied: drop the delalloc
 				 * clusters that no zeroed folio covers.
 				 */
-				ntfs_write_delalloc_release(inode, offset,
-							    iomap->length, 0,
-							    IOMAP_WRITE, iomap);
+				__ntfs_write_delalloc_release(inode, offset,
+							      iomap->length, 0,
+							      IOMAP_WRITE,
+							      iomap);
 				return err;
 			}
 		}
@@ -721,16 +684,27 @@ static int ntfs_write_iomap_begin_non_resident(struct inode *inode, loff_t offse
 	struct ntfs_inode *mrec_ni = ntfs_inode_is_named_stream(ni) ?
 			ntfs_base_inode(ni) : ni;
 
-	mutex_lock(&mrec_ni->mrec_lock);
+	if (ntfs_iomap_flags & NTFS_IOMAP_FLAGS_BEGIN) {
+		int err;
 
-	if (ntfs_iomap_flags & NTFS_IOMAP_FLAGS_BEGIN)
-		return  ntfs_write_simple_iomap_begin_non_resident(inode, offset,
-								   length, iomap);
-	else
-		return ntfs_write_da_iomap_begin_non_resident(inode,
-							      offset, length,
-							      flags, iomap,
-							      ntfs_iomap_flags);
+		/*
+		 * A hole becomes delalloc here and the rest of its partial
+		 * clusters is zeroed after the locks below are dropped: keep
+		 * page faults, which could write into those clusters, out
+		 * until then.
+		 */
+		filemap_invalidate_lock(inode->i_mapping);
+		mutex_lock(&mrec_ni->mrec_lock);
+		err = ntfs_write_simple_iomap_begin_non_resident(inode, offset,
+								 length, iomap);
+		filemap_invalidate_unlock(inode->i_mapping);
+		return err;
+	}
+
+	mutex_lock(&mrec_ni->mrec_lock);
+	return ntfs_write_da_iomap_begin_non_resident(inode, offset, length,
+						      flags, iomap,
+						      ntfs_iomap_flags);
 }
 
 static int __ntfs_write_iomap_begin(struct inode *inode, loff_t offset,
@@ -802,9 +776,10 @@ static void ntfs_write_delalloc_punch(struct inode *inode, loff_t offset,
  * Punch them out again, keeping every cluster that has dirty data in the
  * page cache.
  */
-static void ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
-					loff_t length, ssize_t written,
-					unsigned int flags, struct iomap *iomap)
+static void __ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
+					  loff_t length, ssize_t written,
+					  unsigned int flags,
+					  struct iomap *iomap)
 {
 	struct ntfs_volume *vol = NTFS_I(inode)->vol;
 	loff_t start_byte, end_byte;
@@ -821,9 +796,17 @@ static void ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
 	if (start_byte >= end_byte)
 		return;
 
-	filemap_invalidate_lock(inode->i_mapping);
 	iomap_write_delalloc_release(inode, start_byte, end_byte, flags, iomap,
 				     ntfs_write_delalloc_punch);
+}
+
+static void ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
+					loff_t length, ssize_t written,
+					unsigned int flags, struct iomap *iomap)
+{
+	filemap_invalidate_lock(inode->i_mapping);
+	__ntfs_write_delalloc_release(inode, pos, length, written, flags,
+				      iomap);
 	filemap_invalidate_unlock(inode->i_mapping);
 }
 

-- 
2.56.1

