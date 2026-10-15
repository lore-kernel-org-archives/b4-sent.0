From: Radu Sabau <radu.sabau@analog.com>
Date: Thu, 15 Oct 2026 12:32:58 +0300
Subject: [PATCH v3 1/6] iio: imu: adis: Add optional self_test callback and
 fix custom reset dispatch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-adis16607-v3-1-f972d4efee85@analog.com>
References: <20261015-adis16607-v3-0-f972d4efee85@analog.com>
In-Reply-To: <20261015-adis16607-v3-0-f972d4efee85@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792056783; l=5233;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=UP8MCMap7fm+7qlHawjL4qK3DH6k7Iws3OMbHPds2Nk=;
 b=CMMexmzEJpLjQ/tJ4/0mtHfqfrDyskergDI2BKJSSTdYPAmfzgmRM6ZbMC6ZT9vQLEWE85t45
 ARzQRB3zR2uC00day8M/4nel86y9TPKYMHd2sM5HF7bQ5wYnCJKGS/f
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an optional self_test callback to struct adis_data, for devices
whose self-test doesn't fit the generic mask-write/sleep/check-status
sequence. Purely additive: defaults to NULL, no change for existing
drivers.

Also fix __adis_initial_startup()'s no-reset-gpio path: it called
__adis_reset() directly instead of adis->ops->reset(), silently
ignoring any driver's custom reset implementation. Invisible until now
since adis_default_ops.reset is __adis_reset() itself. Dispatch
through adis->ops->reset() instead, adding the settle-time sleep at
the call site for custom ops (documented not to sleep internally)
while skipping it for the default op (which already sleeps
internally).

Fixes: ecb010d44108 ("iio: imu: adis: Refactor adis_initial_startup")
Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis.c       | 30 +++++++++++++++++++++++-------
 include/linux/iio/imu/adis.h | 32 +++++++++++++++++++++++++++++++-
 2 files changed, 54 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/imu/adis.c b/drivers/iio/imu/adis.c
index a2bc1d14ed91..448046fd2ada 100644
--- a/drivers/iio/imu/adis.c
+++ b/drivers/iio/imu/adis.c
@@ -355,11 +355,20 @@ int __adis_reset(struct adis *adis)
 }
 EXPORT_SYMBOL_NS_GPL(__adis_reset, "IIO_ADIS_LIB");
 
+static const struct adis_ops adis_default_ops = {
+	.read = __adis_read_reg,
+	.write = __adis_write_reg,
+	.reset = __adis_reset,
+};
+
 static int adis_self_test(struct adis *adis)
 {
 	int ret;
 	const struct adis_timeout *timeouts = adis->data->timeouts;
 
+	if (adis->data->self_test)
+		return adis->data->self_test(adis);
+
 	ret = __adis_write_reg_16(adis, adis->data->self_test_reg,
 				  adis->data->self_test_mask);
 	if (ret) {
@@ -413,7 +422,20 @@ int __adis_initial_startup(struct adis *adis)
 		gpiod_set_value_cansleep(gpio, 0);
 		msleep(timeouts->reset_ms);
 	} else {
-		ret = __adis_reset(adis);
+		ret = adis->ops->reset(adis);
+		if (ret)
+			return ret;
+		/*
+		 * __adis_reset() already sleeps the settle time internally.
+		 * Custom reset ops are documented (struct adis_ops::reset)
+		 * not to, so sleep here for them.
+		 */
+		if (adis->ops->reset != __adis_reset)
+			msleep(timeouts->sw_reset_ms);
+	}
+
+	if (adis->data->post_reset_setup) {
+		ret = adis->data->post_reset_setup(adis);
 		if (ret)
 			return ret;
 	}
@@ -491,12 +513,6 @@ int adis_single_conversion(struct iio_dev *indio_dev,
 }
 EXPORT_SYMBOL_NS_GPL(adis_single_conversion, "IIO_ADISLIB");
 
-static const struct adis_ops adis_default_ops = {
-	.read = __adis_read_reg,
-	.write = __adis_write_reg,
-	.reset = __adis_reset,
-};
-
 /**
  * adis_init() - Initialize adis device structure
  * @adis:	The adis device
diff --git a/include/linux/iio/imu/adis.h b/include/linux/iio/imu/adis.h
index bfb6df68e6c9..5d0baeded3c9 100644
--- a/include/linux/iio/imu/adis.h
+++ b/include/linux/iio/imu/adis.h
@@ -10,6 +10,7 @@
 #define __IIO_ADIS_H__
 
 #include <linux/cleanup.h>
+#include <linux/delay.h>
 #include <linux/spi/spi.h>
 #include <linux/interrupt.h>
 #include <linux/iio/iio.h>
@@ -51,6 +52,18 @@ struct adis_timeout {
  * @self_test_mask: Bitmask of supported self-test operations
  * @self_test_reg: Register address to request self test command
  * @self_test_no_autoclear: True if device's self-test needs clear of ctrl reg
+ * @post_reset_setup: Optional device-specific hook called after reset,
+ *		before self-test. Not all ADIS devices need extra bring-up
+ *		between reset and self-test (SPI mode locking, status or
+ *		bootloader checks, pin or burst-mode configuration, etc.) -
+ *		only called when set. Must return 0 on success, a negative
+ *		error code otherwise.
+ * @self_test: Optional device-specific self-test override. When set,
+ *		it is called instead of the generic mask-write/sleep/
+ *		check-status sequence. The callback owns its own pass/fail
+ *		determination entirely (it should call __adis_check_status()
+ *		itself if it wants status-register checks). Must return 0 on
+ *		success, a negative error code otherwise.
  * @status_error_msgs: Array of error messages
  * @status_error_mask: Bitmask of errors supported by the device
  * @timeouts: Chip specific delays
@@ -81,6 +94,8 @@ struct adis_data {
 	unsigned int self_test_mask;
 	unsigned int self_test_reg;
 	bool self_test_no_autoclear;
+	int (*post_reset_setup)(struct adis *adis);
+	int (*self_test)(struct adis *adis);
 	const struct adis_timeout *timeouts;
 
 	const char * const *status_error_msgs;
@@ -171,8 +186,23 @@ int __adis_reset(struct adis *adis);
  */
 static inline int adis_reset(struct adis *adis)
 {
+	int ret;
+
 	guard(mutex)(&adis->state_lock);
-	return __adis_reset(adis);
+
+	ret = adis->ops->reset(adis);
+	if (ret)
+		return ret;
+
+	/*
+	 * __adis_reset() already sleeps the settle time internally. Custom
+	 * reset ops are documented (struct adis_ops::reset) not to, so sleep
+	 * here for them.
+	 */
+	if (adis->ops->reset != __adis_reset)
+		msleep(adis->data->timeouts->sw_reset_ms);
+
+	return 0;
 }
 
 int __adis_write_reg(struct adis *adis, unsigned int reg,

-- 
2.43.0

