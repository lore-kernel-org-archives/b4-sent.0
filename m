From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Apr 2024 17:42:15 +0200
Subject: [PATCH v2 6/7] iio: adc: adi-axi-adc: support digital interface
 calibration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240426-ad9467-new-features-v2-6-6361fc3ba1cc@analog.com>
References: <20240426-ad9467-new-features-v2-0-6361fc3ba1cc@analog.com>
In-Reply-To: <20240426-ad9467-new-features-v2-0-6361fc3ba1cc@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714146147; l=5516;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=aB00ra411xRhssII5y4oXBZqdmEU9tdpGRfh6hUL/eE=;
 b=m2gp7LN+nCx2Jne7+GiKmRJg3THZW4RMHTNB0PeuU2wzBHwU4X1NO7J76uQN96marJcUYAErZ
 jAAm/oiGCBtBVZszQMb14XBYgBzuWZg2yqhuRc4ajx1PMy6i3DTHTDX
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the new IIO backend APIs for calibrating the data
digital interfaces.

While at it, removed the tabs in 'struct adi_axi_adc_state' and used
spaces for the members.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 121 +++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 119 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index b312369b7366..3a556e72f458 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -7,11 +7,13 @@
  */
 
 #include <linux/bitfield.h>
+#include <linux/cleanup.h>
 #include <linux/clk.h>
 #include <linux/err.h>
 #include <linux/io.h>
 #include <linux/delay.h>
 #include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/of.h>
 #include <linux/platform_device.h>
 #include <linux/property.h>
@@ -37,6 +39,9 @@
 #define   ADI_AXI_REG_RSTN_MMCM_RSTN		BIT(1)
 #define   ADI_AXI_REG_RSTN_RSTN			BIT(0)
 
+#define ADI_AXI_ADC_REG_CTRL			0x0044
+#define    ADI_AXI_ADC_CTRL_DDR_EDGESEL_MASK	BIT(1)
+
 /* ADC Channel controls */
 
 #define ADI_AXI_REG_CHAN_CTRL(c)		(0x0400 + (c) * 0x40)
@@ -51,14 +56,28 @@
 #define   ADI_AXI_REG_CHAN_CTRL_PN_TYPE_OWR	BIT(1)
 #define   ADI_AXI_REG_CHAN_CTRL_ENABLE		BIT(0)
 
+#define ADI_AXI_ADC_REG_CHAN_STATUS(c)		(0x0404 + (c) * 0x40)
+#define   ADI_AXI_ADC_CHAN_STAT_PN_MASK		GENMASK(2, 1)
+
+#define ADI_AXI_ADC_REG_CHAN_CTRL_3(c)		(0x0418 + (c) * 0x40)
+#define   ADI_AXI_ADC_CHAN_PN_SEL_MASK		GENMASK(19, 16)
+
+/* IO Delays */
+#define ADI_AXI_ADC_REG_DELAY(l)		(0x0800 + (l) * 0x4)
+#define   AXI_ADC_DELAY_CTRL_MASK		GENMASK(4, 0)
+
+#define ADI_AXI_ADC_MAX_IO_NUM_LANES		15
+
 #define ADI_AXI_REG_CHAN_CTRL_DEFAULTS		\
 	(ADI_AXI_REG_CHAN_CTRL_FMT_SIGNEXT |	\
 	 ADI_AXI_REG_CHAN_CTRL_FMT_EN |		\
 	 ADI_AXI_REG_CHAN_CTRL_ENABLE)
 
 struct adi_axi_adc_state {
-	struct regmap				*regmap;
-	struct device				*dev;
+	struct regmap *regmap;
+	struct device *dev;
+	/* lock to protect multiple accesses to the device registers */
+	struct mutex lock;
 };
 
 static int axi_adc_enable(struct iio_backend *back)
@@ -104,6 +123,100 @@ static int axi_adc_data_format_set(struct iio_backend *back, unsigned int chan,
 				  ADI_AXI_REG_CHAN_CTRL_FMT_MASK, val);
 }
 
