From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 24 May 2025 11:14:36 +0200
Subject: [PATCH v4 1/5] media: i2c: imx214: Reorder imx214_parse_fwnode
 call
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250524-imx214_ccs_pll-v4-1-f7dc22e5255b@apitzsch.eu>
References: <20250524-imx214_ccs_pll-v4-0-f7dc22e5255b@apitzsch.eu>
In-Reply-To: <20250524-imx214_ccs_pll-v4-0-f7dc22e5255b@apitzsch.eu>
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
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Ricardo Ribalda <ribalda@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748078081; l=1268;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=75ElzgjAcPhkZmWR4bGwvMi9n8FDD5pHtp9QDNKGMck=;
 b=jYVZzwVgKN7KIEpkHSdsj/Gnm8CF3uEDjKWpT99zKlW/OFQGFDJCioQLjPyHrFU3MRhFbm3CJ
 iTWP76dLmNnBHXgGPDdMRIPkh1Ef0QWU1h4kO2lYQIzPjuMRIr9rcYn
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reorder imx214_parse_fwnode call to reduce goto paths in upcoming
patches.

No functional change intended.

Acked-by: Ricardo Ribalda <ribalda@chromium.org>
Reviewed-by: Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index dd7bc45523d8b5fcb3ec95728a6d32c4fddede72..0199195dcb7d12dc2ff253fe3eb77ddbcd0812a9 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -1261,10 +1261,6 @@ static int imx214_probe(struct i2c_client *client)
 	struct imx214 *imx214;
 	int ret;
 
-	ret = imx214_parse_fwnode(dev);
-	if (ret)
-		return ret;
-
 	imx214 = devm_kzalloc(dev, sizeof(*imx214), GFP_KERNEL);
 	if (!imx214)
 		return -ENOMEM;
@@ -1295,6 +1291,10 @@ static int imx214_probe(struct i2c_client *client)
 		return dev_err_probe(dev, PTR_ERR(imx214->regmap),
 				     "failed to initialize CCI\n");
 
+	ret = imx214_parse_fwnode(dev);
+	if (ret)
+		return ret;
+
 	v4l2_i2c_subdev_init(&imx214->sd, client, &imx214_subdev_ops);
 	imx214->sd.internal_ops = &imx214_internal_ops;
 

-- 
2.49.0

