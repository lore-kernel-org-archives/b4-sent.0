From: Zi-Hao Huang <zi-hao.huang@mediatek.com>
Date: Wed, 18 Nov 2026 10:31:42 +0800
Subject: [PATCH v2] block: fix PF_BLOCK_TS/current->plug ordering in
 blk_finish_plug()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-blk-plug-fix-v2-1-4acbeec5d512@mediatek.com>
X-B4-Tracking: v=1; b=H4sIAA0O/WoC/3WMyw6CMBAAf4Xs2TXdNSLx5H8YDi0ssOGZFomG9
 N+t3D3OJDM7BPEqAe7ZDl42DTpPCfiUQdXZqRXUOjGw4ZyIGN3Q4zK8Wmz0jY3JC2eYL64wkJL
 FS9LH7lkm7jSss/8c941+9s9oIyS8NZZtznR1Rf0YpVa7Sn+u5hHKGOMXW3GED6sAAAA=
X-Change-ID: 20261112-blk-plug-fix-f068b0223b80
To: Jens Axboe <axboe@kernel.dk>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chao Yu <chao@kernel.org>, stable@vger.kernel.org, 
 Zi-Hao Huang <zi-hao.huang@mediatek.com>, 
 Sandeep Dhavale <dhavale@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794969131; l=2708;
 i=zi-hao.huang@mediatek.com; s=20261112; h=from:subject:message-id;
 bh=yzVnLTZw+V0byMgdM9XGWdyVxiHY2j5nto3cl5zYTUw=;
 b=YreCA/+/lxEewEeUdbmQqFTXZK9vYT/ZIJn38ItYb2h92mIT9j114TDFWBTozc6GL+lHZXlrX
 496eudRghoJCRE0IrwkTnO0nnGdLBh5hc83YVTYF2yVzBYdKYnAh0Mm
X-Developer-Key: i=zi-hao.huang@mediatek.com; a=ed25519;
 pk=tbMIVegYSSBtz5MaQSUCX9RJO88MA/AI5cbmQKbaoIc=
X-Endpoint-Received: by B4 Relay for zi-hao.huang@mediatek.com/20261112 with auth_id=1493
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

blk_plug_invalidate_ts() runs on context switch and assumes that
PF_BLOCK_TS set implies current->plug != NULL. blk_finish_plug() breaks
this: it clears PF_BLOCK_TS in __blk_flush_plug() and then sets
current->plug = NULL, with plain accesses.

clang inlines __blk_flush_plug() and emits the store to current->plug
before the store that clears the flag (arm64, Android common kernel):

  ldr  w8, [x20, #0x44]     // w8 = current->flags
  str  xzr, [x20, #0xaa8]   // current->plug = NULL
  and  w8, w8, #0xdfffffff  // w8 &= ~PF_BLOCK_TS  <- preempted here
  str  w8, [x20, #0x44]     // current->flags = w8

If an interrupt hits there and preempts the task, the task is later
scheduled back in with PF_BLOCK_TS set and no plug, and
blk_plug_invalidate_ts() writes to NULL + 0x20 (plug->cur_ktime):

  Unable to handle kernel NULL pointer dereference at 0000000000000020
  pc : __schedule+0x108c
   preempt_schedule_irq+0x48/0xa8
   el1_interrupt+0x48/0x8c
   blk_finish_plug+0x6c/0x18c
   ext4_do_writepages+0xd3c/0xef8

The window is only a few instructions wide, so this is rare. It was hit
at cycle 127 of a warm reboot stress test.

Add a compiler barrier so the flag is cleared before the plug is
dropped. A compiler barrier is enough because the race is with
preemption of the same task on the same CPU. With the barrier, the same
build stores current->flags before current->plug.

Fixes: fad156c2af22 ("block: invalidate cached plug timestamp after task switch")
Cc: stable@vger.kernel.org
Signed-off-by: Zi-Hao Huang <zi-hao.huang@mediatek.com>
Reviewed-by: Sandeep Dhavale <dhavale@google.com>
---
Changes in v2:
- Point the Fixes tag at fad156c2af22, which dropped the NULL check and
  made the preemption race possible, and drop the stable version
  (Sandeep)
- Collect Reviewed-by
- Link to v1: https://lore.kernel.org/r/20261112-blk-plug-fix-v1-1-7fa2a6215b8d@mediatek.com
---
 block/blk-core.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/block/blk-core.c b/block/blk-core.c
index 8836c7028568..ad2a8e4fe7a8 100644
--- a/block/blk-core.c
+++ b/block/blk-core.c
@@ -1299,6 +1299,12 @@ void blk_finish_plug(struct blk_plug *plug)
 {
 	if (plug == current->plug) {
 		__blk_flush_plug(plug, false);
+		/*
+		 * blk_plug_invalidate_ts() runs on context switch and expects a
+		 * plug whenever PF_BLOCK_TS is set, so clear the flag (done in
+		 * __blk_flush_plug()) before dropping the plug.
+		 */
+		barrier();
 		current->plug = NULL;
 	}
 }

---
base-commit: 067c5c24cef23d913b67eaaf71ae67e7169a6620
change-id: 20261112-blk-plug-fix-f068b0223b80

Best regards,
-- 
Zi-Hao Huang <zi-hao.huang@mediatek.com>