+static int axi_adc_data_sample_trigger(struct iio_backend *back,
+				       enum iio_backend_sample_trigger trigger)
+{
+	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
+
+	switch (trigger) {
+	case IIO_BACKEND_SAMPLE_TRIGGER_EDGE_RISING:
+		return regmap_clear_bits(st->regmap, ADI_AXI_ADC_REG_CTRL,
+					 ADI_AXI_ADC_CTRL_DDR_EDGESEL_MASK);
+	case IIO_BACKEND_SAMPLE_TRIGGER_EDGE_FALLING:
+		return regmap_set_bits(st->regmap, ADI_AXI_ADC_REG_CTRL,
+				       ADI_AXI_ADC_CTRL_DDR_EDGESEL_MASK);
+	default:
+		return -EINVAL;
+	}
+}
+
+static int axi_adc_iodelays_set(struct iio_backend *back, unsigned int lane,
+				unsigned int tap)
+{
+	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
+	int ret;
+	u32 val;
+
+	if (tap > FIELD_MAX(AXI_ADC_DELAY_CTRL_MASK))
+		return -EINVAL;
+	if (lane > ADI_AXI_ADC_MAX_IO_NUM_LANES)
+		return -EINVAL;
+
+	guard(mutex)(&st->lock);
+	ret = regmap_write(st->regmap, ADI_AXI_ADC_REG_DELAY(lane), tap);
+	if (ret)
+		return ret;
+	/*
+	 * If readback is ~0, that means there are issues with the
+	 * delay_clk.
+	 */
+	ret = regmap_read(st->regmap, ADI_AXI_ADC_REG_DELAY(lane), &val);
+	if (ret)
+		return ret;
+	if (val == U32_MAX)
+		return -EIO;
+
+	return 0;
+}
+
+static int axi_adc_test_pattern_set(struct iio_backend *back,
+				    unsigned int chan,
+				    enum iio_backend_test_pattern pattern)
+{
+	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
+
+	switch (pattern) {
+	case IIO_BACKEND_NO_TEST_PATTERN:
+		/* nothing to do */
+		return 0;
+	case IIO_BACKEND_ADI_PRBS_9A:
+		return regmap_update_bits(st->regmap, ADI_AXI_ADC_REG_CHAN_CTRL_3(chan),
+					  ADI_AXI_ADC_CHAN_PN_SEL_MASK,
+					  FIELD_PREP(ADI_AXI_ADC_CHAN_PN_SEL_MASK, 0));
+	default:
+		return -EINVAL;
+	}
+}
+
+static int axi_adc_chan_status(struct iio_backend *back, unsigned int chan,
+			       bool *error)
+{
+	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
+	int ret;
+	u32 val;
+
+	guard(mutex)(&st->lock);
+	/* reset test bits by setting them */
+	ret = regmap_write(st->regmap, ADI_AXI_ADC_REG_CHAN_STATUS(chan),
+			   ADI_AXI_ADC_CHAN_STAT_PN_MASK);
+	if (ret)
+		return ret;
+
+	/* let's give enough time to validate or erroring the incoming pattern */
+	fsleep(1000);
+
+	ret = regmap_read(st->regmap, ADI_AXI_ADC_REG_CHAN_STATUS(chan), &val);
+	if (ret)
+		return ret;
+
+	if (ADI_AXI_ADC_CHAN_STAT_PN_MASK & val)
+		*error = true;
+	else
+		*error = false;
+
+	return 0;
+}
+
 static int axi_adc_chan_enable(struct iio_backend *back, unsigned int chan)
 {
 	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
@@ -166,6 +279,10 @@ static const struct iio_backend_ops adi_axi_adc_generic = {
 	.chan_disable = axi_adc_chan_disable,
 	.request_buffer = axi_adc_request_buffer,
 	.free_buffer = axi_adc_free_buffer,
+	.data_sample_trigger = axi_adc_data_sample_trigger,
+	.iodelay_set = axi_adc_iodelays_set,
+	.test_pattern_set = axi_adc_test_pattern_set,
+	.chan_status = axi_adc_chan_status,
 };
 
 static int adi_axi_adc_probe(struct platform_device *pdev)

-- 
2.44.0

