From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 07 Oct 2026 09:41:31 +0900
Subject: [PATCH] ext4: skip holes when shrinking the extent tree in fast
 commit replay
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261007-ext4-fc-replay-shrink-v1-1-0e45fc03030d@samsung.com>
X-B4-Tracking: v=1; b=H4sIADqVxWoC/x3MQQqEMAxA0atI1hNog5bqVWQW0kltmKFKKqKId
 7fM8i3+v6CwChcYmguUdymy5Ar7aiCkKc+M8qkGMuSsMQ752FqMAZXX33RiSSr5i6Gl3ntPZDs
 HtV2Voxz/7/i+7wftP2+UZwAAAA==
To: Theodore Ts'o <tytso@mit.edu>, linux-ext4@vger.kernel.org
Cc: Jan Kara <jack@suse.cz>, Andreas Dilger <adilger.kernel@dilger.ca>, 
 Baokun Li <libaokun@linux.alibaba.com>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, 
 "Ritesh Harjani (IBM)" <ritesh.list@gmail.com>, 
 Zhang Yi <yi.zhang@huawei.com>, Zhang Yi <yi.zhang@huaweicloud.com>, 
 Harshad Shirwadkar <harshadshirwadkar@gmail.com>, Li Chen <me@linux.beauty>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791333690; l=3028;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=9d0ePU+Z2uVyA8ZMCH2z+JohIkqRKRBLCKpFRrYMEkk=;
 b=uWk7CtWrwT45KwH64V76BnKJKrIrm5YwsyJfQn+gDU9NDiYld9yipQob6eDY+B1Tr4smMo4N2
 VG9HSFKxMWtCYvcLzIVVIyQKowYdqmp8vTjWYPxFQvUDDXQcgDurOkj
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ext4_ext_replay_shrink_inode() walks the extents of an inode from block
0 up to the given end and tries to merge each one with its neighbours.
When the walk is in a hole that follows an extent, ext4_find_extent()
returns that extent, and the walk moves on by a single block. Replay
calls it up to i_size after every ADD_RANGE and DEL_RANGE tag, so the
time recovery takes is proportional to the number of tags times the
number of hole blocks below i_size.

After a crash, mount can be busy for minutes. Replaying a single
ADD_RANGE tag, for one block written and fsynced in a sparse file with
a 1 TiB i_size, kept mount busy for 157 seconds. Replaying four fast
commits of a sparse file with 512 written regions (2048 ADD_RANGE tags,
and 2044 DEL_RANGE tags for the gaps between them) took 44 seconds when
the file was 64 MiB and 177 seconds when it was 256 MiB. With this
change the 1 TiB case takes less than 0.1 seconds, and the other two 3
seconds each.

When the walk is in such a hole, continue at the next extent, as
returned by ext4_ext_next_allocated_block(), or stop if there is none.
For each block skipped this way, the old walk found the same extent
again and retried the same merges, so the resulting tree is the same.

Fixes: 8016e29f4362 ("ext4: fast commit recovery path")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested in QEMU on ext4 dev 9091c97be340 with a 2 GiB file-backed virtio
disk and 4 KiB blocks, crashing by killing QEMU and timing mount(8).
Every fsynced block was verified and e2fsck -fn was clean in each run.
A 1 GiB file with 40 such fast commits (20480 ADD_RANGE and 20440
DEL_RANGE tags) took 31.5 seconds with this change. xfstests ext4/044
ext4/045 generic/455 generic/456 generic/482 with -O fast_commit give
the same results as without it (generic/455 fails on both, at different
marks).

The walk still visits every extent from block 0 for each tag. Bounding
it to the extents around the tag's range, or shrinking once per inode at
the end of replay, could be a follow-up.
---
 fs/ext4/extents.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/fs/ext4/extents.c b/fs/ext4/extents.c
index 836396ea79..df7e1ccb94 100644
--- a/fs/ext4/extents.c
+++ b/fs/ext4/extents.c
@@ -6217,8 +6217,10 @@ void ext4_ext_replay_shrink_inode(struct inode *inode, ext4_lblk_t end)
 		}
 		old_cur = cur;
 		cur = le32_to_cpu(ex->ee_block) + ext4_ext_get_actual_len(ex);
+		/* ex ends before old_cur, which is in a hole: skip the hole */
 		if (cur <= old_cur)
-			cur = old_cur + 1;
+			cur = max(old_cur + 1,
+				  ext4_ext_next_allocated_block(path));
 		ext4_ext_try_to_merge(NULL, inode, path, ex);
 		down_write(&EXT4_I(inode)->i_data_sem);
 		ext4_ext_dirty(NULL, inode, &path[path->p_depth]);

---
base-commit: 9091c97be34083587a75db174aab51551d8e8543
change-id: 20261006-ext4-fc-replay-shrink-c42988822156

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

