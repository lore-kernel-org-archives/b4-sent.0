From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 21 Jun 2025 11:37:29 +0200
Subject: [PATCH RESEND v4 5/5] media: i2c: imx214: Remove hard-coded
 external clock frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250621-imx214_ccs_pll-v4-5-12178e5eb989@apitzsch.eu>
References: <20250621-imx214_ccs_pll-v4-0-12178e5eb989@apitzsch.eu>
In-Reply-To: <20250621-imx214_ccs_pll-v4-0-12178e5eb989@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750498689; l=1261;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=ZCk329jfG7imBAJxPQK2Y7DPdg0WFnmIjBabbY8xuwc=;
 b=7u9/iEoHxGIF46EnZNgbPzTOeQMipucoawzdnk0Uu4+ERMs4QK/gbqXh6Ux3QTPvvLPnWHk0n
 nUmvF7eV3MnAbUxpZe/RbDaXAbU31N/8oTZemUb3gdaFHgw8psuYmCI
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead rely on the rate set on the clock (using assigned-clock-rates
etc.)

Reviewed-by: Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 6 ------
 1 file changed, 6 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index fd03650a5b2bbdbbc677d5797380285f1832baa5..a0cef9e61b41be8ea76a6d6e4b8c9fc4060cfa0f 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -32,7 +32,6 @@
 
 #define IMX214_REG_FAST_STANDBY_CTRL	CCI_REG8(0x0106)
 
-#define IMX214_DEFAULT_CLK_FREQ	24000000
 #define IMX214_DEFAULT_LINK_FREQ	600000000
 /* Keep wrong link frequency for backward compatibility */
 #define IMX214_DEFAULT_LINK_FREQ_LEGACY	480000000
@@ -1402,11 +1401,6 @@ static int imx214_probe(struct i2c_client *client)
 		return dev_err_probe(dev, PTR_ERR(imx214->xclk),
 				     "failed to get xclk\n");
 
-	ret = clk_set_rate(imx214->xclk, IMX214_DEFAULT_CLK_FREQ);
-	if (ret)
-		return dev_err_probe(dev, ret,
-				     "failed to set xclk frequency\n");
-
 	ret = imx214_get_regulators(dev, imx214);
 	if (ret < 0)
 		return dev_err_probe(dev, ret, "failed to get regulators\n");

-- 
2.50.0

