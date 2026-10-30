From: Kamil Chojnowski <contact@diath.net>
Date: Fri, 30 Oct 2026 01:08:15 +0100
Subject: [PATCH 6/6] fs/ntfs3: do not reallocate clusters of a partly
 allocated sparse frame
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-ntfs3-resident-fixes-v1-6-7b6c857d4330@diath.net>
References: <20261030-ntfs3-resident-fixes-v1-0-7b6c857d4330@diath.net>
In-Reply-To: <20261030-ntfs3-resident-fixes-v1-0-7b6c857d4330@diath.net>
To: Konstantin Komarov <almaz.alexandrovich@paragon-software.com>
Cc: Christoph Hellwig <hch@lst.de>, ntfs3@lists.linux.dev, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Kamil Chojnowski <contact@diath.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793318890; l=3450;
 i=contact@diath.net; s=20261029; h=from:subject:message-id;
 bh=sBOCx5FVq+GEhbTfofjJvzmOyg91nklfg6iIoMV954k=;
 b=1WWAgWrv1PGYmoA43+pGreW65PTmI8ysXLTMnlFYoa6qSwH2UCP9yNJfJfIS9mIi0GHDz5DgE
 prDKNmz4m4CAgDhR7DALUv9f3tuv0EHtQKoWjebRsHeW88523TejvpA
X-Developer-Key: i=contact@diath.net; a=ed25519;
 pk=G15RQXroUn6f8ud+bOEqlqpPdpLoCB3L3G9XVUf+YaA=
X-Endpoint-Received: by B4 Relay for contact@diath.net/20261029 with auth_id=1360
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For a sparse or compressed attribute with a compression unit,
attr_data_get_block_locked() fills a hole by allocating the whole frame
around it (16 clusters for c_unit 4), assuming a frame is either fully
allocated or fully sparse.  ntfs.sys keeps it that way, but ntfs-3g
allocates sparse files cluster by cluster: it marks them sparse with
c_unit 4 and leaves holes of any length at any offset.  Linker output
written through ntfs-3g looks like that.

When such a hole starts or ends inside a frame, attr_allocate_clusters()
maps new, zeroed clusters over the clusters the frame already has:

 - the data in those clusters is silently replaced with zeros;
 - the old clusters stay marked in use but are no longer referenced;
 - total_size grows by the whole frame, although only the hole was new.

Once total_size exceeds alloc_size, mi_enum_attr() rejects the record:
the inode goes bad and the volume is marked dirty.

  ntfs3(vda): ino=40, "pwrite" mi_enum_attr
  ntfs3(vda): Mark volume as dirty due to NTFS errors
  ntfs3(vda): ino=40, "pwrite" attr_set_size_ex

Shrink the frame aligned range to the sparse run around the requested
cluster, so that only the hole is allocated.  Frames that are entirely
sparse, and so all frames of files written by ntfs.sys or ntfs3, are
allocated as before.

Reproducer: in a file that ntfs-3g left with a two-cluster hole in the
middle of a frame, pwrite(2) 4 KiB into the hole.  Before this patch 14
clusters of data around it read back as zeros and the file uses 16 more
clusters; after it, only the two hole clusters are allocated.

Fixes: be71b5cba2e6 ("fs/ntfs3: Add attrib operations")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Kamil Chojnowski <contact@diath.net>
---
 fs/ntfs3/attrib.c | 28 ++++++++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/fs/ntfs3/attrib.c b/fs/ntfs3/attrib.c
index b21c913050f7..1bd05639709b 100644
--- a/fs/ntfs3/attrib.c
+++ b/fs/ntfs3/attrib.c
@@ -1032,6 +1032,33 @@ int attr_data_get_block(struct ntfs_inode *ni, CLST vcn, CLST clen, CLST *lcn,
 	return err;
 }
 
+/*
+ * attr_frame_hole - Limit a frame aligned allocation to the hole at @vcn0.
+ *
+ * ntfs.sys allocates sparse and compressed attributes in whole frames, but
+ * ntfs-3g allocates sparse files cluster by cluster, so a frame can be partly
+ * allocated.  Its allocated clusters hold data and must not be allocated
+ * again: shrink [*vcn, *vcn + *to_alloc) to the sparse run around @vcn0.
+ */
+static void attr_frame_hole(const struct runs_tree *run, CLST vcn0, CLST *vcn,
+			    CLST *to_alloc)
+{
+	CLST start = vcn0, end = *vcn + *to_alloc;
+	CLST lcn, len;
+
+	while (start > *vcn &&
+	       run_lookup_entry(run, start - 1, &lcn, NULL, NULL) &&
+	       lcn == SPARSE_LCN)
+		start--;
+
+	if (run_lookup_entry(run, vcn0, &lcn, &len, NULL) &&
+	    lcn == SPARSE_LCN && vcn0 + len < end)
+		end = vcn0 + len;
+
+	*vcn = start;
+	*to_alloc = end - start;
+}
+
 /*
  * attr_data_get_block_locked - Helper for attr_data_get_block.
  */
@@ -1195,6 +1222,7 @@ again:
 		/* Get frame aligned vcn and to_alloc. */
 		vcn = vcn0 & cmask;
 		to_alloc = ((vcn0 + clen + clst_per_frame - 1) & cmask) - vcn;
+		attr_frame_hole(run, vcn0, &vcn, &to_alloc);
 		if (fr < clst_per_frame)
 			fr = clst_per_frame;
 		if (vcn != vcn0 || clen < to_alloc)

-- 
2.56.0

