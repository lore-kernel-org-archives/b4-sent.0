From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 02 Aug 2024 16:27:04 +0200
Subject: [PATCH v2 6/8] iio: adc: adi-axi-adc: implement backend debugfs
 interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240802-dev-iio-backend-add-debugfs-v2-6-4cb62852f0d0@analog.com>
References: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
In-Reply-To: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722608829; l=2891;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=XHFm/DrRZn5PNuj0meI9AmjVqgEfxuUnbOTCPnlHqLs=;
 b=BOLMKKfjm8oM8fatrNj8iUyr9NjiaeMc6d7lU09nR+41/JNP95EMVIG1/9J/U6IZ/QOUGqO6b
 lrTT4nuHeOFAQezk82NJ32AOiQ9ZMXnxWvja8WCbQJ5p/Ln+XBdhFvG
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement debugfs options to read/write registers and print the channel
status into a buffer (so we may know better the cause for errors) .

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 41 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 41 insertions(+)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index 442a87024e1a..5c8c87eb36d1 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -61,6 +61,10 @@
 
 #define ADI_AXI_ADC_REG_CHAN_STATUS(c)		(0x0404 + (c) * 0x40)
 #define   ADI_AXI_ADC_CHAN_STAT_PN_MASK		GENMASK(2, 1)
+/* out of sync */
+#define   ADI_AXI_ADC_CHAN_STAT_PN_OOS		BIT(1)
+/* spurious out of sync */
+#define   ADI_AXI_ADC_CHAN_STAT_PN_ERR		BIT(2)
 
 #define ADI_AXI_ADC_REG_CHAN_CTRL_3(c)		(0x0418 + (c) * 0x40)
 #define   ADI_AXI_ADC_CHAN_PN_SEL_MASK		GENMASK(19, 16)
@@ -246,6 +250,30 @@ static int axi_adc_chan_status(struct iio_backend *back, unsigned int chan,
 	return 0;
 }
 
+static int axi_adc_debugfs_print_chan_status(struct iio_backend *back,
+					     unsigned int chan, char *buf,
+					     size_t len)
+{
+	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
+	u32 val;
+	int ret;
+
+	ret = axi_adc_read_chan_status(st, chan, &val);
+	if (ret)
+		return ret;
+
+	/*
+	 * PN_ERR is cleared in case out of sync is set. Hence, no point in
+	 * checking both bits.
+	 */
+	if (val & ADI_AXI_ADC_CHAN_STAT_PN_OOS)
+		return scnprintf(buf, len, "CH%u: Out of Sync.\n", chan);
+	if (val & ADI_AXI_ADC_CHAN_STAT_PN_ERR)
+		return scnprintf(buf, len, "CH%u: Spurious Out of Sync.\n", chan);
+
+	return scnprintf(buf, len, "CH%u: OK.\n", chan);
+}
+
 static int axi_adc_chan_enable(struct iio_backend *back, unsigned int chan)
 {
 	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
@@ -280,6 +308,17 @@ static void axi_adc_free_buffer(struct iio_backend *back,
 	iio_dmaengine_buffer_free(buffer);
 }
 
+static int axi_adc_reg_access(struct iio_backend *back, unsigned int reg,
+			      unsigned int writeval, unsigned int *readval)
+{
+	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
+
+	if (readval)
+		return regmap_read(st->regmap, reg, readval);
+
+	return regmap_write(st->regmap, reg, writeval);
+}
+
 static const struct regmap_config axi_adc_regmap_config = {
 	.val_bits = 32,
 	.reg_bits = 32,
@@ -298,6 +337,8 @@ static const struct iio_backend_ops adi_axi_adc_ops = {
 	.iodelay_set = axi_adc_iodelays_set,
 	.test_pattern_set = axi_adc_test_pattern_set,
 	.chan_status = axi_adc_chan_status,
+	.debugfs_reg_access = iio_backend_debugfs_ptr(axi_adc_reg_access),
+	.debugfs_print_chan_status = iio_backend_debugfs_ptr(axi_adc_debugfs_print_chan_status),
 };
 
 static const struct iio_backend_info adi_axi_adc_generic = {

-- 
2.45.2

