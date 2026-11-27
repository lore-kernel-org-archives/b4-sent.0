From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 Roman Vivchar <rva333@protonmail.com>, linux-spi@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v2] spi: mt65xx: set host->max_speed_hz in probe
Date: Fri, 27 Nov 2026 02:49:58 +0000
Message-Id: <20261127024958.8686-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795747798; l=2087;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=BHEc+LMfLY+B72htL0cr2zKEFVE9SAYFoEO0zNM8fBc=;
 b=DBC5DI8rLzSjNB7e94V8D1QT17kFycbLd5NUg1CceltKs4S3ZJvIEDGJUjybmYKQNV8H70PKs
 Ypvz0G2lGCzDQsCq6+T5dew+szLokLaPehr+AAD1u1rH0Ynt2fNyw5X
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spi-mt65xx leaves host->max_speed_hz unset (0). When a client device
omits spi-max-frequency in DT, spi_setup() keeps spi->max_speed_hz == 0,
and transfers or spi-mem ops without an explicit speed reach
mtk_spi_prepare_transfer() with speed_hz == 0 and mtk_spi_transfer_wait()
with mem->spi->max_speed_hz == 0, causing division by zero in both
DIV_ROUND_UP(mdata->spi_clk_hz, speed_hz) and
div_u64(ms, mem->spi->max_speed_hz).

Validate that spi_clk_hz is at least 2 Hz and set host->max_speed_hz to
mdata->spi_clk_hz / 2 (the controller's maximum SCK rate at div = 1,
sck_time = 1) so the SPI core populates spi->max_speed_hz,
xfer->speed_hz, and op->max_freq for all transfer paths.

Fixes: a568231f4632 ("spi: mediatek: Add spi bus for Mediatek MT8173")
Suggested-by: Roman Vivchar <rva333@protonmail.com>
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
Changes in v2:
- Set host->max_speed_hz = mdata->spi_clk_hz / 2 in mtk_spi_probe()
  (and reject spi_clk_hz < 2) instead of only guarding speed_hz in
  mtk_spi_prepare_transfer(), covering mtk_spi_transfer_wait() as well
  (suggested by Roman Vivchar).
- Move AI coding assistant disclosure below ---.
- Link to v1: https://lore.kernel.org/r/20261126003314.49090-1-iasnezhkov@gmail.com

Found and drafted with an AI coding assistant.

 drivers/spi/spi-mt65xx.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/spi/spi-mt65xx.c b/drivers/spi/spi-mt65xx.c
index 8b4deef..7e94b4d 100644
--- a/drivers/spi/spi-mt65xx.c
+++ b/drivers/spi/spi-mt65xx.c
@@ -1285,6 +1285,14 @@ static int mtk_spi_probe(struct platform_device *pdev)
 	}
 
 	mdata->spi_clk_hz = clk_get_rate(mdata->spi_clk);
+	if (mdata->spi_clk_hz < 2) {
+		clk_disable_unprepare(mdata->spi_clk);
+		clk_disable_unprepare(mdata->spi_hclk);
+		return dev_err_probe(dev, -EINVAL, "invalid spi-clk rate %u\n",
+				     mdata->spi_clk_hz);
+	}
+
+	host->max_speed_hz = mdata->spi_clk_hz / 2;
 
 	if (mdata->dev_comp->no_need_unprepare) {
 		clk_disable(mdata->spi_clk);
-- 
2.54.0 (Apple Git-157)


