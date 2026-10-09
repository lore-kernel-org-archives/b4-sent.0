From: Andrei Stancovici <andrei.stancovici@analog.com>
Date: Fri, 09 Oct 2026 11:43:37 +0300
Subject: [PATCH 4/6] iio: adc: ltc2497: add 2x speed mode support for the
 LTC2493
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-submission-ltc2493-support-v1-v1-4-3dad1d4b152a@analog.com>
References: <20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com>
In-Reply-To: <20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Beguin <liambeguin@gmail.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Andrei Stancovici <andrei.stancovici@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791535413; l=2263;
 i=andrei.stancovici@analog.com; s=20261009; h=from:subject:message-id;
 bh=FtjA/zFiFEBKxBtPjAK1vPhQfWF3e5tfKdK/i7o0yJw=;
 b=phN5jGvDKmOPIhTENlBto918SuB2PDmV50jIjy04iWATeU8iyUUXA9jsm1HKrV8kxHodn0bcV
 SvS01G/8CMKAVuejLLR2XjmzdXaS45u8ir/1Es91+IWflN4dsZtY0Bc
X-Developer-Key: i=andrei.stancovici@analog.com; a=ed25519;
 pk=wgT+au+blAhVYxhwNgdx0woNl/1p+OCG484rnTRFrsE=
X-Endpoint-Received: by B4 Relay for andrei.stancovici@analog.com/20261009 with auth_id=1140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC2493 supports the same SPD 2x conversion-speed mode as the
LTC2499, using the same config word and conversion times.  Expose it
through sampling_frequency and sampling_frequency_available on the
voltage channels.  The temperature channel ignores the mode and carries
no sampling_frequency.

Tested on live LTC2493 hardware connected through an IIO network
backend: 1x/2x switching works, voltage reads succeed at both rates, and
the temperature channel carries no sampling_frequency attribute.

Datasheet: https://www.analog.com/media/en/technical-documentation/data-sheets/2493fe.pdf
Signed-off-by: Andrei Stancovici <andrei.stancovici@analog.com>
---
 drivers/iio/adc/ltc2497-core.c | 6 +++++-
 drivers/iio/adc/ltc2497.c      | 1 +
 2 files changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ltc2497-core.c b/drivers/iio/adc/ltc2497-core.c
index 87eade46beb5..816312bf0e90 100644
--- a/drivers/iio/adc/ltc2497-core.c
+++ b/drivers/iio/adc/ltc2497-core.c
@@ -362,6 +362,7 @@ static const struct iio_chan_spec _name[] = {                           \
 }
 
 LTC2493_DEFINE_CHANNELS(ltc2493_channel, 0);
+LTC2493_DEFINE_CHANNELS(ltc2493_channel_samp_freq, BIT(IIO_CHAN_INFO_SAMP_FREQ));
 
 static const struct iio_info ltc2497core_info = {
 	.read_raw = ltc2497core_read_raw,
@@ -387,7 +388,10 @@ int ltc2497core_probe(struct device *dev, struct iio_dev *indio_dev)
 	indio_dev->info = &ltc2497core_info;
 	indio_dev->modes = INDIO_DIRECT_MODE;
 	if (ddata->chip_info->four_channel) {
-		indio_dev->channels = ltc2493_channel;
+		if (ddata->chip_info->has_speed_mode)
+			indio_dev->channels = ltc2493_channel_samp_freq;
+		else
+			indio_dev->channels = ltc2493_channel;
 		indio_dev->num_channels = ARRAY_SIZE(ltc2493_channel);
 	} else {
 		if (ddata->chip_info->has_speed_mode)
diff --git a/drivers/iio/adc/ltc2497.c b/drivers/iio/adc/ltc2497.c
index 12c8a2fecc07..a655b04e2454 100644
--- a/drivers/iio/adc/ltc2497.c
+++ b/drivers/iio/adc/ltc2497.c
@@ -175,6 +175,7 @@ static const struct ltc2497_chip_info ltc2497_info[] = {
 		.resolution = 24,
 		.name = "ltc2493",
 		.has_temp = true,
+		.has_speed_mode = true,
 		.four_channel = true,
 	},
 	[TYPE_LTC2497] = {

-- 
2.43.0

