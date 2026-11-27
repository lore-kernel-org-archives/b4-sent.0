From: Fabio Forni <development@redaril.me>
Date: Sat, 28 Nov 2026 00:22:10 +0100
Subject: [PATCH v2 2/2] iio: afe: iio-rescale: Add platform IDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-iio_rescale_platform_ids-v2-2-4c35f16c4f77@redaril.me>
References: <20261128-iio_rescale_platform_ids-v2-0-4c35f16c4f77@redaril.me>
In-Reply-To: <20261128-iio_rescale_platform_ids-v2-0-4c35f16c4f77@redaril.me>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Peter Rosin <peda@lysator.liu.se>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: driver-core@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-iio@vger.kernel.org, Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2198;
 i=development@redaril.me; h=from:subject:message-id;
 bh=+PVgHL+3DkpqptfD2E18XEnVam67vefeMn6aj+Kl9CY=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLK5BDbNlek/4JOwjClMI4CvsbQ2SJLH1idQcLPmqWMvT
 9884abbUcrCIMbFICumyPLfyWhTt5mJ0a1+iVqYOaxMIEMYuDgFYCICsxj+l23g6Fk/W40ru0Ux
 c3V21z53Scl3XydmrZfj9GT4UHloGiPD4hkFVfE92gFFc9hClzXavJ2xduU3bam7TxibCheeqOV
 hBQA=
X-Developer-Key: i=development@redaril.me; a=openpgp;
 fpr=FF4232B28B363432DA8F187D81C2729AADA16A67
X-Endpoint-Received: by B4 Relay for development@redaril.me/default with auth_id=1033
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a rescaler is dynamically instantiated and configured with swnode,
device_get_match_data() will always set rescale->cfg to NULL, because
device_get_match_data() is unimplemented for software nodes.

Define a platform_device_id table (a replica of the of_device_id table)
and call the platform_get_match_data() helper, to deal with both
swnode-based and non-swnode-based instantiation methods.

Signed-off-by: Fabio Forni <development@redaril.me>
---
 drivers/iio/afe/iio-rescale.c | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/afe/iio-rescale.c b/drivers/iio/afe/iio-rescale.c
index c01292a15a29..c268dbaaaea6 100644
--- a/drivers/iio/afe/iio-rescale.c
+++ b/drivers/iio/afe/iio-rescale.c
@@ -518,6 +518,21 @@ static const struct of_device_id rescale_match[] = {
 };
 MODULE_DEVICE_TABLE(of, rescale_match);
 
+static const struct platform_device_id rescale_platform_ids[] = {
+	{ .name = "current-sense-amplifier",
+	  .driver_data = (kernel_ulong_t)&rescale_cfg[CURRENT_SENSE_AMPLIFIER] },
+	{ .name = "current-sense-shunt",
+	  .driver_data = (kernel_ulong_t)&rescale_cfg[CURRENT_SENSE_SHUNT] },
+	{ .name = "voltage-divider",
+	  .driver_data = (kernel_ulong_t)&rescale_cfg[VOLTAGE_DIVIDER] },
+	{ .name = "temperature-sense-rtd",
+	  .driver_data = (kernel_ulong_t)&rescale_cfg[TEMP_SENSE_RTD] },
+	{ .name = "temperature-transducer",
+	  .driver_data = (kernel_ulong_t)&rescale_cfg[TEMP_TRANSDUCER] },
+	{ }
+};
+MODULE_DEVICE_TABLE(platform, rescale_platform_ids);
+
 static int rescale_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
@@ -548,7 +563,7 @@ static int rescale_probe(struct platform_device *pdev)
 
 	rescale = iio_priv(indio_dev);
 
-	rescale->cfg = device_get_match_data(dev);
+	rescale->cfg = platform_get_match_data(pdev);
 	rescale->numerator = 1;
 	rescale->denominator = 1;
 	rescale->offset = 0;
@@ -603,6 +618,7 @@ static struct platform_driver rescale_driver = {
 		.name = "iio-rescale",
 		.of_match_table = rescale_match,
 	},
+	.id_table = rescale_platform_ids,
 };
 module_platform_driver(rescale_driver);
 

-- 
2.56.1

