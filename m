From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 29 Jun 2025 16:49:21 +0200
Subject: [PATCH 2/5] media: i2c: imx214: Drop dev argument from
 imx214_parse_fwnode()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250629-imx214_fixes-v1-2-873eb94ad635@apitzsch.eu>
References: <20250629-imx214_fixes-v1-0-873eb94ad635@apitzsch.eu>
In-Reply-To: <20250629-imx214_fixes-v1-0-873eb94ad635@apitzsch.eu>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751208572; l=1136;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=H8sbCYlOjaNz8MFSGRXI5+CWm2oj7b1ROZKZiNJw/+w=;
 b=EwHc5RkncTt1il5EMiaBdzTUq8h+sx9f1TwoYqosEzn6OZBYIkW//FTQ34PCkCHngr7JRVZbO
 u2pkNwFoWASAZITq5EHYyKlv9q3/QYXmrfq2mfTd7+iSW/EJkk/lOCr
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The device can be accessed from struct imx214.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 8e9b5c9c93b0888f3d6be857168711edaf050db3..d9193bafa3cbb8fec2679200c38d30077d1b11bd 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -1324,10 +1324,11 @@ static int imx214_identify_module(struct imx214 *imx214)
 	return 0;
 }
 
-static int imx214_parse_fwnode(struct device *dev, struct imx214 *imx214)
+static int imx214_parse_fwnode(struct imx214 *imx214)
 {
 	struct v4l2_fwnode_endpoint *bus_cfg = &imx214->bus_cfg;
 	struct fwnode_handle *endpoint;
+	struct device *dev = imx214->dev;
 	unsigned int i;
 	int ret;
 
@@ -1415,7 +1416,7 @@ static int imx214_probe(struct i2c_client *client)
 		return dev_err_probe(dev, PTR_ERR(imx214->regmap),
 				     "failed to initialize CCI\n");
 
-	ret = imx214_parse_fwnode(dev, imx214);
+	ret = imx214_parse_fwnode(imx214);
 	if (ret)
 		return ret;
 

-- 
2.50.0

