From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Tue, 24 Nov 2026 23:49:38 +0100
Subject: [PATCH v2 04/11] ntfs: do not consume delalloc reservations when
 filling holes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-4-f394c800ec03@proton.me>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2158;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=+jVS4i0N2xYWTOmK5KLBxioqsjuDV8wLrjNVc80eqAM=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kXrPqauXXE0L/L/rCdfHoEML1u6/5eZ9yPDweh229
 VbHnji2dJSyMIhxMciKKbJ0/L8R4hPy7dOyOK0+mDmsTCBDGLg4BWAiJiyMDO+C+q6XJFs+2PA+
 MtE984D/w5SfW1Pyr9w/K+nO/2JPWjTDL6YXz51Ck6YzLF117GCo54Ol2dPP9dj1HZ98O3xTdAu
 bCiMA
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ntfs_attr_map_cluster() always calls ntfs_cluster_alloc() with
is_dealloc set, which makes the allocator skip the dirty_clusters check
and subtract the allocated clusters from vol->dirty_clusters.  That is
right for writeback converting an LCN_DELALLOC run, whose clusters were
reserved by the buffered write, but ntfs_attr_map_cluster() also fills
plain holes for fallocate(), direct I/O and page_mkwrite(), which never
reserved anything.  Those allocations release reservations that belong
to dirty data of other files, and can use clusters that are promised to
that data, so writeback of the delayed data can later run out of space
although every earlier check succeeded.

Reproducer: write 1 MiB to file A without syncing (statfs() free space
drops by 256 clusters), then fallocate() 1 MiB on file B: free space
does not drop at all.

Only treat the allocation as consuming a reservation when the run being
filled is a delalloc run.  Filling a hole now fails with ENOSPC when the
remaining free clusters are all reserved for delayed data, so a write
fault into a hole of an mmap()ed file gets SIGBUS in that case, as on
other filesystems with delayed allocation.

Fixes: 495e90fa3348 ("ntfs: update attrib operations")
Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/ntfs/attrib.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/fs/ntfs/attrib.c b/fs/ntfs/attrib.c
index 4028c310fc..cdac846f37 100644
--- a/fs/ntfs/attrib.c
+++ b/fs/ntfs/attrib.c
@@ -5520,8 +5520,14 @@ int ntfs_attr_map_cluster(struct ntfs_inode *ni, s64 vcn_start, s64 *lcn_start,
 		}
 	}
 
+	/*
+	 * Only a delayed-allocation run holds a reservation in
+	 * vol->dirty_clusters for the allocator to consume.  Holes filled by
+	 * fallocate(), direct I/O or page_mkwrite() have none and must leave
+	 * the reservations of other writers alone.
+	 */
 	rlc = ntfs_cluster_alloc(vol, vcn, clu_count, lcn_seek_from, DATA_ZONE,
-			false, true, true);
+			false, true, lcn == LCN_DELALLOC);
 	if (IS_ERR(rlc)) {
 		err = PTR_ERR(rlc);
 		goto out;

-- 
2.56.1

