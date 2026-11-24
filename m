From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Tue, 24 Nov 2026 23:49:44 +0100
Subject: [PATCH v2 10/11] ntfs: zero the rest of a new cluster after a
 short buffered write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-10-f394c800ec03@proton.me>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=8448;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=Suy0TdC3K0sbN2qnqApRQjoBLBv/muIV4lpD2zt49E0=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kYbS78r3PzXlfzkqpp/Ef6uhuOy+/a2ZnjsY7l5e/
 WK3x92SjlIWBjEuBlkxRZaO/zdCfEK+fVoWp9UHM4eVCWQIAxenAEzEahUjwzenb0fKZ8w/VXzn
 QpaTSsP5GmOvUwFP/l24ly5RseDOh98M/0PFGQqWcs49Pffs/pQPvoddBF4v8ZjI+9OU/67SmhX
 uDawA
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ntfs_write_simple_iomap_begin_non_resident() turns the holes a buffered
write covers into LCN_DELALLOC runs, and zeroes in the page cache only
the parts of the first and last cluster that the write will not cover.
When the copy from user space stops inside a cluster (the source buffer
runs into an unmapped page, or a fatal signal), only the bytes copied
are dirty.  Writeback allocates the whole cluster and writes the dirty
blocks, and the rest of the cluster keeps what the reused clusters held
before.  Below initialized_size, for example a write into a hole of a
sparse file, reads return that old data.

Reproducer: fill a file, fsync, truncate it to 0 and back up, write the
last byte, then pwrite() 2.5 clusters at a cluster boundary from a
buffer whose readable part ends 5096 bytes in: the write returns 5096,
and after fsync and drop_caches the rest of the second cluster (4 KiB
clusters) or of the first (64 KiB clusters) reads back the old file
contents.

Mark the mappings that ->iomap_begin() made out of a hole, and on a
short copy make writeback write the rest of the cluster the copy stopped
in, before the unused delalloc clusters after it are punched out: under
the invalidate lock, the blocks of that range in folios already in the
page cache are marked dirty as they are, with iomap_dirty_folio_range()
(they hold the zeroes __iomap_write_begin() put there, or data an mmap
write added meanwhile, which must not be lost), and the rest of the
range is zeroed while it is still delalloc (once a write fault or
writeback has allocated it, an mmap write's data may have left the page
cache; a follow-up series makes both zero a partly written cluster on
the disk before mapping it).  The other blocks of those folios stay
clean, so the punch still releases the clusters the write did not reach.
When the writer has a fatal signal pending, iomap_zero_range() refuses
to run in its context (-EINTR), so the zeroing is done from a worker
then.

Fixes: b041ca562526 ("ntfs: update iomap and address space operations")
Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/ntfs/iomap.c | 141 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 141 insertions(+)

diff --git a/fs/ntfs/iomap.c b/fs/ntfs/iomap.c
index fd94d4b34f..928ccb685a 100644
--- a/fs/ntfs/iomap.c
+++ b/fs/ntfs/iomap.c
@@ -5,6 +5,7 @@
  * Copyright (c) 2025 LG Electronics Co., Ltd.
  */
 
+#include <linux/workqueue.h>
 #include <linux/writeback.h>
 
 #include "attrib.h"
@@ -12,6 +13,9 @@
 #include "ntfs.h"
 #include "iomap.h"
 
