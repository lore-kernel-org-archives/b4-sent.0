From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-spi@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH] spi: mt65xx: avoid division by zero when speed_hz is zero
Date: Thu, 26 Nov 2026 00:33:14 +0000
Message-Id: <20261126003314.49090-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795653194; l=1286;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=EATIDf77MiZZ99Ojdza/GsLWfdou7DzHCfNg7tDlYcg=;
 b=m7g3ptY0Ru5dhWfJGTBqNbiQNerQr4f2yzwodq/jQ8gf+QSArAGoVHVqHF7s32M3MRClM0Hf2
 hIs6EkndoZdCrsClfyjPaDDv6MQjUW3jvMI+SPbRtejjwvQytiEty2X
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spi-mt65xx does not set host->max_speed_hz, so if a slave device omits
spi-max-frequency in DT and a transfer leaves speed_hz unset,
__spi_validate() passes speed_hz == 0 to mtk_spi_prepare_transfer().

Because 0 < mdata->spi_clk_hz / 2 is true, DIV_ROUND_UP(mdata->spi_clk_hz,
speed_hz) divides by zero (undefined behavior; on arm64 udiv returns 0,
which then underflows sck_time - 1 to 0xffff).

Guard the division on speed_hz != 0 so zero speed falls back to div = 1.

Found and drafted with an AI coding assistant.

Fixes: a568231f4632 ("spi: mediatek: Add spi bus for Mediatek MT8173")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/spi/spi-mt65xx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/spi/spi-mt65xx.c b/drivers/spi/spi-mt65xx.c
index 8b4deef..2baea0c 100644
--- a/drivers/spi/spi-mt65xx.c
+++ b/drivers/spi/spi-mt65xx.c
@@ -509,7 +509,7 @@ static void mtk_spi_prepare_transfer(struct spi_controller *host,
 	u32 div, sck_time, reg_val;
 	struct mtk_spi *mdata = spi_controller_get_devdata(host);
 
-	if (speed_hz < mdata->spi_clk_hz / 2)
+	if (speed_hz && speed_hz < mdata->spi_clk_hz / 2)
 		div = DIV_ROUND_UP(mdata->spi_clk_hz, speed_hz);
 	else
 		div = 1;
-- 
2.54.0 (Apple Git-157)


