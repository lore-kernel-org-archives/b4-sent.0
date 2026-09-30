From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:20 +0800
Subject: [PATCH v2 02/21] media: i2c: it6625: propagate initial-setup and
 control-update errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-2-e353f887e7fa@ite.com.tw>
References: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
In-Reply-To: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=4296;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=90pok60+3e5gqhfAQTgKXaY0isPdDz9LBO2ZGVI6Tn4=;
 b=PqCigJcanrscKAcFYgk1zXuTgaYEzvulO7YUS/M7fcdeWN0lnHh+JH5WNttIidKcAHSN9KBOP
 tgt+yZ4970wBZsZyjgEQXkYNlMmoa02UuZiDzoghmZZgYi31l1cKYUA
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_initial_setup() discarded every register write's return value
internally, and probe() logged but did not propagate a failed
it6625_v4l2_sd_ctrl_update() call; either way, probe() always
registered the subdev regardless of failure.

Make both functions return int, propagate the first error, and fail
probe() with dev_err_probe() when either one fails.

None of the three controls has a driver .ops, so the only failure path
in v4l2_ctrl_s_ctrl() is range validation, and every value this driver
passes is always in range -- this is an error-handling correctness fix
responsive to review, not a fix for an observed runtime failure.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 64 ++++++++++++++++++++++++++++++++++++----------
 1 file changed, 50 insertions(+), 14 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 25f9e61a7b03ff228ed61a99c41248036035881f..485e1667c7bea34b152ff3dde09a928f334d71aa 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -889,11 +889,19 @@ static int it6625_s_ctrl_audio_present(struct v4l2_subdev *sd)
 				audio_present(it6625));
 }
 
-static void it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
+static int it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
 {
-	it6625_s_ctrl_detect_hdmi_5v(sd);
-	it6625_s_ctrl_audio_sampling_rate(sd);
-	it6625_s_ctrl_audio_present(sd);
+	int ret;
+
+	ret = it6625_s_ctrl_detect_hdmi_5v(sd);
+	if (ret)
+		return ret;
+
+	ret = it6625_s_ctrl_audio_sampling_rate(sd);
+	if (ret)
+		return ret;
+
+	return it6625_s_ctrl_audio_present(sd);
 }
 
 static void it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
@@ -940,9 +948,10 @@ static inline unsigned int fps_from_bt_timings(const struct v4l2_bt_timings *t)
 				 V4L2_DV_BT_FRAME_WIDTH(t));
 }
 
-static void it6625_initial_setup(struct it6625 *it6625)
+static int it6625_initial_setup(struct it6625 *it6625)
 {
 	int val = 0;
+	int err;
 
 	guard(mutex)(&it6625->it6625_lock);
 
@@ -968,13 +977,28 @@ static void it6625_initial_setup(struct it6625 *it6625)
 	if (it6625->port_num == 2)
 		val |= FIELD_PREP(B_MIPI_SPLIT, 1);
 
-	it6625_write_byte(it6625, REG_MIPI_CFG, val);
-	it6625_write_byte(it6625, REG_MIPI_DATA_TYPE, it6625->csi_format);
-	it6625_write_byte(it6625, REG_MIPI_CONTROL, 0x00);
-	it6625_write_byte(it6625, REG_RX_CFG, 0x00);
+	err = it6625_write_byte(it6625, REG_MIPI_CFG, val);
+	if (err)
+		return err;
+
+	err = it6625_write_byte(it6625, REG_MIPI_DATA_TYPE, it6625->csi_format);
+	if (err)
+		return err;
 
-	it6625_set_bits(it6625, REG_HOST_CTRL_INT, B_CONFIG_UPDATE, B_CONFIG_UPDATE);
-	it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+	err = it6625_write_byte(it6625, REG_MIPI_CONTROL, 0x00);
+	if (err)
+		return err;
+
+	err = it6625_write_byte(it6625, REG_RX_CFG, 0x00);
+	if (err)
+		return err;
+
+	err = it6625_set_bits(it6625, REG_HOST_CTRL_INT, B_CONFIG_UPDATE,
+			      B_CONFIG_UPDATE);
+	if (err)
+		return err;
+
+	return it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
 }
 
 static int it6625_cec_adap_enable(struct cec_adapter *adap, bool enable)
@@ -1136,9 +1160,12 @@ static void it6625_clear_timings(struct it6625 *it6625)
 static void it6625_irq_hdmi_5v_change(struct it6625 *it6625)
 {
 	struct v4l2_subdev *sd = &it6625->sd;
+	int ret;
 
 	it6625_clear_timings(it6625);
-	it6625_v4l2_sd_ctrl_update(sd);
+	ret = it6625_v4l2_sd_ctrl_update(sd);
+	if (ret)
+		dev_err(it6625->dev, "%s: failed to update controls: %d", __func__, ret);
 }
 
 static void it6625_irq_hdcp_change(struct it6625 *it6625)
@@ -2297,8 +2324,17 @@ static int it6625_probe(struct i2c_client *client)
 
 	it6625_debugfs_init(it6625, client);
 
-	it6625_initial_setup(it6625);
-	it6625_v4l2_sd_ctrl_update(sd);
+	err = it6625_initial_setup(it6625);
+	if (err) {
+		dev_err_probe(it6625->dev, err, "failed initial hardware setup");
+		goto err_clean_debugfs;
+	}
+
+	err = it6625_v4l2_sd_ctrl_update(sd);
+	if (err) {
+		dev_err_probe(it6625->dev, err, "failed to update controls");
+		goto err_clean_debugfs;
+	}
 
 	err = v4l2_async_register_subdev(sd);
 	if (err < 0) {

-- 
2.34.1

