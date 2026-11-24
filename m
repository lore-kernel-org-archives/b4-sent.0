From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Tue, 24 Nov 2026 23:49:42 +0100
Subject: [PATCH v2 08/11] ntfs: punch out the delalloc reservation of a
 failed buffered write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-8-f394c800ec03@proton.me>
References: <20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me>
In-Reply-To: <20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me>
To: Namjae Jeon <linkinjeon@kernel.org>, Hyunchul Lee <hyc.lee@gmail.com>, 
 Baolin Liu <liubaolin12138@163.com>
Cc: Christian Brauner <brauner@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 "Darrick J. Wong" <djwong@kernel.org>, ntfs@lists.linux.dev, 
 linux-fsdevel@vger.kernel.org, linux-xfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 stable@vger.kernel.org, Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=9090;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=WjmcqW4CTNNPMSEnxBEJz80BbXZCjwdZk9DXABgswwc=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kQZGtYbKdw1/lb6tfM074cC/fJv/T4r3580V51UQj
 VwVbFnTUcrCIMbFICumyNLx/0aIT8i3T8vitPpg5rAygQxh4OIUgIk4nmb4w9ukK/C3oMb49yOf
 BHP3zBc/byb6lv7fKX1E7ctHEb8URUaGtvXfa7efsb7+ilGS8XL93ITVvOJX5Wrsz1XfTLpQfby
 FAQA=
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ntfs_write_simple_iomap_begin_non_resident() turns the holes a buffered
write covers into LCN_DELALLOC runs and reserves their clusters before
any data is copied.  If the copy then fails or comes up short (EFAULT
from the user buffer, a fatal signal), the clusters that no dirty folio
covers stay delalloc.  Writeback never allocates them, so the
reservation is kept until the inode is evicted, and the stale runs
survive the writeback that fallocate() relies on before it edits the
runlist.

Reproducer: a pwrite() of 512 KiB from an unmapped address into a hole
of a 1 MiB sparse file fails with EFAULT and leaves 128 (4 KiB) clusters
reserved after sync.  A FALLOC_FL_PUNCH_HOLE or COLLAPSE_RANGE through
the range then hits the run splitting bug fixed by the previous patch.

Do what XFS does: in ->iomap_end() of a delalloc mapping that was not
written completely, let iomap_write_delalloc_release() find the ranges
without dirty data and turn the clusters entirely inside them back into
holes, releasing their reservation.  Clusters that still hold dirty data
stay delalloc, including the partial first and last clusters of an
unaligned write that ->iomap_begin() zeroed in the page cache; those are
written back as zeros, as before.  Delalloc runs are holes on disk, so
the mapping pairs do not change.

The error path of ->iomap_begin() itself, taken when zeroing the edges
of the new run fails, only subtracted the reservation and left the run
and i_dealloc_clusters in place, so a later truncate or eviction would
release it a second time.  Use the same release there.

Fixes: b041ca562526 ("ntfs: update iomap and address space operations")
Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/ntfs/attrib.c | 63 +++++++++++++++++++++++++++++++++++++++++++++++++
 fs/ntfs/attrib.h |  1 +
 fs/ntfs/iomap.c  | 71 +++++++++++++++++++++++++++++++++++++++++++++++++++++++-
 3 files changed, 134 insertions(+), 1 deletion(-)

diff --git a/fs/ntfs/attrib.c b/fs/ntfs/attrib.c
index f604a42673..cc24259fb6 100644
--- a/fs/ntfs/attrib.c
+++ b/fs/ntfs/attrib.c
@@ -4416,6 +4416,69 @@ void ntfs_release_delalloc_from(struct ntfs_inode *ni, s64 start_vcn)
 	ni->i_dealloc_clusters -= min_t(s64, nr, ni->i_dealloc_clusters);
 }
 
