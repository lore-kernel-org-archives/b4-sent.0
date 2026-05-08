From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 08 May 2026 18:00:24 +0100
Subject: [PATCH RFC v4 08/10] iio: frequency: ad9910: show channel priority
 in debugfs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-ad9910-iio-driver-v4-8-d26bfd20ee3d@analog.com>
References: <20260508-ad9910-iio-driver-v4-0-d26bfd20ee3d@analog.com>
In-Reply-To: <20260508-ad9910-iio-driver-v4-0-d26bfd20ee3d@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778259632; l=7383;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=JUDJpIjdx9vJJEoYazFgsJZuvoEyk0321++06VhTXds=;
 b=QbhTDNJjISYrblveZ2Qh1NqFtn3eFGamz/jfWMo0fhxCrFChkjwHISiCbT8yqkeAvHAim6VIU
 UmzFHMW8YU1A+P3VPj+d3Lrs4SqO4KylYbtqCvQEncQHX5+GHCf7VB3
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expose frequency_source, phase_source and amplitude_source attributes in
debugfs. Those indicate from which channel the specific DDS parameter is
being sourced by returning the its label. The implementation follows the
priority table found in the datasheet.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 171 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 171 insertions(+)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index 1fdbaba356d7..d8fe88259f22 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -2082,6 +2082,170 @@ static int ad9910_setup(struct device *dev, struct ad9910_state *st,
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
+		return ad9910_channel_str[AD9910_CHAN_IDX_DRG];
+
+	/* Parallel data port enabled and data destination is frequency */
+	mode_en = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+			    st->reg[AD9910_REG_CFR1].val32);
+	if (mode_en) /* TODO: get destination from backend once it is supported */
+		return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_PORT];
+
+	/* FTW: RAM enabled and data destination is phase, amplitude, or polar */
+	if (ram_en)
+		return ad9910_channel_str[AD9910_CHAN_IDX_RAM];
+
+	/* single tone profiles */
+	return ad9910_channel_str[AD9910_CHAN_IDX_PROFILE_0 + st->profile];
+}
+
+static int ad9910_frequency_source_show(struct file *file, char __user *userbuf,
+					size_t count, loff_t *ppos)
+{
+	struct iio_dev *indio_dev = file->private_data;
+	const char *src = ad9910_frequency_source_get(indio_dev);
+
+	return simple_read_from_buffer(userbuf, count, ppos, src, strlen(src));
+}
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
+		return ad9910_channel_str[AD9910_CHAN_IDX_DRG];
+
+	/* Parallel data port enabled and data destination is phase */
+	mode_en = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+			    st->reg[AD9910_REG_CFR1].val32);
+	if (mode_en) /* TODO: get destination from backend once it is supported */
+		return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_PORT];
+
+	/* POW: RAM enabled and data destination is frequency, amplitude, or polar */
+	if (ram_en)
+		return ad9910_channel_str[AD9910_CHAN_IDX_RAM];
+
+	/* single tone profiles */
+	return ad9910_channel_str[AD9910_CHAN_IDX_PROFILE_0 + st->profile];
+}
+
+static int ad9910_phase_source_show(struct file *file, char __user *userbuf,
+				    size_t count, loff_t *ppos)
+{
+	struct iio_dev *indio_dev = file->private_data;
+	const char *src = ad9910_phase_source_get(indio_dev);
+
+	return simple_read_from_buffer(userbuf, count, ppos, src, strlen(src));
+}
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
+			    st->reg[AD9910_REG_CFR2].val32);
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
+		return ad9910_channel_str[AD9910_CHAN_IDX_DRG];
+
+	/* Parallel data port enabled and data destination is phase */
+	mode_en = FIELD_GET(AD9910_CFR2_PARALLEL_DATA_PORT_EN_MSK,
+			    st->reg[AD9910_REG_CFR1].val32);
+	if (mode_en) /* TODO: get destination from backend once it is supported */
+		return ad9910_channel_str[AD9910_CHAN_IDX_PARALLEL_PORT];
+
+	/* only way to control amplitude at this point is through OSK */
+	if (ram_en)
+		return ad9910_channel_str[AD9910_CHAN_IDX_OSK];
+
+	/* single tone profiles */
+	return ad9910_channel_str[AD9910_CHAN_IDX_PROFILE_0 + st->profile];
+}
+
+static int ad9910_amplitude_source_show(struct file *file, char __user *userbuf,
+					size_t count, loff_t *ppos)
+{
+	struct iio_dev *indio_dev = file->private_data;
+	const char *src = ad9910_amplitude_source_get(indio_dev);
+
+	return simple_read_from_buffer(userbuf, count, ppos, src, strlen(src));
+}
+
+static const struct file_operations ad9910_frequency_source_fops = {
+	.owner = THIS_MODULE,
+	.read = ad9910_frequency_source_show,
+};
+
+static const struct file_operations ad9910_phase_source_fops = {
+	.owner = THIS_MODULE,
+	.read = ad9910_phase_source_show,
+};
+
+static const struct file_operations ad9910_amplitude_source_fops = {
+	.owner = THIS_MODULE,
+	.read = ad9910_amplitude_source_show,
+};
+
 static inline void ad9910_debugfs_init(struct ad9910_state *st,
 				       struct iio_dev *indio_dev)
 {
@@ -2097,6 +2261,13 @@ static inline void ad9910_debugfs_init(struct ad9910_state *st,
 
 	snprintf(buf, sizeof(buf), "/sys/class/firmware/%s/data", st->ram_fwu_name);
 	debugfs_create_symlink("ram_data", d, buf);
+
+	debugfs_create_file("frequency_source", 0400, d, indio_dev,
+			    &ad9910_frequency_source_fops);
+	debugfs_create_file("phase_source", 0400, d, indio_dev,
+			    &ad9910_phase_source_fops);
+	debugfs_create_file("amplitude_source", 0400, d, indio_dev,
+			    &ad9910_amplitude_source_fops);
 }
 
 static int ad9910_probe(struct spi_device *spi)

-- 
2.43.0

