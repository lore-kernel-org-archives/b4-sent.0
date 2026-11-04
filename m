From: Babis Danias <b.danias@tutamail.com>
Date: Wed, 04 Nov 2026 11:42:48 +0200
Subject: [PATCH 2/3] media: i2c: ov8856: Enable runtime PM before
 registering the sub-device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-ov8856-pm-fixes-v1-2-1958b730ce66@tutamail.com>
References: <20261104-ov8856-pm-fixes-v1-0-1958b730ce66@tutamail.com>
In-Reply-To: <20261104-ov8856-pm-fixes-v1-0-1958b730ce66@tutamail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Serin Yeh <serin.yeh@intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Robert Foss <rfoss@kernel.org>, Hans de Goede <hansg@kernel.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Kieran Bingham <kieran.bingham@ideasonboard.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Babis Danias <b.danias@tutamail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793785376; l=3065;
 i=b.danias@tutamail.com; s=20261103; h=from:subject:message-id;
 bh=rio8Ofl7JAOdPxjbb0My+vg5aCRf/Neov9MPh8InP7c=;
 b=Xd/bDsiTeDb3b9wbUGceRefwIPGyKMVOY70n0EcT6npYcEB4o4gzVl2tdVCHgQfhDz7AlqE8k
 qZMAB9PuKe6A3PTqiKH9P7R9D+DIAsUePRfoplEwpDXrQOvqGAefh2j
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
motor never showed up. Documentation/driver-api/media/v4l2-subdev.rst
asks drivers to enable runtime PM before registering the sub-device.

Enable runtime PM first, and hold a usage reference until registration
is done, so that the sensor can't be suspended halfway through. Drop the
reference with pm_runtime_put(), which also lets the sensor suspend once
probe is done, as the old pm_runtime_idle() call did. If registration
fails, undo the runtime PM setup. The probe_error_media_entity_cleanup
label then has no users left, so remove it.

The problem was found, and this patch written, with the help of an AI
coding assistant (Claude Opus 5.5). See the cover letter for details.

Fixes: 879347f0c258 ("media: ov8856: Add support for OV8856 sensor")
Cc: stable@vger.kernel.org
Signed-off-by: Babis Danias <b.danias@tutamail.com>
---
 drivers/media/i2c/ov8856.c | 23 ++++++++++++++++-------
 1 file changed, 16 insertions(+), 7 deletions(-)

diff --git a/drivers/media/i2c/ov8856.c b/drivers/media/i2c/ov8856.c
index 988ce0310..f9bcdd412 100644
--- a/drivers/media/i2c/ov8856.c
+++ b/drivers/media/i2c/ov8856.c
@@ -2425,22 +2425,31 @@ static int ov8856_probe(struct i2c_client *client)
 		goto probe_error_v4l2_ctrl_handler_free;
 	}
 
+	/* Set the device's state to active if it's in D0 state. */
+	if (full_power)
+		pm_runtime_set_active(ov8856->dev);
+	/*
+	 * The sub-device can be used as soon as it is registered, so enable
+	 * runtime PM first, and hold a reference until registration is done.
+	 */
+	pm_runtime_get_noresume(ov8856->dev);
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
-	pm_runtime_idle(ov8856->dev);
+	pm_runtime_put(ov8856->dev);
 
 	return 0;
 
-probe_error_media_entity_cleanup:
+probe_error_pm_runtime_disable:
+	pm_runtime_disable(ov8856->dev);
+	pm_runtime_set_suspended(ov8856->dev);
+	pm_runtime_put_noidle(ov8856->dev);
 	media_entity_cleanup(&ov8856->sd.entity);
 
 probe_error_v4l2_ctrl_handler_free:

-- 
2.56.0

