From: Fan Ye <fy15309206903@gmail.com>
Date: Mon, 10 Aug 2026 09:38:43 +0000
Subject: [PATCH] thunderbolt: Use min() for the DMA path credit cap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-tb-dma-credit-min-v1-1-1ea9d3847e7c@gmail.com>
X-B4-Tracking: v=1; b=H4sIACKceWoC/yXMQQqDMBBA0avIrDuQiGj0KtKFyUx1BKMksRTEu
 xvt8i3+PyByEI7QFQcE/kqU1WfoVwFuGvzIKJQNpSprZbTCZJGWAV1gkoSLeGyMNS3pqrXUQO6
 2wB/5Pc/+/Xfc7cwu3SM4zwuzgkX3dQAAAA==
X-Change-ID: 20260810-tb-dma-credit-min-78b89d149bd7
To: Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Andreas Noever <andreas.noever@gmail.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fan Ye <fy15309206903@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786354722; l=1319;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=xu76tpRxhyIN36dOBysJ1tAL6rwd3DghIfQIiVfsYhE=;
 b=jqWnKrgvjW6j0B80u8b+Vddx63b36o0xKfC7tnxw2k39fcYyzw4zMbTqiuu5+yrsgqFihV+e6
 T6xYaUFtMttDAmlrFkK0P1RN/mrTqMkb3jystyKRl+kwndb3XVYgljk
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tb_dma_reserve_credits() caps the request against what the adapter has
left by decrementing one credit at a time. The other arm of the same
if() already caps with min(port->total_credits, credits); use min()
here too.

No functional change: the object code is unchanged.

Assisted-by: Claude:claude-opus-5
Signed-off-by: Fan Ye <fy15309206903@gmail.com>
---
Verified by building drivers/thunderbolt/tunnel.o with and without this
patch (gcc 13.3.0, x86_64): objdump output is identical, a single cmovbe
either way.
---
 drivers/thunderbolt/tunnel.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index b7f32305f14a..e9214de5f3b7 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -1778,8 +1778,7 @@ static int tb_dma_reserve_credits(struct tb_path_hop *hop, unsigned int credits)
 		if (available < TB_MIN_DMA_CREDITS)
 			return -ENOSPC;
 
-		while (credits > available)
-			credits--;
+		credits = min(credits, available);
 
 		tb_port_dbg(port, "reserving %u credits for DMA path\n",
 			    credits);

---
base-commit: db2ddb87143519e20a95aa36c60b36107b736a58
change-id: 20260810-tb-dma-credit-min-78b89d149bd7

Best regards,
--  
Fan Ye <fy15309206903@gmail.com>

