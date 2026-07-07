From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 07 Jul 2026 15:04:36 +0100
Subject: [PATCH v7 15/17] iio: frequency: ad9910: show channel priority in
 debugfs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-ad9910-iio-driver-v7-15-a4ec30f63700@analog.com>
References: <20260707-ad9910-iio-driver-v7-0-a4ec30f63700@analog.com>
In-Reply-To: <20260707-ad9910-iio-driver-v7-0-a4ec30f63700@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783433065; l=8242;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=WM9MrzcGI+gSnGv9gRAHywil9CxWElyT2oNdA6INYJU=;
 b=Tr/DjukmdGf1PfQQcc5SazZMtZpwiJVlcLYMb1NHOOYj7FchzxgetgETDNZtFsvC+/QlnxszO
 BzoFXfH2PVaApW6AWL7Cigy1CcITOd0VZsyfhaZyCoQe/rRMJhZDxIX
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expose frequency_source, phase_source and amplitude_source attributes in
debugfs. Those indicate from which channel the specific DDS parameter is
being sourced by returning its label. The implementation follows the
priority table found in the datasheet.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 187 ++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 186 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index e7d5415b7d07..2ea748e99082 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -22,6 +22,7 @@
 #include <linux/property.h>
 #include <linux/regulator/consumer.h>
 #include <linux/reset.h>
+#include <linux/seq_file.h>
 #include <linux/spi/spi.h>
 #include <linux/sysfs.h>
 #include <linux/types.h>
@@ -183,6 +184,11 @@
 #define AD9910_RAM_ENABLED(st)		\
 	FIELD_GET(AD9910_CFR1_RAM_ENABLE_MSK, (st)->reg[AD9910_REG_CFR1].val32)
 
+#define AD9910_DEST_FREQUENCY		0
+#define AD9910_DEST_PHASE		1
+#define AD9910_DEST_AMPLITUDE		2
+#define AD9910_DEST_POLAR		3
+
 /* PLL constants */
 #define AD9910_PLL_MIN_N		12
 #define AD9910_PLL_MAX_N		127
@@ -314,6 +320,14 @@ enum {
 	AD9910_CHAN_IDX_OSK,
 };
 
