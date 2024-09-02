From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 02 Sep 2024 23:54:29 +0200
Subject: [PATCH 02/13] media: i2c: imx214: Remove unneeded goto
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240902-imx214-v1-2-c96cba989315@apitzsch.eu>
References: <20240902-imx214-v1-0-c96cba989315@apitzsch.eu>
In-Reply-To: <20240902-imx214-v1-0-c96cba989315@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725314079; l=1448;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=+EHNoEmtv/1kZSlndhZbuM8zP4Ms4i21sRmxvjbE1m0=;
 b=ZBWn6rlG+hqBQ6iO8z8r6ViyjrgcD7I32Nv/fAYf650Jgm97RWiXVDiD8BP9SDO+CgNed82vK
 +tcfXo5dcMMBAhegkYuRBXndDvDt+1KTcMK3G3aLPLa3+PGzD9jp4w1
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Simplify the imx214_start_streaming() by removing unneeded goto
statements, and the corresponding error label.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 13 ++++---------
 1 file changed, 4 insertions(+), 9 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 58f3c3f67e0d..283d4783c22e 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -776,7 +776,7 @@ static int imx214_start_streaming(struct imx214 *imx214)
 	ret = imx214_write_table(imx214, mode_table_common);
 	if (ret < 0) {
 		dev_err(imx214->dev, "could not sent common table %d\n", ret);
-		goto error;
+		return ret;
 	}
 
 	mode = v4l2_find_nearest_size(imx214_modes,
@@ -785,22 +785,17 @@ static int imx214_start_streaming(struct imx214 *imx214)
 	ret = imx214_write_table(imx214, mode->reg_table);
 	if (ret < 0) {
 		dev_err(imx214->dev, "could not sent mode table %d\n", ret);
-		goto error;
+		return ret;
 	}
 	ret = __v4l2_ctrl_handler_setup(&imx214->ctrls);
 	if (ret < 0) {
 		dev_err(imx214->dev, "could not sync v4l2 controls\n");
-		goto error;
+		return ret;
 	}
 	ret = regmap_write(imx214->regmap, IMX214_REG_MODE_SELECT, IMX214_MODE_STREAMING);
-	if (ret < 0) {
+	if (ret < 0)
 		dev_err(imx214->dev, "could not sent start table %d\n", ret);
-		goto error;
-	}
-
-	return 0;
 
-error:
 	return ret;
 }
 

-- 
2.46.0

