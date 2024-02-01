From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Feb 2024 22:05:44 +0800
Subject: [PATCH v2 3/3] mmc: hi6220_dw_mmc: add fifoth_val to private data
 and set it in .probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240201-mmc-v2-3-9f09dc1335fd@outlook.com>
References: <20240201-mmc-v2-0-9f09dc1335fd@outlook.com>
In-Reply-To: <20240201-mmc-v2-0-9f09dc1335fd@outlook.com>
To: Peng Fan <peng.fan@nxp.com>, Jaehoon Chung <jh80.chung@samsung.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706796342; l=1853;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=k/PjMbPi1J4MPo25pPuP0uhtm5RSzobNHIIRi+djbLo=;
 b=k4eZdCit7W3fOzhs+AeZoX48vbifXzpedgoIk+5esiHaeEzBxbnh3bJNwTT76ejPWx6HnDums
 styR28cCNZsBHyYaoQmZC53DUuVUL23gtrxl5akJ5lhPtvMR0pxt8Hp
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The value defaults to 0 and is ignored by dw_mmc code, so the other
users are not affected.

Setting this explicitly fixes some weird reading error found on Hi3798MV200.

Fixes: 8a5dc8140e62 ("mmc: hi6220_dw_mmc: add compatible for HC2910 support")

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/mmc/hi6220_dw_mmc.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/mmc/hi6220_dw_mmc.c b/drivers/mmc/hi6220_dw_mmc.c
index a4b8072976..dc0210402b 100644
--- a/drivers/mmc/hi6220_dw_mmc.c
+++ b/drivers/mmc/hi6220_dw_mmc.c
@@ -37,6 +37,7 @@ struct hi6220_dwmmc_priv_data {
 struct hisi_mmc_data {
 	unsigned int clock;
 	bool use_fifo;
+	u32 fifoth_val;
 };
 
 static int hi6220_dwmmc_of_to_plat(struct udevice *dev)
@@ -125,6 +126,7 @@ static int hi6220_dwmmc_probe(struct udevice *dev)
 	host->mmc = &plat->mmc;
 
 	host->fifo_mode = mmc_data->use_fifo;
+	host->fifoth_val = mmc_data->fifoth_val;
 	host->mmc->priv = &priv->host;
 	upriv->mmc = host->mmc;
 	host->mmc->dev = dev;
@@ -154,13 +156,20 @@ static const struct hisi_mmc_data hi6220_mmc_data = {
 	.use_fifo = false,
 };
 
+static const struct hisi_mmc_data hi3798mv2x_mmc_data = {
+	.clock = 50000000,
+	.use_fifo = false,
+	// FIFO depth is 256
+	.fifoth_val = MSIZE(4) | RX_WMARK(0x7f) | TX_WMARK(0x80),
+};
+
 static const struct udevice_id hi6220_dwmmc_ids[] = {
 	{ .compatible = "hisilicon,hi6220-dw-mshc",
 	  .data = (ulong)&hi6220_mmc_data },
 	{ .compatible = "hisilicon,hi3798cv200-dw-mshc",
 	  .data = (ulong)&hi6220_mmc_data },
 	{ .compatible = "hisilicon,hi3798mv200-dw-mshc",
-	  .data = (ulong)&hi6220_mmc_data },
+	  .data = (ulong)&hi3798mv2x_mmc_data },
 	{ .compatible = "hisilicon,hi3660-dw-mshc",
 	  .data = (ulong)&hi3660_mmc_data },
 	{ }

-- 
2.43.0

