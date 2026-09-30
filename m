From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:37 +0800
Subject: [PATCH v2 19/21] media: i2c: it6625: fold subdev initialization
 into probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-19-e353f887e7fa@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=3650;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=vQCYC2VyNScM7akssZx6ERVTpO9Oy/n/rXBGI50n3bg=;
 b=1D3wrTk1ndt1BvGfaWQ2D/rQwRoVp2R4ZxSVp8yVRaT353XQGjj0OxQBh6BUKWibHMjxf/Eg7
 5Wk14vWvAFxA89cdWXns71QOnymbjet89B/osyKd3fwR5+bDM3Q9+9Z
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_init_v4l2_subdev() split subdev/control-handler/media-entity
initialization out of probe(), which made error handling harder to
follow across the two functions and forced probe() to normalize every
init_v4l2_subdev() failure to -ENOMEM regardless of the real error
(e.g. a media_entity_pads_init() failure was reported to the caller as
-ENOMEM instead of its actual code).

Inline it into it6625_probe() so initialization and its unwind path
are visible together, and propagate the real error from
it6625_v4l2_init_controls() instead of replacing it. Cleanup behavior
on each failure path is unchanged: it6625_v4l2_init_controls() already
frees the control handler internally before returning an error, and a
media_entity_pads_init() failure still frees it explicitly before
unwinding, so neither path double-frees it through the later
err_clean_hdl label.

State finalization (v4l2_subdev_init_finalize()/cleanup()) is
deliberately left for a follow-up change, to keep this a pure
restructuring and keep the locking-model transition atomic on its own.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 46 +++++++++++++++++-----------------------------
 1 file changed, 17 insertions(+), 29 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index bc01e87490eeb478b33bf82f77652d6a2c5610cb..c3361727311d1ebbed072d9e7d25967231121cf5 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -2164,33 +2164,6 @@ static int it6625_parse_dt(struct it6625 *it6625)
 	return it6625_parse_endpoint(it6625);
 }
 
-static int it6625_init_v4l2_subdev(struct it6625 *it6625)
-{
-	struct v4l2_subdev *sd = &it6625->sd;
-	int err;
-
-	sd->dev = it6625->dev;
-
-	v4l2_i2c_subdev_init(sd, it6625->i2c_client, &it6625_ops);
-	sd->internal_ops = &it6625_internal_ops;
-	sd->flags |= V4L2_SUBDEV_FL_HAS_DEVNODE | V4L2_SUBDEV_FL_HAS_EVENTS;
-	if (it6625_v4l2_init_controls(sd)) {
-		dev_err(it6625->dev, "Failed to initialize v4l2 controls");
-		return -ENOMEM;
-	}
-
-	it6625->pad.flags = MEDIA_PAD_FL_SOURCE;
-	sd->entity.function = MEDIA_ENT_F_CAM_SENSOR;
-	err = media_entity_pads_init(&sd->entity, 1, &it6625->pad);
-	if (err < 0) {
-		dev_err(it6625->dev, "%s %d err=%d", __func__, __LINE__, err);
-		v4l2_ctrl_handler_free(sd->ctrl_handler);
-		return err;
-	}
-
-	return 0;
-}
-
 static int it6625_check_device(struct it6625 *it6625)
 {
 	static const u8 chip_ids[][2] = {
@@ -2276,9 +2249,23 @@ static int it6625_probe(struct i2c_client *client)
 	}
 
 	sd = &it6625->sd;
-	err = it6625_init_v4l2_subdev(it6625);
-	if (err)
+	v4l2_i2c_subdev_init(sd, it6625->i2c_client, &it6625_ops);
+	sd->internal_ops = &it6625_internal_ops;
+	sd->flags |= V4L2_SUBDEV_FL_HAS_DEVNODE | V4L2_SUBDEV_FL_HAS_EVENTS;
+
+	err = it6625_v4l2_init_controls(sd);
+	if (err) {
+		dev_err(it6625->dev, "failed to initialize v4l2 controls: %d", err);
 		goto err_clean_work_queues;
+	}
+
+	it6625->pad.flags = MEDIA_PAD_FL_SOURCE;
+	sd->entity.function = MEDIA_ENT_F_CAM_SENSOR;
+	err = media_entity_pads_init(&sd->entity, 1, &it6625->pad);
+	if (err < 0) {
+		dev_err(it6625->dev, "%s %d err=%d", __func__, __LINE__, err);
+		goto err_clean_ctrl_handler;
+	}
 
 	err = v4l2_ctrl_handler_setup(sd->ctrl_handler);
 	if (err)
@@ -2337,6 +2324,7 @@ static int it6625_probe(struct i2c_client *client)
 	cec_unregister_adapter(it6625->cec_adap);
 err_clean_hdl:
 	media_entity_cleanup(&sd->entity);
+err_clean_ctrl_handler:
 	v4l2_ctrl_handler_free(&it6625->hdl);
 
 err_clean_work_queues:

-- 
2.34.1

