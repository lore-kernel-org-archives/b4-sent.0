From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 16 Dec 2024 22:00:51 +0100
Subject: [PATCH v4 05/13] media: i2c: imx214: Drop IMX214_REG_EXPOSURE from
 mode reg arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241216-imx214-v4-5-8cbda160fbce@apitzsch.eu>
References: <20241216-imx214-v4-0-8cbda160fbce@apitzsch.eu>
In-Reply-To: <20241216-imx214-v4-0-8cbda160fbce@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Ricardo Ribalda <ribalda@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734382889; l=1197;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=Wt4lKgiTle4e7hLJrl5jH3tQeoO5pMkD6ZjLLk3ju6Y=;
 b=0TQdwxldUE/02+8nnajua7mLVAqMqjd+RwgV97/iPsvtGdm9H95YeofWYr2iNLFcAZ8Sf/PYO
 f3y7nYoylV/CNwRz4Up3mFPl6cDdkWdrWkMppdZZSEzlVYGZL8HHTxr
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IMX214_REG_EXPOSURE is configured twice, once with a hardcoded value
in the mode_<res> registers arrays, and once via v4l2_ctrl_ops. The
latter is enough, drop the former.

Acked-by: Ricardo Ribalda <ribalda@chromium.org>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 0789c149659cf98656312be575e5a7de1b8f5981..378720ad11b9421ce8a803da3072a980151667ba 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -254,7 +254,6 @@ static const struct cci_reg_sequence mode_4096x2304[] = {
 	{ CCI_REG8(0x3011), 0x00 },
 	{ IMX214_REG_STATS_OUT_EN, IMX214_STATS_OUT_ON },
 
-	{ IMX214_REG_EXPOSURE, IMX214_EXPOSURE_DEFAULT },
 	{ IMX214_REG_SHORT_EXPOSURE, 500 },
 
 	{ IMX214_REG_ANALOG_GAIN, 0 },
@@ -328,7 +327,6 @@ static const struct cci_reg_sequence mode_1920x1080[] = {
 	{ CCI_REG8(0x3011), 0x00 },
 	{ IMX214_REG_STATS_OUT_EN, IMX214_STATS_OUT_ON },
 
-	{ IMX214_REG_EXPOSURE, IMX214_EXPOSURE_DEFAULT },
 	{ IMX214_REG_SHORT_EXPOSURE, 500 },
 
 	{ IMX214_REG_ANALOG_GAIN, 0 },

-- 
2.47.1

