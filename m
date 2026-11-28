From: =?utf-8?q?Petr_Krac=C3=ADk?= <petrkr@petrkr.net>
Date: Sat, 28 Nov 2026 01:31:53 +0100
Subject: [PATCH] media: i2c: imx415: Use the new VBLANK value for SHR0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261128-imx415-vblank-fix-v1-1-0878e9928fd6@petrkr.net>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyML3czcChNDU92ypJzEvGzdtMwKXWOjFAvjRBPjlEQTMyWgvoKiVKA
 w2MzoWAi/uDQpKzW5BGSQUm0tAKoNT511AAAA
X-Change-ID: 20261128-imx415-vblank-fix-32d83a43da46
To: Michael Riesch <michael.riesch@collabora.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, =?utf-8?q?Petr_Krac=C3=ADk?= <petrkr@petrkr.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2315; i=petrkr@petrkr.net;
 h=from:subject:message-id; bh=YzHOjfOlYrYJXjwaPQuJDeigg1JsB6+2ebe+BLz+vpg=;
 b=owGbwMvMwCGcmL3AsYG1kZfxtFoSQzaXwl8hq411cRNXLw24ceZYpLh6g9ul/kfChrwHDjwOu
 /TVMUmgo5SFQZiDQVZMkWXbDs1pu7qc58++XmMEM4eVCWQIAxenAEykPYXhr/yTvP4PSUdXCTxw
 cyh5U5eTGLn999OX5tF+gTMqs1L0fjH8r3zx/gGT2rI3pj/EEg8JsV3xD9ugm6owzXD1xHsfw3b
 eFgUA
X-Developer-Key: i=petrkr@petrkr.net; a=openpgp;
 fpr=B6B82996BA8A439F9BD77C32616BA0418005810D
X-Endpoint-Received: by B4 Relay for petrkr@petrkr.net/default with auth_id=1672
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When V4L2_CID_VBLANK is set, imx415_s_ctrl() writes the new VMAX and then
falls through to the exposure case to program SHR0 = VMAX - exposure.
The exposure case computes VMAX from sensor->vblank->cur.val, which still
holds the old value at this point, because the control core updates
cur.val only after s_ctrl() has returned. SHR0 is therefore calculated
for the previous frame length. If the exposure control is not written
afterwards, SHR0 stays wrong and the actual exposure differs from the
requested one (for example when the frame rate is changed).

Take the VBLANK value from the control being set instead.

Fixes: 3bcae55ab96a ("media: i2c: imx415: Add read/write control of VBLANK")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Petr Kracík <petrkr@petrkr.net>
---
 drivers/media/i2c/imx415.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/imx415.c b/drivers/media/i2c/imx415.c
index 7bb27bdf1446..282dc0c3e021 100644
--- a/drivers/media/i2c/imx415.c
+++ b/drivers/media/i2c/imx415.c
@@ -697,6 +697,7 @@ static int imx415_s_ctrl(struct v4l2_ctrl *ctrl)
 	struct v4l2_subdev_state *state;
 	u32 exposure_max;
 	unsigned int vmax;
+	unsigned int vblank;
 	unsigned int flip;
 	int ret;
 
@@ -715,10 +716,14 @@ static int imx415_s_ctrl(struct v4l2_ctrl *ctrl)
 	if (!pm_runtime_get_if_in_use(sensor->dev))
 		return 0;
 
+	vblank = sensor->vblank->cur.val;
+
 	switch (ctrl->id) {
 	case V4L2_CID_VBLANK:
+		/* cur.val is updated only after s_ctrl returns */
+		vblank = ctrl->val;
 		ret = cci_write(sensor->regmap, IMX415_VMAX,
-				format->height + ctrl->val, NULL);
+				format->height + vblank, NULL);
 		if (ret)
 			break;
 		/*
@@ -729,7 +734,7 @@ static int imx415_s_ctrl(struct v4l2_ctrl *ctrl)
 		fallthrough;
 	case V4L2_CID_EXPOSURE:
 		/* clamp the exposure value to VMAX. */
-		vmax = format->height + sensor->vblank->cur.val;
+		vmax = format->height + vblank;
 		ctrl->val = min_t(int, ctrl->val, vmax);
 		ret = cci_write(sensor->regmap, IMX415_SHR0,
 				vmax - ctrl->val, NULL);

---
base-commit: 97d73c8251226cf27cc6656b4c542869bb8c69fa
change-id: 20261128-imx415-vblank-fix-32d83a43da46

Best regards,
--  
Petr Kracík <petrkr@petrkr.net>

