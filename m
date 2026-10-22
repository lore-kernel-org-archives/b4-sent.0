From: Andrei Stancovici <andrei.stancovici@analog.com>
Date: Thu, 22 Oct 2026 12:58:20 +0300
Subject: [PATCH v2 3/3] iio: adc: ltc2497: add LTC2493 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261022-submission-ltc2493-support-v1-v2-3-391d908d2877@analog.com>
References: <20261022-submission-ltc2493-support-v1-v2-0-391d908d2877@analog.com>
In-Reply-To: <20261022-submission-ltc2493-support-v1-v2-0-391d908d2877@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Beguin <liambeguin@gmail.com>, 
 Joshua Crofts <joshua.crofts1@gmail.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Andrei Stancovici <andrei.stancovici@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792663098; l=8715;
 i=andrei.stancovici@analog.com; s=20261009; h=from:subject:message-id;
 bh=y587TS9YqWDIOJvw8dQBhToPnXX1YTN14TsWokMI8DI=;
 b=eir08n3POeaz1h0QalSSsLxr/ZdJl/6D0heAqsWBphGnIbivgnXmMNb1VbkjZ91QYgtL7cEG6
 mPUUbi32cSvAOcrdqtk/9axrtYCpR9+Rfa3oWwlNk8pY+M3IN207UZe
X-Developer-Key: i=andrei.stancovici@analog.com; a=ed25519;
 pk=wgT+au+blAhVYxhwNgdx0woNl/1p+OCG484rnTRFrsE=
X-Endpoint-Received: by B4 Relay for andrei.stancovici@analog.com/20261009 with auth_id=1140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC2493 is the 4-channel member of the LTC2499 family: 4 single-ended
inputs or 2 differential pairs, 24-bit result, and the same command
format, internal PTAT temperature sensor, 2x speed mode and line-frequency
rejection as the LTC2499.

For channel enumeration, the parts differ in how many inputs they
have, so record that count in chip_info and select the corresponding
channel table from it. A future family member with another input
count is then one more table and one more row rather than another
branch in probe.

Datasheet: https://www.analog.com/media/en/technical-documentation/data-sheets/2493fe.pdf
Signed-off-by: Andrei Stancovici <andrei.stancovici@analog.com>

---
Changes in v2:
- Folded in the previous temperature, 2x speed and rejection patches, so
  the LTC2493 chip_info entry is complete where the part is introduced
  (Nuno Sá, Jonathan Cameron).
- Replaced bool four_channel with u8 num_inputs, and pick the channel
  table from a set keyed by that count in the core, so another input
  count is one more table and one more row rather than another branch in
  probe (Jonathan Cameron). It is named num_inputs rather than
  num_channels because indio_dev->num_channels represents the complete
  IIO channel set and is 33 for the 16-input part.
  pahole, struct ltc2497_chip_info, before -> after: LP64 16 -> 16 bytes,
  ILP32 12 -> 12 bytes, no holes either way. The u8 lands in the padding
  the trailing bools already occupied, so nothing was reordered.
- ltc2496_info and the LTC2497/LTC2499 entries gain num_inputs = 16.
  Without it those parts match no channel set and fail probe.
- Dropped the comment above the temperature-channel trim rather than
  rewording it (Nuno Sá).
- Dropped Joshua Crofts' Reviewed-by from the old patch 2/6: that patch
  is now merged with three others and the channel representation it
  covered has been rewritten, so it needs a fresh look.
---
 drivers/iio/adc/ltc2496.c      |  1 +
 drivers/iio/adc/ltc2497-core.c | 66 +++++++++++++++++++++++++++++++++++++-----
 drivers/iio/adc/ltc2497.c      | 13 +++++++++
 drivers/iio/adc/ltc2497.h      |  1 +
 4 files changed, 74 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/adc/ltc2496.c b/drivers/iio/adc/ltc2496.c
