From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Tue, 15 Apr 2025 23:22:18 +0200
Subject: [PATCH 4/4] media: i2c: imx214: Read clock frequency from device
 tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250415-imx214_ccs_pll-v1-4-d3d7748e5fbd@apitzsch.eu>
References: <20250415-imx214_ccs_pll-v1-0-d3d7748e5fbd@apitzsch.eu>
In-Reply-To: <20250415-imx214_ccs_pll-v1-0-d3d7748e5fbd@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744752164; l=1324;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=W4XT5Lp9JWmAz4BFUvUl0L/Hk6LPKxssT64tgrm1IVY=;
 b=GICm5MM8ywi46qLCUp5JA6cgoyQUX3Pu9McqjhMq3TcdkoyyVgkBVnbue9lgEO9gf46KBHe22
 F8EoLxh9UZ6DU4PGEpYVJ4Uvo45CyYXH7RPFHpGg3TC29Fdw+dEj/+Z
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the hard coded external clock frequency by the one read from
device tree.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 5589228d2b44417c0dbf15a6a17fd8f954f1a2bc..6d7f05073aa9ffb054d454771ce22e3141af60e8 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -1388,6 +1388,7 @@ static int imx214_probe(struct i2c_client *client)
 {
 	struct device *dev = &client->dev;
 	struct imx214 *imx214;
+	u32 xclk_freq;
 	int ret;
 
 	imx214 = devm_kzalloc(dev, sizeof(*imx214), GFP_KERNEL);
@@ -1401,7 +1402,14 @@ static int imx214_probe(struct i2c_client *client)
 		return dev_err_probe(dev, PTR_ERR(imx214->xclk),
 				     "failed to get xclk\n");
 
-	ret = clk_set_rate(imx214->xclk, IMX214_DEFAULT_CLK_FREQ);
+	ret = device_property_read_u32(dev, "clock-frequency", &xclk_freq);
+	if (ret) {
+		dev_warn(dev,
+			 "clock-frequency not set, please review your DT. Fallback to default\n");
+		xclk_freq = IMX214_DEFAULT_CLK_FREQ;
+	}
+
+	ret = clk_set_rate(imx214->xclk, xclk_freq);
 	if (ret)
 		return dev_err_probe(dev, ret,
 				     "failed to set xclk frequency\n");

-- 
2.49.0

