From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Tue, 24 Nov 2026 23:49:37 +0100
Subject: [PATCH v2 03/11] ntfs: release delalloc reservations cut off by
 truncate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-3-f394c800ec03@proton.me>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3407;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=3nT+zUonqfx2kvoDVZIlPQfmCvPmSP51Ad2wiF9F3AM=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kXr90o281beWvL0Zy2Jz4uZy84q5HW7FkZwrn2YHN
 rheWXqqo5SFQYyLQVZMkaXj/40Qn5Bvn5bFafXBzGFlAhnCwMUpABM5+4+R4QRjZI9L2GqlM+vP
 rEpPW+rqtv/E89/MZm0F09/zcqXFJjMyLBSrDVT4uqiuSHpr0+OiuP/Cm5lTJkzVyhGLchHZV2D
 EBAA=
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A buffered write into a hole turns the hole into an LCN_DELALLOC run and
reserves its clusters in vol->dirty_clusters
(ntfs_write_simple_iomap_begin_non_resident()).  Writeback hands the
reservation back when ntfs_cluster_alloc() allocates the run.

A truncate that cuts off delalloc runs before writeback drops their
dirty folios, frees the clusters of the attribute with
ntfs_cluster_free(), which skips everything that is not a real cluster,
and removes the runs with ntfs_rl_truncate_nolock().  Nothing gives the
reservation back, so the free space reported by statfs() and used by
ntfs_available_clusters_count() shrinks by that many clusters until the
volume is unmounted.  $Bitmap is not affected.

Workloads that rewrite files (open(O_TRUNC) + write) or truncate freshly
written data lose free space quickly: a test that writes, truncates and
punches holes in six 400 KiB files on a 128 MiB volume sees statfs()
free space drop from 79 MB to zero in 80 seconds, after which writes
fail with ENOSPC or come back short.  A 1 MiB buffered write followed by
ftruncate(fd, 0) and sync leaves 256 (4 KiB) clusters reserved.

Release the reservation of the delalloc runs that the shrink cuts off,
before the runlist is truncated.

Fixes: 495e90fa3348 ("ntfs: update attrib operations")
Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/ntfs/attrib.c | 33 +++++++++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/fs/ntfs/attrib.c b/fs/ntfs/attrib.c
index 6ee6b6bcac..4028c310fc 100644
--- a/fs/ntfs/attrib.c
+++ b/fs/ntfs/attrib.c
@@ -4383,6 +4383,37 @@ static int ntfs_attr_make_resident(struct ntfs_inode *ni, struct ntfs_attr_searc
 	return 0;
 }
 
+/*
+ * ntfs_release_delalloc_from - give back the reservation of delalloc runs
+ * @ni:		non-resident ntfs attribute whose runlist is about to be truncated
+ * @start_vcn:	first vcn that is cut off
+ *
+ * Delayed allocation reserves vol->dirty_clusters for every LCN_DELALLOC
+ * cluster when the buffered write is done and only gives it back when
+ * writeback allocates the clusters.  Runs cut off by a truncate never reach
+ * writeback (their dirty folios are dropped from the page cache), so their
+ * reservation has to be released here or it is lost until unmount.
+ *
+ * The runlist must be mapped completely and locked for writing.
+ */
+static void ntfs_release_delalloc_from(struct ntfs_inode *ni, s64 start_vcn)
+{
+	struct runlist_element *rl = ni->runlist.rl;
+	s64 nr = 0;
+
+	lockdep_assert_held_write(&ni->runlist.lock);
+
+	for (; rl && rl->length; rl++) {
+		if (rl->lcn != LCN_DELALLOC || rl->vcn + rl->length <= start_vcn)
+			continue;
+		nr += rl->vcn + rl->length - max(rl->vcn, start_vcn);
+	}
+	if (!nr)
+		return;
+	ntfs_release_dirty_clusters(ni->vol, nr);
+	ni->i_dealloc_clusters -= min_t(s64, nr, ni->i_dealloc_clusters);
+}
+
 /*
  * ntfs_non_resident_attr_shrink - shrink a non-resident, open ntfs attribute
  * @ni:		non-resident ntfs attribute to shrink
@@ -4479,6 +4510,8 @@ static int ntfs_non_resident_attr_shrink(struct ntfs_inode *ni,
 		}
 		ntfs_attr_put_search_ctx(ctx);
 
+		ntfs_release_delalloc_from(ni, first_free_vcn);
+
 		/* Truncate the runlist itself. */
 		if (ntfs_rl_truncate_nolock(vol, &ni->runlist, first_free_vcn)) {
 			/*

-- 
2.56.1

