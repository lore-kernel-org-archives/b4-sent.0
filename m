From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Tue, 24 Nov 2026 23:49:36 +0100
Subject: [PATCH v2 02/11] iomap: add a helper to mark a range of a folio
 dirty
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-2-f394c800ec03@proton.me>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2884;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=i0mxnQ4RlIZOshN7UDhDAACtyhM3XWJqWt2QLrbCFUc=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kfpnRkdrvuo8To/XeT6tzSlc+Yqky/ZHC5ZwC29sl
 43vr57cUcrCIMbFICumyNLx/0aIT8i3T8vitPpg5rAygQxh4OIUgImInmFkmMbxpLUycMqCH9uu
 pJmtDvCdJ/ynqv/Ah9ser/jenT31/CXDfxdGNaWJdy7Z+h/7runOIbC/etNZ8cpLu2Kany+Z/4z
 jPhsA
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A filesystem that allocates in units larger than a block may need
writeback to write blocks that a buffered write did not copy into.  ntfs
reserves whole clusters for delayed allocation, and after a short copy
into a cluster that was a hole, writeback must also write the rest of
that cluster, or the cluster shows its old contents on the disk there.
folio_mark_dirty() marks every block of the folio dirty, so the delalloc
release that follows no longer finds the clean blocks of the clusters
the write did not reach and keeps them reserved: with 1 KiB and 2 KiB
clusters, writeback then allocates a cluster that holds no data.

Add iomap_dirty_folio_range(), which marks the folio and only the blocks
covering a byte range dirty.

"ntfs: zero the rest of a new cluster after a short buffered write"
later in this series needs this, so it goes to stable with it.

Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/iomap/buffered-io.c | 19 +++++++++++++++++++
 include/linux/iomap.h  |  1 +
 2 files changed, 20 insertions(+)

diff --git a/fs/iomap/buffered-io.c b/fs/iomap/buffered-io.c
index 2eb8070e34..8c8851d16f 100644
--- a/fs/iomap/buffered-io.c
+++ b/fs/iomap/buffered-io.c
@@ -858,6 +858,25 @@ bool iomap_dirty_folio(struct address_space *mapping, struct folio *folio)
 }
 EXPORT_SYMBOL_GPL(iomap_dirty_folio);
 
+/**
+ * iomap_dirty_folio_range - mark a range of a folio dirty
+ * @folio: the locked, uptodate folio
+ * @off: byte offset of the range in @folio
+ * @len: length of the range in bytes
+ *
+ * Mark the blocks that cover [@off, @off + @len) and @folio dirty, but none
+ * of the other blocks of @folio, so that writeback writes only those blocks.
+ */
+void iomap_dirty_folio_range(struct folio *folio, size_t off, size_t len)
+{
+	struct address_space *mapping = folio->mapping;
+
+	ifs_alloc(mapping->host, folio, 0);
+	iomap_set_range_dirty(folio, off, len);
+	filemap_dirty_folio(mapping, folio);
+}
+EXPORT_SYMBOL_GPL(iomap_dirty_folio_range);
+
 static void
 iomap_write_failed(struct inode *inode, loff_t pos, unsigned len)
 {
diff --git a/include/linux/iomap.h b/include/linux/iomap.h
index 78a1b7603a..6a6e67b87f 100644
--- a/include/linux/iomap.h
+++ b/include/linux/iomap.h
@@ -445,6 +445,7 @@ struct folio *iomap_get_folio(struct iomap_iter *iter, loff_t pos, size_t len);
 bool iomap_release_folio(struct folio *folio, gfp_t gfp_flags);
 void iomap_invalidate_folio(struct folio *folio, size_t offset, size_t len);
 bool iomap_dirty_folio(struct address_space *mapping, struct folio *folio);
+void iomap_dirty_folio_range(struct folio *folio, size_t off, size_t len);
 void iomap_folio_mark_uptodate(struct folio *folio);
 int iomap_file_unshare(struct inode *inode, loff_t pos, loff_t len,
 		iomap_iter_next_fn next,

-- 
2.56.1

