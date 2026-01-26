From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 26 Jan 2026 13:51:07 +0000
Subject: [PATCH v2 6/6] iio: amplifiers: ad8366: Update device support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-iio-ad8366-update-v2-6-c9a4d31aeb01@analog.com>
References: <20260126-iio-ad8366-update-v2-0-c9a4d31aeb01@analog.com>
In-Reply-To: <20260126-iio-ad8366-update-v2-0-c9a4d31aeb01@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769436111; l=6385;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=cYZYdo1jsI63Nd/LYcxtiA2+53D0PuyoRYFvGABoZxk=;
 b=SG+43gvAVWKTS6faC3C6oXN1k3mQauE2++W11lrAB95N0ok4XS+bI1yg7gdSuedBdk0KwYt0Z
 Wym/czysWfcBZwnUpgqJSqgYCMXAkUvEKI5JhzKKzEZyjWM59ZYgNI1
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the following digital step attenuators:
- HMC271A: 1dB LSB 5-Bit Digital Attenuator SMT, 0.7 - 3.7 GHz
- ADRF5720: 0.5 dB LSB, 6-Bit, Digital Attenuator, 9 kHz to 40 GHz
- ADRF5730: 0.5 dB LSB, 6-Bit, Digital Attenuator, 100 MHz to 40 GHz
- ADRF5731: 2 dB LSB, 4-Bit, Digital Attenuator, 100 MHz to 40 GHz
- HMC1018A: 1.0 dB LSB GaAs MMIC 5-BIT DIGITAL ATTENUATOR, 0.1 - 30 GHz
- HMC1019A: 0.5 dB LSB GaAs MMIC 5-BIT DIGITAL ATTENUATOR, 0.1 - 30 GHz

Additionally, copyright notice was updated with current year.

Co-developed-by: Alexandru Ardelean <alexandru.ardelean@analog.com>
Signed-off-by: Alexandru Ardelean <alexandru.ardelean@analog.com>
Co-developed-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/Kconfig  |  6 ++++
 drivers/iio/amplifiers/ad8366.c | 72 ++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 77 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/amplifiers/Kconfig b/drivers/iio/amplifiers/Kconfig
index a8a604863eed..39d280d4d437 100644
--- a/drivers/iio/amplifiers/Kconfig
+++ b/drivers/iio/amplifiers/Kconfig
@@ -18,7 +18,13 @@ config AD8366
 	    AD8366 Dual-Digital Variable Gain Amplifier (VGA)
 	    ADA4961 BiCMOS RF Digital Gain Amplifier (DGA)
 	    ADL5240 Digitally controlled variable gain amplifier (VGA)
+	    ADRF5720: 0.5 dB LSB, 6-Bit, Silicon Digital Attenuator
+	    ADRF5730: 0.5 dB LSB, 6-Bit, Silicon Digital Attenuator
+	    ADRF5731: 2 dB LSB, 4-Bit, Silicon Digital Attenuator
+	    HMC271A: 1dB LSB 5-Bit Digital Attenuator SMT
 	    HMC792A 0.25 dB LSB GaAs MMIC 6-Bit Digital Attenuator
+	    HMC1018A: 1.0 dB LSB GaAs MMIC 5-BIT Digital Attenuator
+	    HMC1019A: 0.5 dB LSB GaAs MMIC 5-BIT Digital Attenuator
 	    HMC1119 0.25 dB LSB, 7-Bit, Silicon Digital Attenuator
 
 	  To compile this driver as a module, choose M here: the
diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index 9ad6a628376c..14de0418a234 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -5,10 +5,16 @@
  *   AD8366 Dual-Digital Variable Gain Amplifier (VGA)
  *   ADA4961 BiCMOS RF Digital Gain Amplifier (DGA)
  *   ADL5240 Digitally controlled variable gain amplifier (VGA)
+ *   ADRF5720: 0.5 dB LSB, 6-Bit, Silicon Digital Attenuator, 9 kHz to 40 GHz
+ *   ADRF5730: 0.5 dB LSB, 6-Bit, Silicon Digital Attenuator, 100 MHz to 40 GHz
+ *   ADRF5731: 2 dB LSB, 4-Bit, Silicon Digital Attenuator, 100 MHz to 40 GHz
+ *   HMC271A: 1dB LSB 5-Bit Digital Attenuator SMT, 0.7 - 3.7 GHz
  *   HMC792A 0.25 dB LSB GaAs MMIC 6-Bit Digital Attenuator
+ *   HMC1018A: 1.0 dB LSB GaAs MMIC 5-BIT DIGITAL ATTENUATOR, 0.1 - 30 GHz
+ *   HMC1019A: 0.5 dB LSB GaAs MMIC 5-BIT DIGITAL ATTENUATOR, 0.1 - 30 GHz
  *   HMC1119 0.25 dB LSB, 7-Bit, Silicon Digital Attenuator
  *
