From: Jiucheng Xu <jiucheng.xu@amlogic.com>
Date: Sat, 20 Jun 2026 17:34:05 +0800
Subject: [PATCH] f2fs: fix FG GC failure when file in victim is pinned
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-origin-dev-v1-1-3b2e639e794c@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAIxeNmoC/x3MQQqAIBBA0avIrBMmA9GuEi1inGw2GgoRiHdPW
 r7F/w0qF+EKq2pQ+JEqOQ3MkwK6jhRZSxgGg8aiNahzkShJB3609xSIyC0OEUZwFz7l/Wfb3vs
 HUFYodlwAAAA=
X-Change-ID: 20260620-origin-dev-99cdccc83800
To: Jaegeuk Kim <jaegeuk@kernel.org>, Chao Yu <chao@kernel.org>
Cc: linux-f2fs-devel@lists.sourceforge.net, linux-kernel@vger.kernel.org, 
 jianxin.pan@amlogic.com, tuan.zhang@amlogic.com, 
 Jiucheng Xu <jiucheng.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781948046; l=1408;
 i=jiucheng.xu@amlogic.com; s=20250821; h=from:subject:message-id;
 bh=jxb8I4TnUJtPHsroLRoqXeQLJJ3g0yqJyXK0cin68SY=;
 b=0wXhatgMPTS5dc7I5i5bJ3pyFgVnevNTYeVkGK3tp06SbPEDSe6NQW8z+aZ1tlnOGmFYTQVkv
 ytHajwEBNytA88mid32RHSnx7pgiAshH3jae3kBJuL2MmyJGWKufa64
X-Developer-Key: i=jiucheng.xu@amlogic.com; a=ed25519;
 pk=Q18IjkdWCCuncSplyu+dYqIrm+n42glvoLFJTQqpb2o=
X-Endpoint-Received: by B4 Relay for jiucheng.xu@amlogic.com/20250821 with auth_id=498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When continuous write operations occur in the system, BG GC fails to
work. This leads to large dirty_segments and small free_segments. If
fallocate() is performed on a pinned file with the allocated space
exceeding the free_segment, FG_GC reclamation fails.

The reason is that the file corresponding to the block in the victim is
pinned, causing gc_data_segment() to fail. Since the condition sec_freed
< gc_control->nr_free_secs isn't satisfied, GC stops, resulting in the
failure of f2fs_fallocate() allocation.

Setting gc_control->nr_free_secs = 1 make FG GC continue searching
for new victim.

Signed-off-by: Jiucheng Xu <jiucheng.xu@amlogic.com>
---
 fs/f2fs/file.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/f2fs/file.c b/fs/f2fs/file.c
index 8acdd94272a0ced448e0ba21635d702cfec10682..3e49a73bbf3a184a314e97bff9509a66c27eac00 100644
--- a/fs/f2fs/file.c
+++ b/fs/f2fs/file.c
@@ -1883,7 +1883,7 @@ static int f2fs_expand_inode_data(struct inode *inode, loff_t offset,
 			.init_gc_type = FG_GC,
 			.should_migrate_blocks = false,
 			.err_gc_skipped = true,
-			.nr_free_secs = 0 };
+			.nr_free_secs = 1 };
 	pgoff_t pg_start, pg_end;
 	loff_t new_size;
 	loff_t off_end;

---
base-commit: b51f606aa323d553d786ed681a213f134dc688d6
change-id: 20260620-origin-dev-99cdccc83800

Best regards,
-- 
Jiucheng Xu <jiucheng.xu@amlogic.com>

