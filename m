From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Fri, 20 Dec 2024 14:26:04 +0100
Subject: [PATCH v6 05/13] media: i2c: imx214: Drop IMX214_REG_EXPOSURE from
 mode reg arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241220-imx214-v6-5-d90a185d82e5@apitzsch.eu>
References: <20241220-imx214-v6-0-d90a185d82e5@apitzsch.eu>
In-Reply-To: <20241220-imx214-v6-0-d90a185d82e5@apitzsch.eu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734701191; l=1197;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=xnGMMDNqIaP7nP/gicDjO9ZlDo7V8r+Yz/cn6oUDZ/k=;
 b=E84wLKihP+E0NgoalO9mxoOdxezqd0x9MFPPeku4QZoZFuqIdfAymjRNtIXr1VmH1nRrcXZ+q
 2hgOS7tNKpqAg6lHnO1mCAFIiyajYCJYhkd7aLEYmJG0jf6u1O6fDbL
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
index d40373aa7ac496b78bfdb90f1cc6e68b0e21faaa..4e9a8e0e2c5f2ac3fd72be06906979dcd3aaa2a4 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -252,7 +252,6 @@ static const struct cci_reg_sequence mode_4096x2304[] = {
 	{ CCI_REG8(0x3011), 0x00 },
 	{ IMX214_REG_STATS_OUT_EN, IMX214_STATS_OUT_ON },
 
-	{ IMX214_REG_EXPOSURE, IMX214_EXPOSURE_DEFAULT },
 	{ IMX214_REG_SHORT_EXPOSURE, 500 },
 
 	{ IMX214_REG_ANALOG_GAIN, 0 },
@@ -326,7 +325,6 @@ static const struct cci_reg_sequence mode_1920x1080[] = {
 	{ CCI_REG8(0x3011), 0x00 },
 	{ IMX214_REG_STATS_OUT_EN, IMX214_STATS_OUT_ON },
 
-	{ IMX214_REG_EXPOSURE, IMX214_EXPOSURE_DEFAULT },
 	{ IMX214_REG_SHORT_EXPOSURE, 500 },
 
 	{ IMX214_REG_ANALOG_GAIN, 0 },

-- 
2.47.1

