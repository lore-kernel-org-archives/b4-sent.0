From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Tue, 24 Nov 2026 23:49:40 +0100
Subject: [PATCH v2 06/11] ntfs: release the delalloc reservations of an
 evicted inode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-6-f394c800ec03@proton.me>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4574;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=m0GZy5Hxncz+i8T1+cTd1NfQBxBBQqqcjVOAbZiwO7o=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kQatHf3fNwrpO8x8tL1I0NG3VMTJUtldRbCOiXs70
 2o7n6iOUhYGMS4GWTFFlo7/N0J8Qr59Whan1Qczh5UJZAgDF6cATOTFckaG9fNfTVP++amAS6+z
 mXWmwz2Nm0b3TurYe3c0t17tl40TYfifLX1dNqezMHzPpnbZG7fKwnXDF2zfu+XixO/pZ9ifWkS
 xAAA=
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When an inode is evicted with LCN_DELALLOC runs left in its runlist,
truncate_inode_pages_final() drops their dirty folios and the clusters
reserved for them in vol->dirty_clusters are never given back.  Only the
deletion of a base inode released anything, using the per-inode
i_dealloc_clusters counter.  This leaks free space until unmount when a
named stream with delayed data is removed (ntfs_stream_finish_remove()
truncates the page cache and ntfs_attr_rm() frees only real clusters),
when a file is unlinked while one of its named streams has delayed data
(ntfs_cleanup_deleted_inode() drops the stream inode, whose reservation
is not covered by the base inode's counter), and when an inode that
keeps a delalloc run no dirty folio covers (see the next patches) is
evicted.

Reproducer: mount with streams_interface=windows, write 1 MiB to f:s,
rm f:s (or rm f), sync: statfs() reports 256 (4 KiB) clusters less free
space than after a remount.

Release the reservations of whatever delalloc runs are left in the
runlist when any ntfs inode is evicted, and drop the counter-based
release from the deletion path, which would release them twice.

Fixes: b041ca562526 ("ntfs: update iomap and address space operations")
Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/ntfs/attrib.c | 12 +++++++-----
 fs/ntfs/attrib.h |  1 +
 fs/ntfs/inode.c  | 12 +++++++++++-
 3 files changed, 19 insertions(+), 6 deletions(-)

diff --git a/fs/ntfs/attrib.c b/fs/ntfs/attrib.c
index 7711b9df89..f604a42673 100644
--- a/fs/ntfs/attrib.c
+++ b/fs/ntfs/attrib.c
@@ -4390,13 +4390,15 @@ static int ntfs_attr_make_resident(struct ntfs_inode *ni, struct ntfs_attr_searc
  *
  * Delayed allocation reserves vol->dirty_clusters for every LCN_DELALLOC
  * cluster when the buffered write is done and only gives it back when
- * writeback allocates the clusters.  Runs cut off by a truncate never reach
- * writeback (their dirty folios are dropped from the page cache), so their
- * reservation has to be released here or it is lost until unmount.
+ * writeback allocates the clusters.  Runs cut off by a truncate, or left in
+ * the runlist of an inode that is evicted, never reach writeback (their dirty
+ * folios are dropped from the page cache), so their reservation has to be
+ * released here or it is lost until unmount.
  *
- * The runlist must be mapped completely and locked for writing.
+ * The runlist must be locked for writing.  It need not be mapped completely:
+ * delalloc runs only exist in fragments of the runlist that are mapped.
  */
-static void ntfs_release_delalloc_from(struct ntfs_inode *ni, s64 start_vcn)
+void ntfs_release_delalloc_from(struct ntfs_inode *ni, s64 start_vcn)
 {
 	struct runlist_element *rl = ni->runlist.rl;
 	s64 nr = 0;
diff --git a/fs/ntfs/attrib.h b/fs/ntfs/attrib.h
index 9d6bf03202..faa2dfba3a 100644
--- a/fs/ntfs/attrib.h
+++ b/fs/ntfs/attrib.h
@@ -109,6 +109,7 @@ int ntfs_attr_fallocate(struct ntfs_inode *ni, loff_t start, loff_t byte_len, bo
 int ntfs_non_resident_attr_insert_range(struct ntfs_inode *ni, s64 start_vcn, s64 len);
 int ntfs_non_resident_attr_collapse_range(struct ntfs_inode *ni, s64 start_vcn, s64 len);
 int ntfs_non_resident_attr_punch_hole(struct ntfs_inode *ni, s64 start_vcn, s64 len);
+void ntfs_release_delalloc_from(struct ntfs_inode *ni, s64 start_vcn);
 int __ntfs_attr_truncate_vfs(struct ntfs_inode *ni, const s64 newsize,
 		const s64 i_size);
 int ntfs_attr_expand(struct ntfs_inode *ni, const s64 newsize, const s64 prealloc_size);
diff --git a/fs/ntfs/inode.c b/fs/ntfs/inode.c
index 4fbdcd4596..911e68fa91 100644
--- a/fs/ntfs/inode.c
+++ b/fs/ntfs/inode.c
@@ -430,7 +430,6 @@ static int ntfs_non_resident_dealloc_clusters(struct ntfs_inode *ni)
 		}
 	}
 
-	ntfs_release_dirty_clusters(ni->vol, ni->i_dealloc_clusters);
 	ntfs_attr_put_search_ctx(actx);
 	return err;
 }
@@ -2459,6 +2458,17 @@ void ntfs_evict_big_inode(struct inode *vi)
 
 	truncate_inode_pages_final(&vi->i_data);
 
+	/*
+	 * The dirty folios dropped above never reach writeback.  Give back
+	 * the reservations of the delalloc runs they had, for named streams
+	 * and attribute inodes as well as for base inodes.
+	 */
+	if (NInoNonResident(ni) && ni->runlist.rl) {
+		down_write(&ni->runlist.lock);
+		ntfs_release_delalloc_from(ni, 0);
+		up_write(&ni->runlist.lock);
+	}
+
 	if (!vi->i_nlink) {
 		if (!NInoAttr(ni)) {
 			/* Never called with extent inodes */

-- 
2.56.1