+/*
+ * ntfs_attr_punch_delalloc - turn delalloc runs back into holes
+ * @ni:		non-resident ntfs attribute
+ * @start_vcn:	first vcn of the range
+ * @len:	number of clusters in the range
+ *
+ * Turn the LCN_DELALLOC parts of [@start_vcn, @start_vcn + @len) into holes
+ * and give back their reservation.  Used when a buffered write that reserved
+ * them failed before it dirtied any folio over them, so that writeback will
+ * never allocate them.  Runs that are not delalloc (anymore) are left alone.
+ * Delalloc runs are stored as holes on disk, so the mapping pairs need no
+ * update.
+ *
+ * The caller holds the mrec_lock of the base inode and the runlist lock for
+ * writing.
+ */
+void ntfs_attr_punch_delalloc(struct ntfs_inode *ni, s64 start_vcn, s64 len)
+{
+	struct runlist_element *rl, *punch_rl;
+	s64 vcn = start_vcn, end_vcn = start_vcn + len, run_end;
+	size_t new_rl_count;
+	int rl_count, err;
+
+	lockdep_assert_held_write(&ni->runlist.lock);
+
+	err = ntfs_attr_map_whole_runlist(ni);
+	if (err) {
+		ntfs_error(ni->vol->sb,
+			   "Failed to map the runlist to drop delalloc runs: %d", err);
+		return;
+	}
+
+	while (vcn < end_vcn) {
+		rl = ntfs_rl_find_vcn_nolock(ni->runlist.rl, vcn);
+		if (!rl || !rl->length)
+			break;
+		run_end = min(rl->vcn + rl->length, end_vcn);
+		if (rl->lcn != LCN_DELALLOC) {
+			vcn = run_end;
+			continue;
+		}
+
+		for (rl = ni->runlist.rl, rl_count = 0; rl->length; rl++)
+			rl_count++;
+		rl = ntfs_rl_punch_hole(ni->runlist.rl, rl_count + 1, vcn,
+					run_end - vcn, &punch_rl, &new_rl_count);
+		if (IS_ERR(rl)) {
+			ntfs_error(ni->vol->sb,
+				   "Failed to drop delalloc run at vcn 0x%llx: %ld",
+				   vcn, PTR_ERR(rl));
+			break;
+		}
+		kvfree(punch_rl);
+		ni->runlist.rl = rl;
+		ni->runlist.count = new_rl_count;
+
+		ntfs_release_dirty_clusters(ni->vol, run_end - vcn);
+		ni->i_dealloc_clusters -= min_t(s64, run_end - vcn,
+						ni->i_dealloc_clusters);
+		vcn = run_end;
+	}
+}
+
 /*
  * ntfs_non_resident_attr_shrink - shrink a non-resident, open ntfs attribute
  * @ni:		non-resident ntfs attribute to shrink
diff --git a/fs/ntfs/attrib.h b/fs/ntfs/attrib.h
index faa2dfba3a..ca2a8b53a4 100644
--- a/fs/ntfs/attrib.h
+++ b/fs/ntfs/attrib.h
@@ -110,6 +110,7 @@ int ntfs_non_resident_attr_insert_range(struct ntfs_inode *ni, s64 start_vcn, s6
 int ntfs_non_resident_attr_collapse_range(struct ntfs_inode *ni, s64 start_vcn, s64 len);
 int ntfs_non_resident_attr_punch_hole(struct ntfs_inode *ni, s64 start_vcn, s64 len);
 void ntfs_release_delalloc_from(struct ntfs_inode *ni, s64 start_vcn);
+void ntfs_attr_punch_delalloc(struct ntfs_inode *ni, s64 start_vcn, s64 len);
 int __ntfs_attr_truncate_vfs(struct ntfs_inode *ni, const s64 newsize,
 		const s64 i_size);
 int ntfs_attr_expand(struct ntfs_inode *ni, const s64 newsize, const s64 prealloc_size);
diff --git a/fs/ntfs/iomap.c b/fs/ntfs/iomap.c
index ce916707f6..1909824c30 100644
--- a/fs/ntfs/iomap.c
+++ b/fs/ntfs/iomap.c
@@ -372,6 +372,10 @@ static int ntfs_zero_range(struct inode *inode, loff_t offset, loff_t length)
 				NULL);
 }
 
+static void ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
+					loff_t length, ssize_t written,
+					unsigned int flags, struct iomap *iomap);
+
 static int ntfs_write_simple_iomap_begin_non_resident(struct inode *inode, loff_t offset,
 						      loff_t length, struct iomap *iomap)
 {
@@ -543,7 +547,13 @@ static int ntfs_write_simple_iomap_begin_non_resident(struct inode *inode, loff_
 			if (err == -EPERM)
 				err = 0;
 			if (err) {
-				ntfs_release_dirty_clusters(vol, max_clu_count);
+				/*
+				 * Nothing will be copied: drop the delalloc
+				 * clusters that no zeroed folio covers.
+				 */
+				ntfs_write_delalloc_release(inode, offset,
+							    iomap->length, 0,
+							    IOMAP_WRITE, iomap);
 				return err;
 			}
 		}
