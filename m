From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: perex@perex.cz, tiwai@suse.com, matthias.bgg@gmail.com, 
 angelogioacchino.delregno@collabora.com, linux-sound@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH] ASoC: mediatek: mtk-btcvsd: guard against 0xdeadfeed in
 btcvsd_tx_clean_buffer()
Date: Wed, 25 Nov 2026 23:48:30 +0000
Message-Id: <20261125234830.94895-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795650510; l=1783;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=W9UyHqccaU9sJaYlkqCsX581VyBG8Z+037komTBj1Ts=;
 b=F9wU7UgJiGB2P7BStff8lAWPeen21Nkm66rJ9rRHWpCkZFY0WYH0G/B5l0W93ngFGlAbZw9Ud
 4ETAUZd1+ooDxOSjHeaJt/7+hfBhl3sX3fMZ/KatqJ8iz7nMHDgESuG
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mtk_btcvsd_read_from_bt() and mtk_btcvsd_write_to_bt() both reject the
0xdeadfeed sentinel returned by the BT connsys SRAM pointer register
when BT SRAM is unpowered or resetting, and check the SRAM address
before dereferencing it. btcvsd_tx_clean_buffer(), however, casts each
stored bt_sram_addr[] entry straight to a pointer and writes mute frames
through mtk_btcvsd_snd_data_transfer() without checking for 0xdeadfeed
or NULL.

If an invalid or reset SRAM address is recorded or cleared concurrently
around hw_free / mute transitions, btcvsd_tx_clean_buffer() dereferences
an invalid address in atomic context under tx_lock.

Skip any bt_sram_addr[] slot holding 0xdeadfeed or 0 before transferring
mute data.

Found and drafted with an AI coding assistant while bringing up MT6789.

Fixes: 4bd8597dc36c ("ASoC: mediatek: add btcvsd driver")
Fixes: d067b3378a78 ("ASoC: mediatek: mtk-btcvsd: Add checks for write and read of mtk_btcvsd_snd")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 sound/soc/mediatek/common/mtk-btcvsd.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/sound/soc/mediatek/common/mtk-btcvsd.c b/sound/soc/mediatek/common/mtk-btcvsd.c
index 19329dd..1f52567 100644
--- a/sound/soc/mediatek/common/mtk-btcvsd.c
+++ b/sound/soc/mediatek/common/mtk-btcvsd.c
@@ -341,6 +341,10 @@ static int btcvsd_tx_clean_buffer(struct mtk_btcvsd_snd *bt)
 		dev_info(bt->dev, "%s(), clean addr 0x%lx\n", __func__,
 			 bt->tx->buffer_info.bt_sram_addr[i]);
 
+		if (bt->tx->buffer_info.bt_sram_addr[i] == 0xdeadfeed ||
+		    !bt->tx->buffer_info.bt_sram_addr[i])
+			continue;
+
 		dst = (void *)bt->tx->buffer_info.bt_sram_addr[i];
 
 		mtk_btcvsd_snd_data_transfer(BT_SCO_DIRECT_ARM2BT,
-- 
2.54.0 (Apple Git-157)


