From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: lee@kernel.org
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH] mfd: mt6358: fix MT6358_AUD_TOP and MT6358_MISC_TOP
 interrupt status bit shifts
Date: Wed, 25 Nov 2026 23:48:20 +0000
Message-Id: <20261125234820.94635-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795650500; l=1414;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=CJD3RtuSi+tWsdxFPCGavRJOeasqCKE/cFgR4AGmT1E=;
 b=jFumlAP5ZBfX9e8ufTxPUCAnsD5dqr3aDBM/ntE2X8rf8eBwGwpbG9ohmxiaM094HkUFERLBk
 sNCgBgUIjz4AeuhE33HEDaA310bImMeslbn6YyGC0w7ZklpNeHR8cvP
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In enum mt6358_irq_top_status_shift, MT6358_AUD_TOP immediately follows
MT6358_HK_TOP (5), assigning it bit 6 and MT6358_MISC_TOP bit 7.

On MT6358 and MT6366 hardware, TOP_INT_STATUS0 leaves bit 6 reserved
(corresponding to XPP_TOP on MT6357); AUD_TOP is bit 7 and MISC_TOP is
bit 8, matching MT6359_AUD_TOP = 7 in include/linux/mfd/mt6359/core.h,
MT6357_AUD_TOP (7) in include/linux/mfd/mt6357/core.h, and MediaTek's
downstream MT6358/MT6366 MFD headers.

Because mt6358_irq_handler() tests BIT(irqd->pmic_ints[i].top_offset)
against TOP_INT_STATUS0, audio, ACCDET, and SPI_CMD_ALERT interrupts
are never dispatched on MT6358/MT6366.

Set MT6358_AUD_TOP = 7 so MT6358_AUD_TOP is 7 and MT6358_MISC_TOP is 8.

Found and drafted with an AI coding assistant while auditing MT6366.

Fixes: 2b91c28f2abd ("mfd: Add support for the MediaTek MT6358 PMIC")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 include/linux/mfd/mt6358/core.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/mfd/mt6358/core.h b/include/linux/mfd/mt6358/core.h
index 68578e2..5c96607 100644
--- a/include/linux/mfd/mt6358/core.h
+++ b/include/linux/mfd/mt6358/core.h
@@ -32,7 +32,7 @@ enum mt6358_irq_top_status_shift {
 	MT6358_SCK_TOP,
 	MT6358_BM_TOP,
 	MT6358_HK_TOP,
-	MT6358_AUD_TOP,
+	MT6358_AUD_TOP = 7,
 	MT6358_MISC_TOP,
 };
 
-- 
2.54.0 (Apple Git-157)