- * Copyright 2012-2019 Analog Devices Inc.
+ * Copyright 2012-2026 Analog Devices Inc.
  */
 
 #include <linux/cleanup.h>
@@ -67,6 +73,18 @@ static size_t simple_pack_code(struct ad8366_state *st)
 	return 1;
 }
 
+static size_t adrf5731_pack_code(struct ad8366_state *st)
+{
+	st->data[0] = st->ch[0] << 2;
+	return 1;
+}
+
+static size_t hmc271_pack_code(struct ad8366_state *st)
+{
+	st->data[0] = bitrev8(st->ch[0] & 0x1F) >> 3;
+	return 1;
+}
+
 static const struct ad8366_info ad8366_chip_info = {
 	.gain_min = 4500,
 	.gain_max = 20500,
@@ -91,6 +109,30 @@ static const struct ad8366_info adl5240_chip_info = {
 	.pack_code = simple_pack_code,
 };
 
+static const struct ad8366_info adrf57x0_chip_info = {
+	.gain_min = -31500,
+	.gain_max = 0,
+	.gain_step = -500,
+	.num_channels = 1,
+	.pack_code = simple_pack_code,
+};
+
+static const struct ad8366_info adrf5731_chip_info = {
+	.gain_min = -30000,
+	.gain_max = 0,
+	.gain_step = -2000,
+	.num_channels = 1,
+	.pack_code = adrf5731_pack_code,
+};
+
+static const struct ad8366_info hmc271_chip_info = {
+	.gain_min = -31000,
+	.gain_max = 0,
+	.gain_step = 1000,
+	.num_channels = 1,
+	.pack_code = hmc271_pack_code,
+};
+
 static const struct ad8366_info hmc792_chip_info = {
 	.gain_min = -15750,
 	.gain_max = 0,
@@ -99,6 +141,22 @@ static const struct ad8366_info hmc792_chip_info = {
 	.pack_code = simple_pack_code,
 };
 
+static const struct ad8366_info hmc1018_chip_info = {
+	.gain_min = -31000,
+	.gain_max = 0,
+	.gain_step = 1000,
+	.num_channels = 1,
+	.pack_code = simple_pack_code,
+};
+
+static const struct ad8366_info hmc1019_chip_info = {
+	.gain_min = -15500,
+	.gain_max = 0,
+	.gain_step = 500,
+	.num_channels = 1,
+	.pack_code = simple_pack_code,
+};
+
 static const struct ad8366_info hmc1119_chip_info = {
 	.gain_min = -31750,
 	.gain_max = 0,
@@ -253,7 +311,13 @@ static const struct spi_device_id ad8366_id[] = {
 	{"ad8366", (kernel_ulong_t)&ad8366_chip_info},
 	{"ada4961", (kernel_ulong_t)&ada4961_chip_info},
 	{"adl5240", (kernel_ulong_t)&adl5240_chip_info},
+	{"adrf5720", (kernel_ulong_t)&adrf57x0_chip_info},
+	{"adrf5730", (kernel_ulong_t)&adrf57x0_chip_info},
+	{"adrf5731", (kernel_ulong_t)&adrf5731_chip_info},
+	{"hmc271a", (kernel_ulong_t)&hmc271_chip_info},
 	{"hmc792a", (kernel_ulong_t)&hmc792_chip_info},
+	{"hmc1018a", (kernel_ulong_t)&hmc1018_chip_info},
+	{"hmc1019a", (kernel_ulong_t)&hmc1019_chip_info},
 	{"hmc1119", (kernel_ulong_t)&hmc1119_chip_info},
 	{ }
 };
@@ -263,7 +327,13 @@ static const struct of_device_id ad8366_of_match[] = {
 	{ .compatible = "adi,ad8366", .data = &ad8366_chip_info },
 	{ .compatible = "adi,ada4961", .data = &ada4961_chip_info },
 	{ .compatible = "adi,adl5240", .data = &adl5240_chip_info },
+	{ .compatible = "adi,adrf5720", .data = &adrf57x0_chip_info },
+	{ .compatible = "adi,adrf5730", .data = &adrf57x0_chip_info },
+	{ .compatible = "adi,adrf5731", .data = &adrf5731_chip_info },
+	{ .compatible = "adi,hmc271a", .data = &hmc271_chip_info },
 	{ .compatible = "adi,hmc792a", .data = &hmc792_chip_info },
+	{ .compatible = "adi,hmc1018a", .data = &hmc1018_chip_info },
+	{ .compatible = "adi,hmc1019a", .data = &hmc1019_chip_info },
 	{ .compatible = "adi,hmc1119", .data = &hmc1119_chip_info },
 	{ }
 };

-- 
2.43.0

