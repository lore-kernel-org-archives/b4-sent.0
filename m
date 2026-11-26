From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: perex@perex.cz, tiwai@suse.com, matthias.bgg@gmail.com, 
 angelogioacchino.delregno@collabora.com, linux-sound@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v2 1/2] ASoC: mediatek: mtk-btcvsd: check bt_reg_pkt_w for
 0xdeadfeed in btcvsd_tx_clean_buffer()
Date: Thu, 26 Nov 2026 00:53:15 +0000
Message-Id: <20261126005314.71606-2-iasnezhkov@gmail.com>
In-Reply-To: <20261126005314.71606-1-iasnezhkov@gmail.com>
References: <20261126005314.71606-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654394; l=1768;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=od5JgiRPKhJS8T2nyAhO51juiYOD8biytma5Vs2f0n4=;
 b=0x0khT7NbeBEi+gu6pYGVAaIuWAMKLi2x60dVwh5I9qZLlynk19VXXXdkGP4QwFE7QcJubYOD
 pEl9zSUNn+cCkAw9SJpX6FkTwL1p337hT3xy+B8HqvWBaAgbkI/FWR3
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mtk_btcvsd_read_from_bt(), mtk_btcvsd_write_to_bt(), and the loopback
path in mtk_btcvsd_snd_irq_handler() all read *bt->bt_reg_pkt_w and
bail out on the 0xdeadfeed sentinel returned when BT connsys SRAM is
unpowered or resetting.

btcvsd_tx_clean_buffer(), called from mtk_pcm_btcvsd_hw_free() and the
TX mute path, writes mute frames directly to previously cached
bt_sram_addr[] addresses without checking whether BT connsys SRAM is
still powered. If BT entered sleep or reset after those addresses were
recorded, writing to the cached SRAM addresses accesses unpowered BT
SRAM under tx_lock.

Return 0 early when num_valid_addr is zero so closing an unused stream
does not touch BT registers, and otherwise verify *bt->bt_reg_pkt_w !=
0xdeadfeed under tx_lock before writing mute frames.

Found and drafted with an AI coding assistant while bringing up MT6789.

Fixes: 4bd8597dc36c ("ASoC: mediatek: add btcvsd driver")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 sound/soc/mediatek/common/mtk-btcvsd.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/sound/soc/mediatek/common/mtk-btcvsd.c b/sound/soc/mediatek/common/mtk-btcvsd.c
index 19329dd..752856a 100644
--- a/sound/soc/mediatek/common/mtk-btcvsd.c
+++ b/sound/soc/mediatek/common/mtk-btcvsd.c
@@ -335,6 +335,15 @@ static int btcvsd_tx_clean_buffer(struct mtk_btcvsd_snd *bt)
 	dev_info(bt->dev, "%s(), band %d, num_valid_addr %u\n",
 		 __func__, band, num_valid_addr);
 
+	if (!num_valid_addr)
+		return 0;
+
+	if (*bt->bt_reg_pkt_w == 0xdeadfeed) {
+		dev_warn(bt->dev, "%s(), connsys_addr_tx == 0xdeadfeed\n",
+			 __func__);
+		return -EIO;
+	}
+
 	for (i = 0; i < num_valid_addr; i++) {
 		void *dst;
 
-- 
2.54.0 (Apple Git-157)


