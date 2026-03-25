From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 25 Mar 2026 11:12:03 +0000
Subject: [PATCH 2/2] iio: amplifiers: ad8366: add support for adrf5702/3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-adrf570x-iio-support-v1-2-9a2685eb2e55@analog.com>
References: <20260325-adrf570x-iio-support-v1-0-9a2685eb2e55@analog.com>
In-Reply-To: <20260325-adrf570x-iio-support-v1-0-9a2685eb2e55@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774437143; l=3508;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=AsNs5tyHtb0PShFN/SAT4QMGDo6HOT+KvogC5g2UCX8=;
 b=2+oY5DPNo4WEC+olLvftCchq99Nj6592+xVQpUbXn3yDSbD5KE4kh7b45GuQaUI6OWfOrcHzl
 yY9QCHxPnZ4BNXXGS9xpE4YBGEynpu22KBe9wVgDCN1gs0cKd3Wohum
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add chip info structs and device table entries for ADRF5702 and ADRF5703
Digital Step Attenuators.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/Kconfig  |  2 ++
 drivers/iio/amplifiers/ad8366.c | 22 ++++++++++++++++++++++
 2 files changed, 24 insertions(+)

diff --git a/drivers/iio/amplifiers/Kconfig b/drivers/iio/amplifiers/Kconfig
index 39d280d4d437..9e24421b5e97 100644
--- a/drivers/iio/amplifiers/Kconfig
+++ b/drivers/iio/amplifiers/Kconfig
@@ -18,6 +18,8 @@ config AD8366
 	    AD8366 Dual-Digital Variable Gain Amplifier (VGA)
 	    ADA4961 BiCMOS RF Digital Gain Amplifier (DGA)
 	    ADL5240 Digitally controlled variable gain amplifier (VGA)
+	    ADRF5702: 0.125 dB LSB, 8-Bit, Silicon Digital Attenuator
+	    ADRF5703: 0.25 dB LSB, 7-Bit, Silicon Digital Attenuator
 	    ADRF5720: 0.5 dB LSB, 6-Bit, Silicon Digital Attenuator
 	    ADRF5730: 0.5 dB LSB, 6-Bit, Silicon Digital Attenuator
 	    ADRF5731: 2 dB LSB, 4-Bit, Silicon Digital Attenuator
diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index 334ca91c0f59..bbf41a1fb3a1 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -5,6 +5,8 @@
  *   AD8366 Dual-Digital Variable Gain Amplifier (VGA)
  *   ADA4961 BiCMOS RF Digital Gain Amplifier (DGA)
  *   ADL5240 Digitally controlled variable gain amplifier (VGA)
+ *   ADRF5702: 0.125 dB LSB, 8-Bit, Silicon Digital Attenuator, 50 MHz to 20 GHz
+ *   ADRF5703: 0.25 dB LSB, 7-Bit, Silicon Digital Attenuator, 9 kHz to 20 GHz
  *   ADRF5720: 0.5 dB LSB, 6-Bit, Silicon Digital Attenuator, 9 kHz to 40 GHz
  *   ADRF5730: 0.5 dB LSB, 6-Bit, Silicon Digital Attenuator, 100 MHz to 40 GHz
  *   ADRF5731: 2 dB LSB, 4-Bit, Silicon Digital Attenuator, 100 MHz to 40 GHz
@@ -106,6 +108,22 @@ static const struct ad8366_info adl5240_chip_info = {
 	.num_channels = 1,
 };
 
+static const struct ad8366_info adrf5702_chip_info = {
+	.name = "adrf5702",
+	.gain_min = -31875,
+	.gain_max = 0,
+	.gain_step = -125,
+	.num_channels = 1,
+};
+
+static const struct ad8366_info adrf5703_chip_info = {
+	.name = "adrf5703",
+	.gain_min = -31750,
+	.gain_max = 0,
+	.gain_step = -250,
+	.num_channels = 1,
+};
+
 static const struct ad8366_info adrf5720_chip_info = {
 	.name = "adrf5720",
 	.gain_min = -31500,
@@ -337,6 +355,8 @@ static const struct spi_device_id ad8366_id[] = {
 	{ "ad8366", (kernel_ulong_t)&ad8366_chip_info },
 	{ "ada4961", (kernel_ulong_t)&ada4961_chip_info },
 	{ "adl5240", (kernel_ulong_t)&adl5240_chip_info },
+	{ "adrf5702", (kernel_ulong_t)&adrf5702_chip_info },
+	{ "adrf5703", (kernel_ulong_t)&adrf5703_chip_info },
 	{ "adrf5720", (kernel_ulong_t)&adrf5720_chip_info },
 	{ "adrf5730", (kernel_ulong_t)&adrf5730_chip_info },
 	{ "adrf5731", (kernel_ulong_t)&adrf5731_chip_info },
@@ -353,6 +373,8 @@ static const struct of_device_id ad8366_of_match[] = {
 	{ .compatible = "adi,ad8366", .data = &ad8366_chip_info },
 	{ .compatible = "adi,ada4961", .data = &ada4961_chip_info },
 	{ .compatible = "adi,adl5240", .data = &adl5240_chip_info },
+	{ .compatible = "adi,adrf5702", .data = &adrf5702_chip_info },
+	{ .compatible = "adi,adrf5703", .data = &adrf5703_chip_info },
 	{ .compatible = "adi,adrf5720", .data = &adrf5720_chip_info },
 	{ .compatible = "adi,adrf5730", .data = &adrf5730_chip_info },
 	{ .compatible = "adi,adrf5731", .data = &adrf5731_chip_info },

-- 
2.43.0