@@ -762,6 +772,61 @@ static int ntfs_write_iomap_end_resident(struct inode *inode, loff_t pos,
 	return written;
 }
 
+static void ntfs_write_delalloc_punch(struct inode *inode, loff_t offset,
+				      loff_t length, struct iomap *iomap)
+{
+	struct ntfs_inode *ni = NTFS_I(inode);
+	struct ntfs_inode *mrec_ni = ntfs_inode_is_named_stream(ni) ?
+			ntfs_base_inode(ni) : ni;
+	struct ntfs_volume *vol = ni->vol;
+	/* Clusters that still hold some dirty data stay delalloc. */
+	loff_t start = round_up(offset, vol->cluster_size);
+	loff_t end = round_down(offset + length, vol->cluster_size);
+
+	if (start >= end)
+		return;
+
+	mutex_lock(&mrec_ni->mrec_lock);
+	down_write(&ni->runlist.lock);
+	ntfs_attr_punch_delalloc(ni, ntfs_bytes_to_cluster(vol, start),
+				 ntfs_bytes_to_cluster(vol, end - start));
+	up_write(&ni->runlist.lock);
+	mutex_unlock(&mrec_ni->mrec_lock);
+}
+
+/*
+ * A buffered write that failed or copied less than it mapped leaves delalloc
+ * clusters that no dirty folio covers: writeback never allocates them, so
+ * their reservation would stay until the inode is evicted, and the stale
+ * delalloc runs would outlive the flush done by fallocate() and friends.
+ * Punch them out again, keeping every cluster that has dirty data in the
+ * page cache.
+ */
+static void ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
+					loff_t length, ssize_t written,
+					unsigned int flags, struct iomap *iomap)
+{
+	struct ntfs_volume *vol = NTFS_I(inode)->vol;
+	loff_t start_byte, end_byte;
+
+	/*
+	 * Delalloc is reserved per cluster, which can be larger than the
+	 * block size iomap_last_written_block() would round to.
+	 */
+	if (written)
+		start_byte = round_up(pos + written, vol->cluster_size);
+	else
+		start_byte = round_down(pos, vol->cluster_size);
+	end_byte = round_up(pos + length, vol->cluster_size);
+	if (start_byte >= end_byte)
+		return;
+
+	filemap_invalidate_lock(inode->i_mapping);
+	iomap_write_delalloc_release(inode, start_byte, end_byte, flags, iomap,
+				     ntfs_write_delalloc_punch);
+	filemap_invalidate_unlock(inode->i_mapping);
+}
+
 static int ntfs_write_iomap_end(struct inode *inode, loff_t pos, loff_t length,
 				ssize_t written, unsigned int flags,
 				struct iomap *iomap)
@@ -769,6 +834,10 @@ static int ntfs_write_iomap_end(struct inode *inode, loff_t pos, loff_t length,
 	if (iomap->type == IOMAP_INLINE)
 		return ntfs_write_iomap_end_resident(inode, pos, length,
 						     written, flags, iomap);
+	if (iomap->type == IOMAP_DELALLOC && iomap->flags & IOMAP_F_NEW &&
+	    !(flags & IOMAP_FAULT) && written < length)
+		ntfs_write_delalloc_release(inode, pos, length, written, flags,
+					    iomap);
 	return written;
 }
 

-- 
2.56.1

