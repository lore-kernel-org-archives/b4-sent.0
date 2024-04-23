From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 23 Apr 2024 17:20:33 +0200
Subject: [PATCH v2 4/4] iio: common: scmi_iio: convert to dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240423-dev-add_dev_errp_probe-v2-4-12f43c5d8b0d@analog.com>
References: <20240423-dev-add_dev_errp_probe-v2-0-12f43c5d8b0d@analog.com>
In-Reply-To: <20240423-dev-add_dev_errp_probe-v2-0-12f43c5d8b0d@analog.com>
To: Petr Mladek <pmladek@suse.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Chris Down <chris@chrisdown.name>, John Ogness <john.ogness@linutronix.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Andi Shyti <andi.shyti@kernel.org>, Jyoti Bhayana <jbhayana@google.com>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713885641; l=3433;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ClJ3sRzkiojLcrvi0KpVZa+uYfx+C5zcG1LAl2kp8n8=;
 b=VN2nBviGoxHI3FJL9V7BAJfS9jU4cTEgtov2PPD9aWEKmHMliTcjcuctwHjvXVoKDRXsFq0lz
 APclNLIVmvbAAXJetoYeEU2tFiuLJPg5k8W5ParKCVUhDC+dXv26xUR
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of dev_err_probe() and dev_err_ptr_probe() to simplify error paths
during probe.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/common/scmi_sensors/scmi_iio.c | 45 +++++++++++++-----------------
 1 file changed, 19 insertions(+), 26 deletions(-)

diff --git a/drivers/iio/common/scmi_sensors/scmi_iio.c b/drivers/iio/common/scmi_sensors/scmi_iio.c
index 0c2caf3570db..841eda79a8cc 100644
--- a/drivers/iio/common/scmi_sensors/scmi_iio.c
+++ b/drivers/iio/common/scmi_sensors/scmi_iio.c
@@ -626,12 +626,10 @@ scmi_alloc_iiodev(struct scmi_device *sdev,
 				SCMI_PROTOCOL_SENSOR, SCMI_EVENT_SENSOR_UPDATE,
 				&sensor->sensor_info->id,
 				&sensor->sensor_update_nb);
-	if (ret) {
-		dev_err(&iiodev->dev,
-			"Error in registering sensor update notifier for sensor %s err %d",
-			sensor->sensor_info->name, ret);
-		return ERR_PTR(ret);
-	}
+	if (ret)
+		return dev_err_ptr_probe(&iiodev->dev, ret,
+					 "Error in registering sensor update notifier for sensor %s err %d",
+					 sensor->sensor_info->name, ret);
 
 	scmi_iio_set_timestamp_channel(&iio_channels[i], i);
 	iiodev->channels = iio_channels;
@@ -653,10 +651,9 @@ static int scmi_iio_dev_probe(struct scmi_device *sdev)
 		return -ENODEV;
 
 	sensor_ops = handle->devm_protocol_get(sdev, SCMI_PROTOCOL_SENSOR, &ph);
-	if (IS_ERR(sensor_ops)) {
-		dev_err(dev, "SCMI device has no sensor interface\n");
-		return PTR_ERR(sensor_ops);
-	}
+	if (IS_ERR(sensor_ops))
+		return dev_err_probe(dev, PTR_ERR(sensor_ops),
+				     "SCMI device has no sensor interface\n");
 
 	nr_sensors = sensor_ops->count_get(ph);
 	if (!nr_sensors) {
@@ -667,8 +664,8 @@ static int scmi_iio_dev_probe(struct scmi_device *sdev)
 	for (i = 0; i < nr_sensors; i++) {
 		sensor_info = sensor_ops->info_get(ph, i);
 		if (!sensor_info) {
-			dev_err(dev, "SCMI sensor %d has missing info\n", i);
-			return -EINVAL;
+			return dev_err_probe(dev, -EINVAL,
+					     "SCMI sensor %d has missing info\n", i);
 		}
 
 		/* This driver only supports 3-axis accel and gyro, skipping other sensors */
@@ -683,29 +680,25 @@ static int scmi_iio_dev_probe(struct scmi_device *sdev)
 		scmi_iio_dev = scmi_alloc_iiodev(sdev, sensor_ops, ph,
 						 sensor_info);
 		if (IS_ERR(scmi_iio_dev)) {
-			dev_err(dev,
-				"failed to allocate IIO device for sensor %s: %ld\n",
-				sensor_info->name, PTR_ERR(scmi_iio_dev));
-			return PTR_ERR(scmi_iio_dev);
+			return dev_err_probe(dev, PTR_ERR(scmi_iio_dev),
+					     "failed to allocate IIO device for sensor %s: %ld\n",
+					     sensor_info->name, PTR_ERR(scmi_iio_dev));
 		}
 
 		err = devm_iio_kfifo_buffer_setup(&scmi_iio_dev->dev,
 						  scmi_iio_dev,
 						  &scmi_iio_buffer_ops);
 		if (err < 0) {
-			dev_err(dev,
-				"IIO buffer setup error at sensor %s: %d\n",
-				sensor_info->name, err);
-			return err;
+			return dev_err_probe(dev, err,
+					     "IIO buffer setup error at sensor %s: %d\n",
+					     sensor_info->name, err);
 		}
 
 		err = devm_iio_device_register(dev, scmi_iio_dev);
-		if (err) {
-			dev_err(dev,
-				"IIO device registration failed at sensor %s: %d\n",
-				sensor_info->name, err);
-			return err;
-		}
+		if (err)
+			return dev_err_probe(dev, err,
+					     "IIO device registration failed at sensor %s: %d\n",
+					     sensor_info->name, err);
 	}
 	return err;
 }

-- 
2.44.0

