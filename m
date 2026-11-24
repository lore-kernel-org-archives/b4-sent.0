From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Tue, 24 Nov 2026 23:49:45 +0100
Subject: [PATCH v2 11/11] ntfs: revalidate a buffered write's mapping after
 its clusters were allocated
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-11-f394c800ec03@proton.me>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5793;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=f2wotSxMN9uyJz+Y54H9BK5AnjHdsoo22xRtTQu7BLA=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kYYzWnVpM/a9/LSZo+RiUPibxcdr0pce8GidknnRJ
 2RCfN3ejlIWBjEuBlkxRZaO/zdCfEK+fVoWp9UHM4eVCWQIAxenAExEZyMjwwWWdRqai5cnn/R5
 LnsgfqHwaoervqX98QHTXpzYcDDafB7DX4kXhxfn2xXpT+C7+qD3OHf0EZb+TYZsP7rm/VW02v5
 pIjMA
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A buffered write turns a hole into an LCN_DELALLOC run in
->iomap_begin() and copies into the page cache afterwards, with only
the inode lock held.  A write fault or writeback does not take that
lock and can allocate the clusters in the meantime.  If the folio the
write has not reached yet is then written back and reclaimed,
__iomap_write_begin() still sees IOMAP_DELALLOC and zeroes the parts of
the block that the write does not cover instead of reading them, and
data that a write through a shared mapping put there is lost.

Reproducer: block the copy of a write into a hole on a userfaultfd page
before its second page, store a byte through a shared mapping next to
where the write ends, sync_file_range() the file and drop the page with
POSIX_FADV_DONTNEED, then let the copy go on.  The byte reads back as
zero.

Give the delalloc mapping of a buffered write a validity cookie.
ntfs_attr_map_cluster() bumps a per-inode count whenever it allocates
clusters, and ->iomap_valid() calls the mapping stale when the count
moved and its clusters are no longer all delalloc.  ->iomap_end() then
releases what was not copied, as for a short write, and the rest of the
write is mapped again.

Fixes: b041ca562526 ("ntfs: update iomap and address space operations")
Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/ntfs/attrib.c |  2 ++
 fs/ntfs/inode.c  |  1 +
 fs/ntfs/inode.h  |  3 +++
 fs/ntfs/iomap.c  | 48 ++++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 54 insertions(+)

diff --git a/fs/ntfs/attrib.c b/fs/ntfs/attrib.c
index cc24259fb6..4ec4ca3d87 100644
--- a/fs/ntfs/attrib.c
+++ b/fs/ntfs/attrib.c
@@ -5643,6 +5643,8 @@ int ntfs_attr_map_cluster(struct ntfs_inode *ni, s64 vcn_start, s64 *lcn_start,
 	}
 	ni->runlist.rl = rl;
 	ni->runlist.count = new_rl_count;
+	/* Delalloc mappings of buffered writes in flight go stale. */
+	WRITE_ONCE(ni->alloc_seq, ni->alloc_seq + 1);
 
 	if (!update_mp) {
 		u64 free = atomic64_read(&vol->free_clusters) * 100;
diff --git a/fs/ntfs/inode.c b/fs/ntfs/inode.c
index 911e68fa91..231f2799eb 100644
--- a/fs/ntfs/inode.c
+++ b/fs/ntfs/inode.c
@@ -557,6 +557,7 @@ void __ntfs_init_inode(struct super_block *sb, struct ntfs_inode *ni)
 	ni->target = NULL;
 	ni->linuxflags = 0;
 	ni->i_dealloc_clusters = 0;
+	ni->alloc_seq = 0;
 }
 
 /*
diff --git a/fs/ntfs/inode.h b/fs/ntfs/inode.h
index 7ea52c59c0..136062c9fb 100644
--- a/fs/ntfs/inode.h
+++ b/fs/ntfs/inode.h
@@ -94,6 +94,8 @@ enum ntfs_inode_mutex_lock_class {
  *   record. For fake inodes, the real (base) inode to which the attribute
  *   belongs.
  * @i_dealloc_clusters: delayed allocated clusters.
+ * @alloc_seq: bumped under the runlist lock whenever clusters are allocated
+ *   for a hole or delalloc run; a buffered write's ->iomap_valid() uses it.
  * @target: symlink buffer.
  * @linuxflags: Linux-specific file attributes loaded from the $LINUXFLAGS EA.
  */