+enum {
+	AD9910_SCAN_IDX_AMP,
+	AD9910_SCAN_IDX_PHASE,
+	AD9910_SCAN_IDX_FREQ,
+	AD9910_SCAN_IDX_POLAR_AMP,
+	AD9910_SCAN_IDX_POLAR_PHASE,
+};
+
 enum {
 	AD9910_POWERDOWN,
 	AD9910_DWELL_EN,
@@ -2038,6 +2052,171 @@ static int ad9910_setup(struct device *dev, struct ad9910_state *st,
 	return ad9910_io_update(st);
 }
 
+static inline const char *ad9910_frequency_source_get(struct iio_dev *indio_dev)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	bool ram_en, mode_en;
+
+	guard(mutex)(&st->lock);
+
+	/* RAM enabled and data destination is frequency */
+	ram_en = AD9910_RAM_ENABLED(st);
+	if (ram_en && AD9910_DEST_FREQUENCY ==
+		      FIELD_GET(AD9910_CFR1_RAM_PLAYBACK_DEST_MSK,
+				st->reg[AD9910_REG_CFR1].val32))
+		return ad9910_channel_str[AD9910_CHAN_IDX_RAM];
+
+	/* DRG enabled and data destination is frequency */
+	mode_en = FIELD_GET(AD9910_CFR2_DRG_ENABLE_MSK,
+			    st->reg[AD9910_REG_CFR2].val32);
+	if (mode_en && AD9910_DEST_FREQUENCY ==
+		       FIELD_GET(AD9910_CFR2_DRG_DEST_MSK,
+				 st->reg[AD9910_REG_CFR2].val32))
+		return ad9910_channel_str[AD9910_CHAN_IDX_DRG_FREQ];
+
+	/* Parallel data port enabled and data destination is frequency */
+	mode_en = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+			    st->reg[AD9910_REG_CFR2].val32);
+	if (mode_en && indio_dev->active_scan_mask &&
+	    test_bit(AD9910_SCAN_IDX_FREQ, indio_dev->active_scan_mask))
+		return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_FREQ];
+
+	/* FTW: RAM enabled and data destination is phase, amplitude, or polar */
+	if (ram_en)
+		return ad9910_channel_str[AD9910_CHAN_IDX_RAM];
+
+	/* single tone profiles */
+	return ad9910_channel_str[AD9910_CHAN_IDX_PROFILE_0 + st->profile];
+}
+
+static int ad9910_frequency_source_show(struct seq_file *s, void *ignored)
+{
+	seq_printf(s, "%s\n", ad9910_frequency_source_get(s->private));
+	return 0;
+}
+DEFINE_SHOW_ATTRIBUTE(ad9910_frequency_source);
+
+static inline const char *ad9910_phase_source_get(struct iio_dev *indio_dev)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	bool ram_en, mode_en;
+	u32 destination;
+
+	guard(mutex)(&st->lock);
+
+	/* RAM enabled and data destination is phase or polar  */
+	ram_en = AD9910_RAM_ENABLED(st);
+	if (ram_en) {
+		destination = FIELD_GET(AD9910_CFR1_RAM_PLAYBACK_DEST_MSK,
+					st->reg[AD9910_REG_CFR1].val32);
+		if (destination == AD9910_DEST_PHASE ||
+		    destination == AD9910_DEST_POLAR)
+			return ad9910_channel_str[AD9910_CHAN_IDX_RAM];
+	}
+
+	/* DRG enabled and data destination is phase */
+	mode_en = FIELD_GET(AD9910_CFR2_DRG_ENABLE_MSK,
+			    st->reg[AD9910_REG_CFR2].val32);
+	if (mode_en && AD9910_DEST_PHASE ==
+		       FIELD_GET(AD9910_CFR2_DRG_DEST_MSK,
+				 st->reg[AD9910_REG_CFR2].val32))
+		return ad9910_channel_str[AD9910_CHAN_IDX_DRG_PHASE];
+
+	/* Parallel data port enabled and data destination is phase */
+	mode_en = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+			    st->reg[AD9910_REG_CFR2].val32);
+	if (mode_en && indio_dev->active_scan_mask) {
+		if (test_bit(AD9910_SCAN_IDX_PHASE, indio_dev->active_scan_mask))
+			return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_PHASE];
+		if (test_bit(AD9910_SCAN_IDX_POLAR_PHASE, indio_dev->active_scan_mask))
+			return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_POLAR_PHASE];
+	}
+
+	/* POW: RAM enabled and data destination is frequency or amplitude */
+	if (ram_en)
+		return ad9910_channel_str[AD9910_CHAN_IDX_RAM];
+
+	/* single tone profiles */
+	return ad9910_channel_str[AD9910_CHAN_IDX_PROFILE_0 + st->profile];
+}
+
+static int ad9910_phase_source_show(struct seq_file *s, void *ignored)
+{
+	seq_printf(s, "%s\n", ad9910_phase_source_get(s->private));
+	return 0;
+}
+DEFINE_SHOW_ATTRIBUTE(ad9910_phase_source);
+
+static inline const char *ad9910_amplitude_source_get(struct iio_dev *indio_dev)
+{
+	struct ad9910_state *st = iio_priv(indio_dev);
+	bool ram_en, mode_en;
+	u32 destination;
+
+	guard(mutex)(&st->lock);
+
+	/* OSK enabled */
+	mode_en = FIELD_GET(AD9910_CFR1_OSK_ENABLE_MSK,
+			    st->reg[AD9910_REG_CFR1].val32);
+	if (mode_en)
+		return ad9910_channel_str[AD9910_CHAN_IDX_OSK];
+
+	/* RAM enabled and data destination is amplitude or polar */
+	ram_en = AD9910_RAM_ENABLED(st);
+	if (ram_en) {
+		destination = FIELD_GET(AD9910_CFR1_RAM_PLAYBACK_DEST_MSK,
+					st->reg[AD9910_REG_CFR1].val32);
+		if (destination == AD9910_DEST_AMPLITUDE ||
+		    destination == AD9910_DEST_POLAR)
+			return ad9910_channel_str[AD9910_CHAN_IDX_RAM];
+	}
+
+	/* DRG enabled and data destination is amplitude */
+	mode_en = FIELD_GET(AD9910_CFR2_DRG_ENABLE_MSK,
+			    st->reg[AD9910_REG_CFR2].val32);
+	if (mode_en && AD9910_DEST_AMPLITUDE ==
+		       FIELD_GET(AD9910_CFR2_DRG_DEST_MSK,
+				 st->reg[AD9910_REG_CFR2].val32))
+		return ad9910_channel_str[AD9910_CHAN_IDX_DRG_AMP];
+
+	/* Parallel data port enabled and data destination is amplitude */
+	mode_en = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+			    st->reg[AD9910_REG_CFR2].val32);
+	if (mode_en && indio_dev->active_scan_mask) {
+		if (test_bit(AD9910_SCAN_IDX_AMP, indio_dev->active_scan_mask))
+			return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_AMP];
+		if (test_bit(AD9910_SCAN_IDX_POLAR_AMP, indio_dev->active_scan_mask))
+			return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_POLAR_AMP];
+	}
+
+	/* only way to control amplitude at this point is through OSK */
+	if (ram_en)
+		return ad9910_channel_str[AD9910_CHAN_IDX_OSK];
+
+	/* single tone profiles */
+	return ad9910_channel_str[AD9910_CHAN_IDX_PROFILE_0 + st->profile];
+}
+
+static int ad9910_amplitude_source_show(struct seq_file *s, void *ignored)
+{
+	seq_printf(s, "%s\n", ad9910_amplitude_source_get(s->private));
+	return 0;
+}
+DEFINE_SHOW_ATTRIBUTE(ad9910_amplitude_source);
+
+static inline void ad9910_debugfs_init(struct ad9910_state *st,
+				       struct iio_dev *indio_dev)
+{
+	struct dentry *d = iio_get_debugfs_dentry(indio_dev);
+
+	debugfs_create_file("frequency_source", 0400, d, indio_dev,
+			    &ad9910_frequency_source_fops);
+	debugfs_create_file("phase_source", 0400, d, indio_dev,
+			    &ad9910_phase_source_fops);
+	debugfs_create_file("amplitude_source", 0400, d, indio_dev,
+			    &ad9910_amplitude_source_fops);
+}
+
 static int ad9910_probe(struct spi_device *spi)
 {
 	static const char * const supplies[] = {
@@ -2141,7 +2320,13 @@ static int ad9910_probe(struct spi_device *spi)
 		return dev_err_probe(dev, ret,
 				     "failed to add ram upload unregister action\n");
 
-	return devm_iio_device_register(dev, indio_dev);
+	ret = devm_iio_device_register(dev, indio_dev);
+	if (ret)
+		return ret;
+
+	ad9910_debugfs_init(st, indio_dev);
+
+	return 0;
 }
 
 static const struct spi_device_id ad9910_id[] = {

-- 
2.43.0