index 5b5b6ab28850..e40440410f60 100644
--- a/drivers/iio/adc/ltc2496.c
+++ b/drivers/iio/adc/ltc2496.c
@@ -89,6 +89,7 @@ static void ltc2496_remove(struct spi_device *spi)
 static const struct ltc2497_chip_info ltc2496_info = {
 	.resolution = 16,
 	.name = NULL,
+	.num_inputs = 16,
 };
 
 static const struct of_device_id ltc2496_of_match[] = {
diff --git a/drivers/iio/adc/ltc2497-core.c b/drivers/iio/adc/ltc2497-core.c
index c218d87d3a62..9346a39968d0 100644
--- a/drivers/iio/adc/ltc2497-core.c
+++ b/drivers/iio/adc/ltc2497-core.c
@@ -420,6 +420,49 @@ static const struct iio_chan_spec _name[] = {                           \
 LTC2497_DEFINE_CHANNELS(ltc2497core_channel, 0);
 LTC2497_DEFINE_CHANNELS(ltc2497core_channel_samp_freq, BIT(IIO_CHAN_INFO_SAMP_FREQ));
 
+#define LTC2493_DEFINE_CHANNELS(_name, _extra_mask)                     \
+static const struct iio_chan_spec _name[] = {                           \
+	LTC2497_CHAN(0, LTC2497_SGL, "CH0", _extra_mask),               \
+	LTC2497_CHAN(1, LTC2497_SGL, "CH1", _extra_mask),               \
+	LTC2497_CHAN(2, LTC2497_SGL, "CH2", _extra_mask),               \
+	LTC2497_CHAN(3, LTC2497_SGL, "CH3", _extra_mask),               \
+	LTC2497_CHAN_DIFF(0, LTC2497_DIFF, _extra_mask),                \
+	LTC2497_CHAN_DIFF(1, LTC2497_DIFF, _extra_mask),                \
+	LTC2497_CHAN_DIFF(0, LTC2497_DIFF | LTC2497_SIGN, _extra_mask), \
+	LTC2497_CHAN_DIFF(1, LTC2497_DIFF | LTC2497_SIGN, _extra_mask), \
+	LTC2497_TEMP_CHANNEL,                                           \
+}
+
+LTC2493_DEFINE_CHANNELS(ltc2493_channel, 0);
+LTC2493_DEFINE_CHANNELS(ltc2493_channel_samp_freq, BIT(IIO_CHAN_INFO_SAMP_FREQ));
+
+/*
+ * Channel sets keyed by the part's single-ended input count, so that adding a
+ * family member with a different count is a new table and a new row here
+ * rather than a new branch in probe.  num_channels counts the temperature
+ * entry, which probe drops again for parts without the sensor.
+ */
+struct ltc2497core_channel_set {
+	u8 num_inputs;
+	unsigned int num_channels;
+	const struct iio_chan_spec *channels;
+	const struct iio_chan_spec *channels_samp_freq;
+};
+
+static const struct ltc2497core_channel_set ltc2497core_channel_sets[] = {
+	{
+		.num_inputs		= 4,
+		.num_channels		= ARRAY_SIZE(ltc2493_channel),
+		.channels		= ltc2493_channel,
+		.channels_samp_freq	= ltc2493_channel_samp_freq,
+	}, {
+		.num_inputs		= 16,
+		.num_channels		= ARRAY_SIZE(ltc2497core_channel),
+		.channels		= ltc2497core_channel,
+		.channels_samp_freq	= ltc2497core_channel_samp_freq,
+	},
+};
+
 static const struct iio_info ltc2497core_info = {
 	.read_raw = ltc2497core_read_raw,
 	.read_avail = ltc2497core_read_avail,
@@ -430,6 +473,7 @@ int ltc2497core_probe(struct device *dev, struct iio_dev *indio_dev)
 {
 	struct ltc2497core_driverdata *ddata = iio_priv(indio_dev);
 	struct iio_map *plat_data = dev_get_platdata(dev);
+	const struct ltc2497core_channel_set *set = NULL;
 	int ret;
 
 	/*
@@ -441,17 +485,25 @@ int ltc2497core_probe(struct device *dev, struct iio_dev *indio_dev)
 	else
 		indio_dev->name = dev_name(dev);
 
+	for (unsigned int i = 0; i < ARRAY_SIZE(ltc2497core_channel_sets); i++) {
+		if (ltc2497core_channel_sets[i].num_inputs ==
+		    ddata->chip_info->num_inputs) {
+			set = &ltc2497core_channel_sets[i];
+			break;
+		}
+	}
+	if (!set)
+		return -EINVAL;
+
 	indio_dev->info = &ltc2497core_info;
 	indio_dev->modes = INDIO_DIRECT_MODE;
 	if (ddata->chip_info->has_speed_mode)
-		indio_dev->channels = ltc2497core_channel_samp_freq;
-	else
-		indio_dev->channels = ltc2497core_channel;
-	/* Only the ltc2499 has a temperature channel; it is the last entry. */
-	if (ddata->chip_info->has_temp)
-		indio_dev->num_channels = ARRAY_SIZE(ltc2497core_channel);
+		indio_dev->channels = set->channels_samp_freq;
 	else
-		indio_dev->num_channels = ARRAY_SIZE(ltc2497core_channel) - 1;
+		indio_dev->channels = set->channels;
+	indio_dev->num_channels = set->num_channels;
+	if (!ddata->chip_info->has_temp)
+		indio_dev->num_channels--;
 
 	if (ddata->chip_info->has_rejection_mode) {
 		struct iio_chan_spec *channels;
diff --git a/drivers/iio/adc/ltc2497.c b/drivers/iio/adc/ltc2497.c
index 4cccd3b7c8ef..644954b785b8 100644
--- a/drivers/iio/adc/ltc2497.c
+++ b/drivers/iio/adc/ltc2497.c
@@ -19,6 +19,7 @@
 #include "ltc2497.h"
 
 enum ltc2497_chip_type {
+	TYPE_LTC2493,
 	TYPE_LTC2497,
 	TYPE_LTC2499,
 };
@@ -173,13 +174,23 @@ static void ltc2497_remove(struct i2c_client *client)
 }
 
 static const struct ltc2497_chip_info ltc2497_info[] = {
+	[TYPE_LTC2493] = {
+		.resolution = 24,
+		.name = "ltc2493",
+		.num_inputs = 4,
+		.has_temp = true,
+		.has_speed_mode = true,
+		.has_rejection_mode = true,
+	},
 	[TYPE_LTC2497] = {
 		.resolution = 16,
 		.name = NULL,
+		.num_inputs = 16,
 	},
 	[TYPE_LTC2499] = {
 		.resolution = 24,
 		.name = "ltc2499",
+		.num_inputs = 16,
 		.has_temp = true,
 		.has_speed_mode = true,
 		.has_rejection_mode = true,
@@ -187,6 +198,7 @@ static const struct ltc2497_chip_info ltc2497_info[] = {
 };
 
 static const struct i2c_device_id ltc2497_id[] = {
+	{ .name = "ltc2493", .driver_data = (kernel_ulong_t)&ltc2497_info[TYPE_LTC2493] },
 	{ .name = "ltc2497", .driver_data = (kernel_ulong_t)&ltc2497_info[TYPE_LTC2497] },
 	{ .name = "ltc2499", .driver_data = (kernel_ulong_t)&ltc2497_info[TYPE_LTC2499] },
 	{ }
@@ -194,6 +206,7 @@ static const struct i2c_device_id ltc2497_id[] = {
 MODULE_DEVICE_TABLE(i2c, ltc2497_id);
 
 static const struct of_device_id ltc2497_of_match[] = {
+	{ .compatible = "lltc,ltc2493", .data = &ltc2497_info[TYPE_LTC2493] },
 	{ .compatible = "lltc,ltc2497", .data = &ltc2497_info[TYPE_LTC2497] },
 	{ .compatible = "lltc,ltc2499", .data = &ltc2497_info[TYPE_LTC2499] },
 	{ }
diff --git a/drivers/iio/adc/ltc2497.h b/drivers/iio/adc/ltc2497.h
index 3a3fd82b21a3..02ca0c946448 100644
--- a/drivers/iio/adc/ltc2497.h
+++ b/drivers/iio/adc/ltc2497.h
@@ -47,6 +47,7 @@ enum ltc2497_rejection {
 struct ltc2497_chip_info {
 	const char *name;
 	u32 resolution;
+	u8 num_inputs;		/* single-ended inputs */
 	bool has_temp;
 	bool has_speed_mode;	/* SPD bit in the 2nd config byte (LTC2499/LTC2493) */
 	bool has_rejection_mode;	/* FA/FB bits in the 2nd config byte */

-- 
2.43.0

