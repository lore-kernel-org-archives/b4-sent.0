From: ILYAS NHASSE <ilyas.nhasse@skf.com>
Date: Fri, 20 Nov 2026 12:26:48 +0100
Subject: [PATCH 2/2] iio: adc: ad_sigma_delta: support devices without RDY
 interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261120-ad7124-no-irq-v1-2-7826c5c3fd25@skf.com>
References: <20261120-ad7124-no-irq-v1-0-7826c5c3fd25@skf.com>
In-Reply-To: <20261120-ad7124-no-irq-v1-0-7826c5c3fd25@skf.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marcelo Schmitt <marcelo.schmitt@analog.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, ILYAS NHASSE <ilyas.nhasse@skf.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795174009; l=4847;
 i=ilyas.nhasse@skf.com; s=20261120; h=from:subject:message-id;
 bh=HkzT/yb82j6rKe0Wh5OPBoTT821E9QupBRs1skXiPo8=;
 b=1hP85xBznH4d7TuSarorWfpu5RkjyLmNxMEGy/wG2fGuVOF8OGKDMx2pJuvSvMecBgFRcDdHt
 l6yYl1GYOS3CNszA/vey0D5HX3jz7VB36TNdhCDfrkmzi2nGwN9Av7s
X-Developer-Key: i=ilyas.nhasse@skf.com; a=ed25519;
 pk=DeEyhWzUoP0HCAWFV/8oy5EFF+41tZxPpWZhfGyiMS4=
X-Endpoint-Received: by B4 Relay for ilyas.nhasse@skf.com/20261120 with auth_id=1581
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The end of a conversion or of a calibration is detected with the DOUT/RDY
interrupt, so a device whose DOUT/RDY pin is only wired to the SPI MISO
line can't be used, although its status register reports the same event
in its RDY bit.

For devices with registers but without interrupt, wait for RDY in
ad_sigma_delta_single_conversion() and ad_sd_calibrate() by polling the
status register, with the same timeouts as the interrupt-driven waits.
As with the interrupt, the bus stays locked and CS asserted during the
wait, and ad_sigma_delta_clear_pending_event() has drained any older
result beforehand, so the RDY bit seen by the poll belongs to the
operation just started. A timeout is reported as -ETIMEDOUT.

The RDY interrupt is the only trigger source of the triggered buffer, so
devm_ad_sd_setup_buffer_and_trigger() sets nothing up for these devices
and they only support direct mode. Registerless devices still require
the interrupt.

Each poll is a SPI transfer, so poll every 20 ms: this delays the
detection of the end of a conversion by at most one period, a fifth of
a conversion at the AD7124 default output data rate of 10 SPS, while
keeping the bus traffic, and the CPU time of PIO SPI transfers, low.

Nothing changes for devices with an interrupt.

Signed-off-by: ILYAS NHASSE <ilyas.nhasse@skf.com>
---
 drivers/iio/adc/ad_sigma_delta.c | 47 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 41 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/adc/ad_sigma_delta.c b/drivers/iio/adc/ad_sigma_delta.c
index 119ddc5a1..546135995 100644
--- a/drivers/iio/adc/ad_sigma_delta.c
+++ b/drivers/iio/adc/ad_sigma_delta.c
@@ -17,6 +17,7 @@
 #include <linux/find.h>
 #include <linux/gpio/consumer.h>
 #include <linux/interrupt.h>
+#include <linux/iopoll.h>
 #include <linux/module.h>
 #include <linux/property.h>
 #include <linux/slab.h>
@@ -43,6 +44,8 @@
 
 #define AD_SD_REG_STATUS_RDY	0x80
 
+#define AD_SD_POLL_PERIOD_US	(20 * USEC_PER_MSEC)
+
 /**
  * ad_sd_set_comm() - Set communications register
  *
@@ -347,6 +350,22 @@ static int ad_sigma_delta_clear_pending_event(struct ad_sigma_delta *sigma_delta
 	return ret;
 }
 
+static int ad_sd_poll_rdy(struct ad_sigma_delta *sigma_delta,
+			  unsigned int timeout_us)
+{
+	unsigned int status;
+	int ret, ret_read;
+
+	ret = read_poll_timeout(ad_sd_read_reg, ret_read,
+				ret_read || !(status & AD_SD_REG_STATUS_RDY),
+				AD_SD_POLL_PERIOD_US, timeout_us, false,
+				sigma_delta, AD_SD_REG_STATUS, 1, &status);
+	if (ret)
+		return ret;
+
+	return ret_read;
+}
+
 int ad_sd_calibrate(struct ad_sigma_delta *sigma_delta,
 	unsigned int mode, unsigned int channel)
 {
@@ -370,6 +389,11 @@ int ad_sd_calibrate(struct ad_sigma_delta *sigma_delta,
 	if (ret < 0)
 		goto out;
 
+	if (!sigma_delta->irq_line) {
+		ret = ad_sd_poll_rdy(sigma_delta, 2 * USEC_PER_SEC);
+		goto out;
+	}
+
 	ad_sd_enable_irq(sigma_delta);
 	time_left = wait_for_completion_timeout(&sigma_delta->completion, 2 * HZ);
 	if (time_left == 0) {
@@ -447,12 +471,16 @@ int ad_sigma_delta_single_conversion(struct iio_dev *indio_dev,
 
 	ad_sigma_delta_set_mode(sigma_delta, AD_SD_MODE_SINGLE);
 
-	ad_sd_enable_irq(sigma_delta);
-	ret = wait_for_completion_interruptible_timeout(
-			&sigma_delta->completion, HZ);
+	if (sigma_delta->irq_line) {
+		ad_sd_enable_irq(sigma_delta);
+		ret = wait_for_completion_interruptible_timeout(&sigma_delta->completion,
+								HZ);
 
-	if (ret == 0)
-		ret = -EIO;
+		if (ret == 0)
+			ret = -EIO;
+	} else {
+		ret = ad_sd_poll_rdy(sigma_delta, USEC_PER_SEC);
+	}
 	if (ret < 0)
 		goto out;
 
@@ -466,7 +494,8 @@ int ad_sigma_delta_single_conversion(struct iio_dev *indio_dev,
 		&raw_sample);
 
 out:
-	ad_sd_disable_irq(sigma_delta);
+	if (sigma_delta->irq_line)
+		ad_sd_disable_irq(sigma_delta);
 
 out_unlock:
 	sigma_delta->keep_cs_asserted = false;
@@ -816,12 +845,18 @@ static int devm_ad_sd_probe_trigger(struct device *dev, struct iio_dev *indio_de
  * devm_ad_sd_setup_buffer_and_trigger() - Device-managed buffer & trigger setup
  * @dev: Device object to which to bind the life-time of the resources attached
  * @indio_dev: The IIO device
+ *
+ * Nothing is set up for devices with registers but without R̅D̅Y̅ interrupt:
+ * they only support direct mode, with polled conversions.
  */
 int devm_ad_sd_setup_buffer_and_trigger(struct device *dev, struct iio_dev *indio_dev)
 {
 	struct ad_sigma_delta *sigma_delta = iio_device_get_drvdata(indio_dev);
 	int ret;
 
+	if (!sigma_delta->irq_line && sigma_delta->info->has_registers)
+		return 0;
+
 	sigma_delta->slots = devm_kcalloc(dev, sigma_delta->num_slots,
 					  sizeof(*sigma_delta->slots), GFP_KERNEL);
 	if (!sigma_delta->slots)

-- 
2.43.0

