From: Andrei Stancovici <andrei.stancovici@analog.com>
Date: Fri, 09 Oct 2026 11:43:36 +0300
Subject: [PATCH 3/6] iio: adc: ltc2497: add LTC2493 internal temperature
 channel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-submission-ltc2493-support-v1-v1-3-3dad1d4b152a@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791535413; l=1711;
 i=andrei.stancovici@analog.com; s=20261009; h=from:subject:message-id;
 bh=y50zBMCty6O/0VAscXJTxsJbowdiUfKJKU+8SF6Q/K4=;
 b=Qu4VdPdTeDXtWEz5X8Ec+PtTkdSgzZc07RvD7MScvZJ/UXGCSIPY+BjIbWwf7aLz95G7EPXsm
 jwpB8UdzqLzCkhfjGdiewq6VPES3sGsMVQtnt8PrtEurJhIMACIYosG
X-Developer-Key: i=andrei.stancovici@analog.com; a=ed25519;
 pk=wgT+au+blAhVYxhwNgdx0woNl/1p+OCG484rnTRFrsE=
X-Endpoint-Received: by B4 Relay for andrei.stancovici@analog.com/20261009 with auth_id=1140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC2493 includes the same internal PTAT temperature sensor as the
LTC2499, selected via the IM bit in the second config byte.

Tested on live LTC2493 hardware connected through an IIO network backend:
in_temp_raw, in_temp_scale, and in_temp_offset are readable; the reported
temperature is plausible; and voltage/temperature interleaving produces no
sticky-PTAT.

Datasheet: https://www.analog.com/media/en/technical-documentation/data-sheets/2493fe.pdf
Signed-off-by: Andrei Stancovici <andrei.stancovici@analog.com>
---
 drivers/iio/adc/ltc2497-core.c | 2 +-
 drivers/iio/adc/ltc2497.c      | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ltc2497-core.c b/drivers/iio/adc/ltc2497-core.c
index 96b365efd1e9..87eade46beb5 100644
--- a/drivers/iio/adc/ltc2497-core.c
+++ b/drivers/iio/adc/ltc2497-core.c
@@ -396,7 +396,7 @@ int ltc2497core_probe(struct device *dev, struct iio_dev *indio_dev)
 			indio_dev->channels = ltc2497core_channel;
 		indio_dev->num_channels = ARRAY_SIZE(ltc2497core_channel);
 	}
-	/* Only the ltc2499 has a temperature channel; it is the last entry. */
+	/* Temperature is the last channel entry; trim it for parts without the sensor. */
 	if (!ddata->chip_info->has_temp)
 		indio_dev->num_channels--;
 
diff --git a/drivers/iio/adc/ltc2497.c b/drivers/iio/adc/ltc2497.c
index ea9dff3c0d73..12c8a2fecc07 100644
--- a/drivers/iio/adc/ltc2497.c
+++ b/drivers/iio/adc/ltc2497.c
@@ -174,6 +174,7 @@ static const struct ltc2497_chip_info ltc2497_info[] = {
 	[TYPE_LTC2493] = {
 		.resolution = 24,
 		.name = "ltc2493",
+		.has_temp = true,
 		.four_channel = true,
 	},
 	[TYPE_LTC2497] = {

-- 
2.43.0

