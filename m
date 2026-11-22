From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Sun, 22 Nov 2026 19:19:40 +0100
Subject: [PATCH 4/7] ntfs: do not shift the cluster number of a delalloc
 run on split
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-ntfs-delalloc-fixes-v1-4-0726f0dce403@proton.me>
References: <20261122-b4-ntfs-delalloc-fixes-v1-0-0726f0dce403@proton.me>
In-Reply-To: <20261122-b4-ntfs-delalloc-fixes-v1-0-0726f0dce403@proton.me>
To: Namjae Jeon <linkinjeon@kernel.org>, Hyunchul Lee <hyc.lee@gmail.com>, 
 Baolin Liu <liubaolin12138@163.com>
Cc: ntfs@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Zhan Xusheng <zhanxusheng1024@gmail.com>, stable@vger.kernel.org, 
 Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3638;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=QYrY3PPRwc1pxE1XgYFpRxvEIryQYj/9Bk2ICaRmWlw=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmxmI8uYJ2p3p3zxX3m5Z+l87XsPRQRffrlbHGnPoXIvT
 2tDVuXkjlIWBjEuBlkxRZaO/zdCfEK+fVoWp9UHM4eVCWQIAxenAEykbg/DX5EcxajDEzf/Xf5G
 ZlJS+6FnbK2lXxZLbVq8+efZ7578meqMDAdieUtfsxmmlhy5cX3t60fV3f6TGM/Hae05E7HX4V0
 XFzcA
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ntfs_rl_punch_hole() and ntfs_rl_collapse_range() advance the lcn of a
run they split with "if (lcn > LCN_HOLE) lcn += n".  LCN_DELALLOC (-1)
is greater than LCN_HOLE (-2), so splitting a delalloc run turns its
tail into a run of real clusters starting at n - 1.
ntfs_rl_insert_range() advances it unconditionally; its callers insert
holes, so only a hole split for a non-hole source and a split delalloc
run are affected.  ntfs_rle_lcn_contiguous() has the same problem and
can merge a delalloc run with a following real run.

The punched-out part then goes to ntfs_cluster_free_from_rl(), which
frees clusters that belong to other files or to metadata, and the part
left in the runlist maps the file onto them.  Delalloc runs normally do
not survive the writeback that fallocate() does first, but a buffered
write that fails after ->iomap_begin() leaves one without dirty folios
(fixed by the next patch); FALLOC_FL_PUNCH_HOLE or COLLAPSE_RANGE
through it then corrupts the volume (ntfsck: "Found 1 inconsistent
bitmap block(s)").

Only shift the lcn of runs that have real clusters.

Fixes: 11ccc9107dc4 ("ntfs: update runlist handling and cluster allocator")
Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/ntfs/runlist.c | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

diff --git a/fs/ntfs/runlist.c b/fs/ntfs/runlist.c
index 76ba6ab72b..1e87db35ce 100644
--- a/fs/ntfs/runlist.c
+++ b/fs/ntfs/runlist.c
@@ -1770,7 +1770,7 @@ s64 ntfs_rl_get_compressed_size(struct ntfs_volume *vol, struct runlist_element
 static inline bool ntfs_rle_lcn_contiguous(struct runlist_element *left_rle,
 					   struct runlist_element *right_rle)
 {
-	if (left_rle->lcn > LCN_HOLE &&
+	if (left_rle->lcn >= 0 &&
 	    left_rle->lcn + left_rle->length == right_rle->lcn)
 		return true;
 	else if (left_rle->lcn == LCN_HOLE && right_rle->lcn == LCN_HOLE)
@@ -1832,7 +1832,8 @@ struct runlist_element *ntfs_rl_insert_range(struct runlist_element *dst_rl, int
 
 		i_rl[0].vcn = start_vcn;
 		i_rl[0].length -= dst_rl_split.length;
-		i_rl[0].lcn += dst_rl_split.length;
+		if (i_rl[0].lcn >= 0)
+			i_rl[0].lcn += dst_rl_split.length;
 	} else {
 		struct runlist_element *dst_rle, *src_rle;
 merge_src_rle:
@@ -1988,7 +1989,7 @@ struct runlist_element *ntfs_rl_punch_hole(struct runlist_element *dst_rl, int d
 
 		(*punch_rl)[0].vcn = start_vcn;
 		(*punch_rl)[0].length -= first_cnt;
-		if ((*punch_rl)[0].lcn > LCN_HOLE)
+		if ((*punch_rl)[0].lcn >= 0)
 			(*punch_rl)[0].lcn += first_cnt;
 	}
 
@@ -2008,7 +2009,7 @@ struct runlist_element *ntfs_rl_punch_hole(struct runlist_element *dst_rl, int d
 
 		new_rl[new_1st_cnt + 1].vcn = end_vcn + 1;
 		new_rl[new_1st_cnt + 1].length -= first_cnt;
-		if (new_rl[new_1st_cnt + 1].lcn > LCN_HOLE)
+		if (new_rl[new_1st_cnt + 1].lcn >= 0)
 			new_rl[new_1st_cnt + 1].lcn += first_cnt;
 
 		if (one_split_3)
@@ -2136,7 +2137,7 @@ struct runlist_element *ntfs_rl_collapse_range(struct runlist_element *dst_rl, i
 
 		(*punch_rl)[0].vcn = start_vcn;
 		(*punch_rl)[0].length -= first_cnt;
-		if ((*punch_rl)[0].lcn > LCN_HOLE)
+		if ((*punch_rl)[0].lcn >= 0)
 			(*punch_rl)[0].lcn += first_cnt;
 	}
 
@@ -2150,7 +2151,7 @@ struct runlist_element *ntfs_rl_collapse_range(struct runlist_element *dst_rl, i
 
 		new_rl[new_1st_cnt].vcn = end_vcn + 1;
 		new_rl[new_1st_cnt].length -= first_cnt;
-		if (new_rl[new_1st_cnt].lcn > LCN_HOLE)
+		if (new_rl[new_1st_cnt].lcn >= 0)
 			new_rl[new_1st_cnt].lcn += first_cnt;
 
 		if (one_split_3)

-- 
2.56.1

