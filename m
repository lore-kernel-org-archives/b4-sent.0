From: Suyuan Wang <shyckless@gmail.com>
Date: Wed, 18 Nov 2026 12:53:20 +0000
Subject: [PATCH] f2fs: don't read inode->i_ino after iput() in
 gc_data_segment()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-f2fs-gc-v1-1-297612253f6c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAL+f/WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0ML3TSjtGLd9GRdI3NLI0Njs0RzAzNjJaDqgqLUtMwKsEnRsRB+cWl
 SVmpyCUi7Um0tACss0+drAAAA
X-Change-ID: 20261118-f2fs-gc-2792136a7063
To: jaegeuk@kernel.org, chao@kernel.org
Cc: linux-kernel@vger.kernel.org, linux-f2fs-devel@lists.sourceforge.net
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795006400; l=1817;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=CnaJBZLbNSkqbrUrG6Geieyu9/h+9hR1JQWRnrfCtG0=;
 b=gmxM3O37yU6iQwcn8i11c4Qjn9+9bQNCjnDuqrVqffwHf5d8hiGWVCyq2vaPTmw2NVbCSkv6H
 d5U2Xx0zn5ZClzra6lpw0eh25Uj5PSSm8QyV1/GXLzioyr6n3/nZmzv
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When gc_data_segment() finds an inode that has both the inline-data flag
and a data block, it puts the inode before logging the error:

	iput(inode);
	set_sbi_flag(sbi, SBI_NEED_FSCK);
	f2fs_err_ratelimited(sbi,
		"inode %llu has both inline_data flag and "
		"data block, nid=%u, ofs_in_node=%u",
		inode->i_ino, dni.nid, ofs_in_node);

At this point the inode has not been added to the GC inode list and
i_gc_rwsem has not been taken, so nothing else is holding it. iput()
may drop the last reference, so reading inode->i_ino for the message is
a use-after-free.

Move the iput() below the error message so i_ino is read while the
reference is still held.

Found with a static analysis tool and checked by hand.

Fixes: fc01008c92f4 ("f2fs: fix to do sanity check on F2FS_INLINE_DATA flag in inode during GC")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested only (x86_64, W=1 and sparse show no new warnings). The
use-after-free is in the corrupted-inode error path and hasn't been
reproduced at runtime.
---
 fs/f2fs/gc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/f2fs/gc.c b/fs/f2fs/gc.c
index 5b948c92f981..edbfb45f15fc 100644
--- a/fs/f2fs/gc.c
+++ b/fs/f2fs/gc.c
@@ -1664,12 +1664,12 @@ static int gc_data_segment(struct f2fs_sb_info *sbi, struct f2fs_summary *sum,
 			}
 
 			if (f2fs_has_inline_data(inode)) {
-				iput(inode);
 				set_sbi_flag(sbi, SBI_NEED_FSCK);
 				f2fs_err_ratelimited(sbi,
 					"inode %llu has both inline_data flag and "
 					"data block, nid=%u, ofs_in_node=%u",
 					inode->i_ino, dni.nid, ofs_in_node);
+				iput(inode);
 				continue;
 			}
 



