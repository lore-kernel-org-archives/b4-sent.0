From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: perex@perex.cz, tiwai@suse.com, matthias.bgg@gmail.com, 
 angelogioacchino.delregno@collabora.com, linux-sound@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v2 2/2] ASoC: mediatek: mtk-btcvsd: bound bt_sram_addr[]
 writes in mtk_btcvsd_write_to_bt()
Date: Thu, 26 Nov 2026 00:53:16 +0000
Message-Id: <20261126005314.71606-3-iasnezhkov@gmail.com>
In-Reply-To: <20261126005314.71606-1-iasnezhkov@gmail.com>
References: <20261126005314.71606-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654395; l=2237;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=9ux9uWFLOH2k0sXAf5BIFccI/VfvFaqk+pxBS8OV1FQ=;
 b=sxViQTOIXvR9gTPR1kuw9wCzmYkm5MD0oresoHVsiSj8O4Gd+jsjJWH8N42jQz1v1X3BMCUEX
 dCBA1zT8fh0DHQKBL/He63v5rchZsgNHdPJMlR63kJMpTtpDya30zIN
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bt->tx->buffer_info.bt_sram_addr[] has a fixed capacity of 20 entries,
but mtk_btcvsd_write_to_bt() unconditionally increments num_valid_addr
and writes bt_sram_addr[next_idx] whenever a new SRAM offset is seen.

If more than 20 distinct SRAM offsets are ever observed (for instance
during BT subsystem resets or corrupted register reads), this writes
out of bounds past bt_sram_addr[19] into adjacent fields of
struct mtk_btcvsd_snd_hw_info and surrounding memory.

Check next_idx against ARRAY_SIZE(bt->tx->buffer_info.bt_sram_addr)
under tx_lock before storing the address and advancing num_valid_addr.

Found and drafted with an AI coding assistant while bringing up MT6789.

Fixes: 4bd8597dc36c ("ASoC: mediatek: add btcvsd driver")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 sound/soc/mediatek/common/mtk-btcvsd.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/sound/soc/mediatek/common/mtk-btcvsd.c b/sound/soc/mediatek/common/mtk-btcvsd.c
index 752856a..362d608 100644
--- a/sound/soc/mediatek/common/mtk-btcvsd.c
+++ b/sound/soc/mediatek/common/mtk-btcvsd.c
@@ -466,15 +466,22 @@ static int mtk_btcvsd_write_to_bt(struct mtk_btcvsd_snd *bt,
 	}
 	if (new_ap_addr_tx) {
 		unsigned int next_idx;
+		bool stored = false;
 
 		scoped_guard(spinlock_irqsave, &bt->tx_lock) {
-			bt->tx->buffer_info.num_valid_addr++;
-			next_idx = bt->tx->buffer_info.num_valid_addr - 1;
-			bt->tx->buffer_info.bt_sram_addr[next_idx] = ap_addr_tx;
+			next_idx = bt->tx->buffer_info.num_valid_addr;
+			if (next_idx < ARRAY_SIZE(bt->tx->buffer_info.bt_sram_addr)) {
+				bt->tx->buffer_info.bt_sram_addr[next_idx] = ap_addr_tx;
+				bt->tx->buffer_info.num_valid_addr = next_idx + 1;
+				stored = true;
+			}
 		}
-		dev_info(bt->dev, "%s(), new ap_addr_tx = 0x%lx, num_valid_addr %d\n",
-			 __func__, ap_addr_tx,
-			 bt->tx->buffer_info.num_valid_addr);
+		if (stored)
+			dev_info(bt->dev, "%s(), new ap_addr_tx = 0x%lx, num_valid_addr %u\n",
+				 __func__, ap_addr_tx, next_idx + 1);
+		else
+			dev_warn_once(bt->dev, "%s(), bt_sram_addr table full\n",
+				      __func__);
 	}
 
 	if (bt->tx->mute)
-- 
2.54.0 (Apple Git-157)


