From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 16 Feb 2026 17:10:55 +0000
Subject: [PATCH v5 11/11] iio: amplifiers: ad8366: update device support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-iio-ad8366-update-v5-11-7e6091357d02@analog.com>
References: <20260216-iio-ad8366-update-v5-0-7e6091357d02@analog.com>
In-Reply-To: <20260216-iio-ad8366-update-v5-0-7e6091357d02@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771261851; l=6757;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=IP0Q14Wu7q7zwFy9Nj6jg6zOD0UoOhkxtbBst3yVtgM=;
 b=A3+YY8X4cn13eCtaxB/G4oBGtatXQZylFpHWeG9NWFGhG7LCmYQ50UeE9aHAw0mLNTN7WxDw1
 BkghbVjuI7xDTPOvNkskVtrvTx0PywSJB090uvucDemK/QFjDv/u41D
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
Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/Kconfig  |  6 +++
 drivers/iio/amplifiers/ad8366.c | 84 ++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 89 insertions(+), 1 deletion(-)

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
index d4499af0518a..334ca91c0f59 100644
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
 
 #include <linux/bitrev.h>
@@ -61,6 +67,20 @@ static size_t ad8366_pack_code(const unsigned char *code, size_t num_channels,
 	return sizeof(__be16);
 }
 
+static size_t adrf5731_pack_code(const unsigned char *code, size_t num_channels,
+				 unsigned char *data)
+{
+	data[0] = code[0] << 2;
+	return 1;
+}
+
+static size_t hmc271_pack_code(const unsigned char *code, size_t num_channels,
+			       unsigned char *data)
+{
+	data[0] = bitrev8(code[0]) >> 3;
+	return 1;
+}
+
 static const struct ad8366_info ad8366_chip_info = {
 	.name = "ad8366",
 	.gain_min = 4500,
@@ -86,6 +106,40 @@ static const struct ad8366_info adl5240_chip_info = {
 	.num_channels = 1,
 };
 
+static const struct ad8366_info adrf5720_chip_info = {
+	.name = "adrf5720",
+	.gain_min = -31500,
+	.gain_max = 0,
+	.gain_step = -500,
+	.num_channels = 1,
+};
+
+static const struct ad8366_info adrf5730_chip_info = {
+	.name = "adrf5730",
+	.gain_min = -31500,
+	.gain_max = 0,
+	.gain_step = -500,
+	.num_channels = 1,
+};
+
+static const struct ad8366_info adrf5731_chip_info = {
+	.name = "adrf5731",
+	.gain_min = -30000,
+	.gain_max = 0,
+	.gain_step = -2000,
+	.num_channels = 1,
+	.pack_code = adrf5731_pack_code,
+};
+
+static const struct ad8366_info hmc271_chip_info = {
+	.name = "hmc271a",
+	.gain_min = -31000,
+	.gain_max = 0,
+	.gain_step = 1000,
+	.num_channels = 1,
+	.pack_code = hmc271_pack_code,
+};
+
 static const struct ad8366_info hmc792_chip_info = {
 	.name = "hmc792a",
 	.gain_min = -15750,
@@ -94,6 +148,22 @@ static const struct ad8366_info hmc792_chip_info = {
 	.num_channels = 1,
 };
 
+static const struct ad8366_info hmc1018_chip_info = {
+	.name = "hmc1018a",
+	.gain_min = -31000,
+	.gain_max = 0,
+	.gain_step = 1000,
+	.num_channels = 1,
+};
+
+static const struct ad8366_info hmc1019_chip_info = {
+	.name = "hmc1019a",
+	.gain_min = -15500,
+	.gain_max = 0,
+	.gain_step = 500,
+	.num_channels = 1,
+};
+
 static const struct ad8366_info hmc1119_chip_info = {
 	.name = "hmc1119",
 	.gain_min = -31750,
@@ -267,7 +337,13 @@ static const struct spi_device_id ad8366_id[] = {
 	{ "ad8366", (kernel_ulong_t)&ad8366_chip_info },
 	{ "ada4961", (kernel_ulong_t)&ada4961_chip_info },
 	{ "adl5240", (kernel_ulong_t)&adl5240_chip_info },
+	{ "adrf5720", (kernel_ulong_t)&adrf5720_chip_info },
+	{ "adrf5730", (kernel_ulong_t)&adrf5730_chip_info },
+	{ "adrf5731", (kernel_ulong_t)&adrf5731_chip_info },
+	{ "hmc271a", (kernel_ulong_t)&hmc271_chip_info },
 	{ "hmc792a", (kernel_ulong_t)&hmc792_chip_info },
+	{ "hmc1018a", (kernel_ulong_t)&hmc1018_chip_info },
+	{ "hmc1019a", (kernel_ulong_t)&hmc1019_chip_info },
 	{ "hmc1119", (kernel_ulong_t)&hmc1119_chip_info },
 	{ }
 };
@@ -277,7 +353,13 @@ static const struct of_device_id ad8366_of_match[] = {
 	{ .compatible = "adi,ad8366", .data = &ad8366_chip_info },
 	{ .compatible = "adi,ada4961", .data = &ada4961_chip_info },
 	{ .compatible = "adi,adl5240", .data = &adl5240_chip_info },
+	{ .compatible = "adi,adrf5720", .data = &adrf5720_chip_info },
+	{ .compatible = "adi,adrf5730", .data = &adrf5730_chip_info },
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

