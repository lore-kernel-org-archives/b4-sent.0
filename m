From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 08 Mar 2025 22:47:58 +0100
Subject: [PATCH RESEND 4/4] media: i2c: imx214: Add support for 23.88MHz
 clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250308-imx214_clk_freq-v1-4-467a4c083c35@apitzsch.eu>
References: <20250308-imx214_clk_freq-v1-0-467a4c083c35@apitzsch.eu>
In-Reply-To: <20250308-imx214_clk_freq-v1-0-467a4c083c35@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741470489; l=2166;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=WazSPfo9iHxmaDrm3SErM4Vh2VDI2d/EHPhwKDpeOK0=;
 b=9FuClyeXyAMC4vqo/KrMlBMy2FxYhXKiRyuEQ6X/GiABtnb+qz4HmAW41Ze4+ALTYE+RYFYIb
 0X6ehEiIaHLA+5xaZx9Q4/kdKFKhktKqdBC4tX/ATg7SW6jee3qkgXG
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Qualcomm MSM8916 devices only provide an external clock of 23.88MHz.
Make the sensor usable by those devices by adding support for this
frequency.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index c3d55259d6fd1c4ca96f52833864bdfe6bedf13a..e24c76e01ab5070c073d082b1a2969cff3e17f9f 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -30,7 +30,10 @@
 
 #define IMX214_REG_FAST_STANDBY_CTRL	CCI_REG8(0x0106)
 
+#define IMX214_CLK_FREQ_23880KHZ	23880000
 #define IMX214_CLK_FREQ_24000KHZ	24000000
+
+#define IMX214_LINK_FREQ_597MHZ		597000000
 #define IMX214_LINK_FREQ_600MHZ		600000000
 /* Keep wrong link frequency for backward compatibility */
 #define IMX214_DEFAULT_LINK_FREQ_LEGACY	480000000
@@ -233,6 +236,7 @@ static const char * const imx214_supply_name[] = {
 #define IMX214_NUM_SUPPLIES ARRAY_SIZE(imx214_supply_name)
 
 static const s64 link_freq[] = {
+	IMX214_LINK_FREQ_597MHZ,
 	IMX214_LINK_FREQ_600MHZ,
 };
 
@@ -242,6 +246,10 @@ struct imx214_clk_params {
 };
 
 static const struct imx214_clk_params imx214_clk_params[] = {
+	{
+		.clk_freq = IMX214_CLK_FREQ_23880KHZ,
+		.link_freq = IMX214_LINK_FREQ_597MHZ,
+	},
 	{
 		.clk_freq = IMX214_CLK_FREQ_24000KHZ,
 		.link_freq = IMX214_LINK_FREQ_600MHZ,
@@ -1320,8 +1328,7 @@ static int imx214_parse_fwnode(struct device *dev, struct imx214 *imx214)
 
 	if (i == bus_cfg.nr_of_link_frequencies)
 		ret = dev_err_probe(dev, -EINVAL,
-				    "link-frequencies %d not supported, please review your DT\n",
-				    IMX214_LINK_FREQ_600MHZ);
+				    "provided link-frequencies not supported, please review your DT\n");
 
 done:
 	v4l2_fwnode_endpoint_free(&bus_cfg);
@@ -1359,6 +1366,7 @@ static int imx214_probe(struct i2c_client *client)
 	}
 
 	switch (xclk_freq) {
+	case IMX214_CLK_FREQ_23880KHZ:
 	case IMX214_CLK_FREQ_24000KHZ:
 		if (imx214->clk_params->clk_freq != xclk_freq)
 			return dev_err_probe(imx214->dev, -EINVAL,

-- 
2.48.1

