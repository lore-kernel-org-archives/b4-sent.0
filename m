From: Babis Danias <b.danias@tutamail.com>
Date: Mon, 16 Nov 2026 18:04:00 +0200
Subject: [PATCH v2 2/2] media: i2c: ov8856: Enable runtime PM before
 registering the sub-device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-ov8856-pm-fixes-v2-2-7e41763164f2@tutamail.com>
References: <20261116-ov8856-pm-fixes-v2-0-7e41763164f2@tutamail.com>
In-Reply-To: <20261116-ov8856-pm-fixes-v2-0-7e41763164f2@tutamail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Tomasz Figa <tfiga@chromium.org>, 
 Hidenori Kobayashi <hidenorik@chromium.org>, Ben Kao <ben.kao@intel.com>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Serin Yeh <serin.yeh@intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Robert Foss <rfoss@kernel.org>, Hans de Goede <hansg@kernel.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Kieran Bingham <kieran.bingham@ideasonboard.com>, 
 Charles Drolet <linux@cdrolet.dev>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Babis Danias <b.danias@tutamail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794845041; l=2716;
 i=b.danias@tutamail.com; s=20261103; h=from:subject:message-id;
 bh=9Sob8EIPfCS4oIJbr5Hlz/DsJU9QMNnA5zdbHTCDRzQ=;
 b=dX1Osg17NALZ6SQbn7NyEfJHKqCb/plyYAXUo4Udcn5BNkv8QU63n67Jvb7DNUq0c8vA8SEzP
 gJnTyyzHyQ2CReTTivFaxKzwebDSaFxp6z1adKsqv0GY2E+k15LlCE4
X-Developer-Key: i=b.danias@tutamail.com; a=ed25519;
 pk=6DWeigdk0D3JwBjwvmxo9RW8cG8S1Eku42cb9PP+ghk=
X-Endpoint-Received: by B4 Relay for b.danias@tutamail.com/20261103 with auth_id=1406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ov8856_probe() registers the async sub-device before it enables runtime
PM. But the sub-device can be used as soon as it is registered. On ACPI
systems where ipu-bridge instantiates a VCM for the sensor, the bridge's
.bound() callback queues a work item that runtime-resumes the sensor.
If the work runs before probe reaches pm_runtime_enable(),
pm_runtime_get_sync() fails with -EACCES and the VCM is never created:

  [  213.265894] ov8856 i2c-OVTI8856:00: Error -13 runtime-resuming sensor, cannot instantiate VCM

On a Dell Latitude 7320 Detachable this happened on every bind of the
rear sensor after the IPU6 ISYS driver had probed, so the dw9714 focus
motor never showed up. On another unit of the same model, Charles Drolet
saw it on about one boot in four.
Documentation/driver-api/media/v4l2-subdev.rst asks drivers to enable
runtime PM before registering the sub-device.

Enable runtime PM before registering the sub-device. Keep the
pm_runtime_idle() call after registration, so that the sensor can still
suspend once probe is done. If registration fails, disable runtime PM
again and mark the device suspended. The probe_error_media_entity_cleanup
label then has no users left, so remove it.

Fixes: 879347f0c258 ("media: ov8856: Add support for OV8856 sensor")
Cc: stable@vger.kernel.org
Signed-off-by: Babis Danias <b.danias@tutamail.com>
---
 drivers/media/i2c/ov8856.c | 16 ++++++++++------
 1 file changed, 10 insertions(+), 6 deletions(-)

diff --git a/drivers/media/i2c/ov8856.c b/drivers/media/i2c/ov8856.c
index 18bae9db64..c8cb9ee882 100644
--- a/drivers/media/i2c/ov8856.c
+++ b/drivers/media/i2c/ov8856.c
@@ -2426,22 +2426,26 @@ static int ov8856_probe(struct i2c_client *client)
 		goto probe_error_v4l2_ctrl_handler_free;
 	}
 
+	/* Set the device's state to active if it's in D0 state. */
+	if (full_power)
+		pm_runtime_set_active(ov8856->dev);
+	/* The sub-device can be used as soon as it is registered. */
+	pm_runtime_enable(ov8856->dev);
+
 	ret = v4l2_async_register_subdev_sensor(&ov8856->sd);
 	if (ret < 0) {
 		dev_err(ov8856->dev, "failed to register V4L2 subdev: %d",
 			ret);
-		goto probe_error_media_entity_cleanup;
+		goto probe_error_pm_runtime_disable;
 	}
 
-	/* Set the device's state to active if it's in D0 state. */
-	if (full_power)
-		pm_runtime_set_active(ov8856->dev);
-	pm_runtime_enable(ov8856->dev);
 	pm_runtime_idle(ov8856->dev);
 
 	return 0;
 
-probe_error_media_entity_cleanup:
+probe_error_pm_runtime_disable:
+	pm_runtime_disable(ov8856->dev);
+	pm_runtime_set_suspended(ov8856->dev);
 	media_entity_cleanup(&ov8856->sd.entity);
 
 probe_error_v4l2_ctrl_handler_free:

-- 
2.56.0