+/* iomap->flags: ->iomap_begin() turned a hole into this delalloc mapping */
+#define NTFS_IOMAP_F_WAS_HOLE		IOMAP_F_PRIVATE
+
 static void ntfs_iomap_put_folio_non_resident(struct inode *inode, loff_t pos,
 					      unsigned int len, struct folio *folio)
 {
@@ -481,6 +485,9 @@ static int ntfs_write_simple_iomap_begin_non_resident(struct inode *inode, loff_
 		if (lcn <= LCN_HOLE) {
 			loff_t end = offset + length;
 
+			/* The whole mapping was a hole before this write. */
+			iomap->flags |= NTFS_IOMAP_F_WAS_HOLE;
+
 			if (vcn_ofs || ((vol->cluster_size > iomap->length) &&
 					end < ni->initialized_size)) {
 				loff_t z_start, z_end;
@@ -800,11 +807,145 @@ static void __ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
 				     ntfs_write_delalloc_punch);
 }
 
+struct ntfs_zero_work {
+	struct work_struct work;
+	struct inode *inode;
+	loff_t pos;
+	loff_t len;
+	int err;
+};
+
+static void ntfs_zero_range_workfn(struct work_struct *work)
+{
+	struct ntfs_zero_work *zw = container_of(work, struct ntfs_zero_work,
+						 work);
+
+	zw->err = iomap_zero_range(zw->inode, zw->pos, zw->len, NULL,
+				   ntfs_seek_iomap_next, &ntfs_iomap_folio_ops,
+				   NULL);
+}
+
+/*
+ * Like ntfs_zero_range(), but also for a writer that has a fatal signal
+ * pending: iomap_zero_range() then gives up with -EINTR, and a write cut
+ * short by SIGKILL is one whose cluster tail must still be zeroed.  Zero
+ * from a worker in that case, which has no signal to see; the caller's
+ * invalidate lock still keeps page faults out of the range.
+ */
+static int ntfs_zero_range_unkillable(struct inode *inode, loff_t pos,
+				      loff_t len)
+{
+	struct ntfs_zero_work zw = { .inode = inode, .pos = pos, .len = len };
+
+	int err;
+
+	if (!fatal_signal_pending(current)) {
+		err = ntfs_zero_range(inode, pos, len);
+		/* the signal may also come while it zeroes */
+		if (err != -EINTR || !fatal_signal_pending(current))
+			return err;
+	}
+
+	lockdep_assert_held_write(&inode->i_mapping->invalidate_lock);
+	INIT_WORK_ONSTACK(&zw.work, ntfs_zero_range_workfn);
+	queue_work(system_unbound_wq, &zw.work);
+	flush_work(&zw.work);
+	destroy_work_on_stack(&zw.work);
+	return zw.err;
+}
+
+/* True if the cluster at byte @pos is still a delalloc run. */
+static bool ntfs_pos_is_delalloc(struct inode *inode, loff_t pos)
+{
+	struct ntfs_inode *ni = NTFS_I(inode);
+	s64 vcn = ntfs_bytes_to_cluster(ni->vol, pos);
+	struct runlist_element *rl;
+	s64 lcn;
+
+	down_read(&ni->runlist.lock);
+	rl = __ntfs_attr_find_vcn_nolock(&ni->runlist, vcn);
+	lcn = IS_ERR(rl) ? LCN_EINVAL : ntfs_rl_vcn_to_lcn(rl, vcn);
+	up_read(&ni->runlist.lock);
+	return lcn == LCN_DELALLOC;
+}
+
+/*
+ * Make writeback write all of [start, end), the rest of a cluster that was a
+ * hole and that a short buffered write filled only in part.  Folios in the
+ * page cache keep their contents (the zeroes __iomap_write_begin() put
+ * there, or data an mmap write added meanwhile), and only their blocks in
+ * the range are dirtied: other clean blocks of the folio may be holes, or
+ * delalloc clusters the write did not reach, which the caller punches out.
+ * The rest of the range is zeroed only while the cluster is still delalloc:
+ * once a write fault or writeback has allocated it, what an mmap write put
+ * there since may be on the disk only, and zeroing the page cache would
+ * overwrite it.  The caller holds the invalidate lock.
+ */
+static int ntfs_dirty_cluster_tail(struct inode *inode, loff_t start,
+				   loff_t end)
+{
+	struct folio *folio;
+	loff_t next;
+	int err = 0;
+
+	lockdep_assert_held_write(&inode->i_mapping->invalidate_lock);
+	while (!err && start < end) {
+		folio = filemap_lock_folio(inode->i_mapping,
+					   start >> PAGE_SHIFT);
+		if (IS_ERR(folio)) {
+			next = min_t(loff_t, round_up(start + 1, PAGE_SIZE),
+				     end);
+			if (ntfs_pos_is_delalloc(inode, start))
+				err = ntfs_zero_range_unkillable(inode, start,
+								 next - start);
+		} else {
+			bool uptodate = folio_test_uptodate(folio);
+			size_t off = offset_in_folio(folio, start);
+
+			next = min_t(loff_t, folio_pos(folio) +
+				     folio_size(folio), end);
+			if (uptodate)
+				iomap_dirty_folio_range(folio, off,
+							next - start);
+			folio_unlock(folio);
+			folio_put(folio);
+			if (!uptodate && ntfs_pos_is_delalloc(inode, start))
+				err = ntfs_zero_range_unkillable(inode, start,
+								 next - start);
+		}
+		start = next;
+	}
+	return err;
+}
+
 static void ntfs_write_delalloc_release(struct inode *inode, loff_t pos,
 					loff_t length, ssize_t written,
 					unsigned int flags, struct iomap *iomap)
 {
+	struct ntfs_volume *vol = NTFS_I(inode)->vol;
+
 	filemap_invalidate_lock(inode->i_mapping);
+	/*
+	 * A copy that stopped inside a cluster which was a hole leaves the
+	 * rest of that cluster neither written nor zeroed, but writeback
+	 * allocates the whole cluster and writes only the dirty blocks, so
+	 * the old contents of the cluster would show through.
+	 */
+	if (written && iomap->flags & NTFS_IOMAP_F_WAS_HOLE) {
+		loff_t start = pos + written;
+		loff_t end = min_t(loff_t, round_up(start, vol->cluster_size),
+				   i_size_read(inode));
+		int err = 0;
+
+		if (end > start)
+			err = ntfs_dirty_cluster_tail(inode, start, end);
+		if (err) {
+			ntfs_error(vol->sb,
+				   "Failed to zero [%lld, %lld) of inode 0x%llx after a short write: %d",
+				   start, end, NTFS_I(inode)->mft_no, err);
+			NVolSetErrors(vol);
+		}
+	}
 	__ntfs_write_delalloc_release(inode, pos, length, written, flags,
 				      iomap);
 	filemap_invalidate_unlock(inode->i_mapping);

-- 
2.56.1