@@ -144,6 +146,7 @@ struct ntfs_inode {
 		struct ntfs_inode *base_ntfs_ino;
 	} ext;
 	unsigned int i_dealloc_clusters;
+	unsigned int alloc_seq;
 	__le32 reparse_tag;
 	__le32 reparse_flags;
 	char *target;
diff --git a/fs/ntfs/iomap.c b/fs/ntfs/iomap.c
index 928ccb685a..bdb176fdd4 100644
--- a/fs/ntfs/iomap.c
+++ b/fs/ntfs/iomap.c
@@ -80,8 +80,55 @@ static void ntfs_iomap_put_folio(struct inode *inode, loff_t pos,
 	folio_put(folio);
 }
 
+/* Never 0: a mapping with no cookie is not checked. */
+static u64 ntfs_alloc_cookie(struct ntfs_inode *ni)
+{
+	return (u64)READ_ONCE(ni->alloc_seq) + 1;
+}
+
+/*
+ * A buffered write maps a hole or delalloc run as delalloc and copies into
+ * the page cache afterwards, without the locks a write fault or writeback
+ * takes to allocate the clusters.  If one of them allocates them meanwhile
+ * and the folio is written back and reclaimed, __iomap_write_begin() would
+ * zero the parts of a block that the write does not cover instead of
+ * reading what a write through a mapping put there.  Every allocation
+ * bumps ni->alloc_seq; when it moved since the mapping was made, the
+ * mapping is still good only if its clusters are all still delalloc.
+ * A stale mapping ends like a short write (->iomap_end() releases what was
+ * not copied) and the rest of the write is mapped again.
+ */
+static bool ntfs_iomap_valid(struct inode *inode, const struct iomap *iomap)
+{
+	struct ntfs_inode *ni = NTFS_I(inode);
+	struct ntfs_volume *vol = ni->vol;
+	struct runlist_element *rl;
+	s64 vcn, end;
+	bool valid = true;
+
+	if (!iomap->validity_cookie ||
+	    iomap->validity_cookie == ntfs_alloc_cookie(ni))
+		return true;
+
+	vcn = ntfs_bytes_to_cluster(vol, iomap->offset);
+	end = ntfs_bytes_to_cluster(vol, round_up(iomap->offset + iomap->length,
+						  vol->cluster_size));
+	down_read(&ni->runlist.lock);
+	rl = __ntfs_attr_find_vcn_nolock(&ni->runlist, vcn);
+	if (IS_ERR(rl))
+		valid = false;
+	for (; valid && vcn < end; rl++) {
+		if (!rl->length || rl->lcn != LCN_DELALLOC)
+			valid = false;
+		vcn = rl->vcn + rl->length;
+	}
+	up_read(&ni->runlist.lock);
+	return valid;
+}
+
 const struct iomap_write_ops ntfs_iomap_folio_ops = {
 	.put_folio = ntfs_iomap_put_folio,
+	.iomap_valid = ntfs_iomap_valid,
 };
 
 static int ntfs_read_iomap_begin_resident(struct inode *inode, loff_t offset, loff_t length,
@@ -469,6 +516,7 @@ static int ntfs_write_simple_iomap_begin_non_resident(struct inode *inode, loff_
 			ni->runlist.count = new_rl_count;
 			ni->i_dealloc_clusters += max_clu_count;
 		}
+		iomap->validity_cookie = ntfs_alloc_cookie(ni);
 		up_write(&ni->runlist.lock);
 		mutex_unlock(&mrec_ni->mrec_lock);
 

-- 
2.56.1

