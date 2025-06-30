From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 30 Jun 2025 21:05:23 +0200
Subject: [PATCH v2 3/5] media: i2c: imx214: Use __free(fwnode_handle)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250630-imx214_fixes-v2-3-cd1a76c412c0@apitzsch.eu>
References: <20250630-imx214_fixes-v2-0-cd1a76c412c0@apitzsch.eu>
In-Reply-To: <20250630-imx214_fixes-v2-0-cd1a76c412c0@apitzsch.eu>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Markus Elfring <Markus.Elfring@web.de>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751310420; l=1454;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=tZsctISDnJnONVzhuovrPsRYlzaU3GibT4KV2gK2N3U=;
 b=sOBUZlCZNxB8y8lgX1Eu43HcTcTRBwONrDdF5xbtn591NECKv0Mo3v1NQNY3dCEbS51EmR9cb
 Fs60WG8VdZ+B4Mul/ZoXA9ygNZC3UskjjfjIwkTwz2omhTy4AvUIq4F
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the __free(fwnode_handle) hook to free the endpoint when the
function exits to simplify the error path.

Reviewed-by: Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 9 +++------
 1 file changed, 3 insertions(+), 6 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index d9193bafa3cbb8fec2679200c38d30077d1b11bd..b84197ee5177d609b1395e14e1404ffa5b9a6dbf 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -1326,8 +1326,8 @@ static int imx214_identify_module(struct imx214 *imx214)
 
 static int imx214_parse_fwnode(struct imx214 *imx214)
 {
+	struct fwnode_handle *endpoint __free(fwnode_handle) = NULL;
 	struct v4l2_fwnode_endpoint *bus_cfg = &imx214->bus_cfg;
-	struct fwnode_handle *endpoint;
 	struct device *dev = imx214->dev;
 	unsigned int i;
 	int ret;
@@ -1338,11 +1338,8 @@ static int imx214_parse_fwnode(struct imx214 *imx214)
 
 	bus_cfg->bus_type = V4L2_MBUS_CSI2_DPHY;
 	ret = v4l2_fwnode_endpoint_alloc_parse(endpoint, bus_cfg);
-	fwnode_handle_put(endpoint);
-	if (ret) {
-		dev_err_probe(dev, ret, "parsing endpoint node failed\n");
-		goto error;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "parsing endpoint node failed\n");
 
 	/* Check the number of MIPI CSI2 data lanes */
 	if (bus_cfg->bus.mipi_csi2.num_data_lanes != 4) {

-- 
2.50.0

