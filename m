From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 15:35:17 +0000
Subject: [PATCH v4 12/12] iio: dac: ad5446: Add AD5542 to the spi id table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-dev-add-ad5542-v4-12-6fe35458bf8c@analog.com>
References: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
In-Reply-To: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762270508; l=1707;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=/Mkg35Wn0UA67FMCbuwFEboIaykrODqRCUQPosEXLzA=;
 b=uCHg1Ky4g//MIgWH2Uzc67rHvTtgx7F/SFFBdgRn+O0xeJvLc8Ja4dz41O/DLKLmbspP9Ff6O
 8rJLr0kUDLUDUV6BGoyg/YJy6mvYyVkVu6Y+cn/9UFWvfg6tFPyHNRj
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Hennerich <michael.hennerich@analog.com>

This adds support for the AD5542 single channel Current Source and
Voltage Output DACs.

It is similar to the AD5542A model so just use the same id.

Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Co-developed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446-spi.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/dac/ad5446-spi.c b/drivers/iio/dac/ad5446-spi.c
index 1a52f6014fad..487268d52ce2 100644
--- a/drivers/iio/dac/ad5446-spi.c
+++ b/drivers/iio/dac/ad5446-spi.c
@@ -175,6 +175,7 @@ static const struct spi_device_id ad5446_spi_ids[] = {
 	{"ad5453", (kernel_ulong_t)&ad5446_chip_info}, /* ad5453 is compatible to the ad5446 */
 	{"ad5512a", (kernel_ulong_t)&ad5512a_chip_info},
 	{"ad5541a", (kernel_ulong_t)&ad5541a_chip_info},
+	{"ad5542", (kernel_ulong_t)&ad5541a_chip_info}, /* ad5541a and ad5542 are compatible */
 	{"ad5542a", (kernel_ulong_t)&ad5541a_chip_info}, /* ad5541a and ad5542a are compatible */
 	{"ad5543", (kernel_ulong_t)&ad5541a_chip_info}, /* ad5541a and ad5543 are compatible */
 	{"ad5553", (kernel_ulong_t)&ad5553_chip_info},
@@ -211,6 +212,7 @@ static const struct of_device_id ad5446_of_ids[] = {
 	{ .compatible = "adi,ad5453", .data = &ad5446_chip_info },
 	{ .compatible = "adi,ad5512a", .data = &ad5512a_chip_info },
 	{ .compatible = "adi,ad5541a", .data = &ad5541a_chip_info },
+	{ .compatible = "adi,ad5542", .data = &ad5541a_chip_info },
 	{ .compatible = "adi,ad5542a", .data = &ad5541a_chip_info },
 	{ .compatible = "adi,ad5543", .data = &ad5541a_chip_info },
 	{ .compatible = "adi,ad5553", .data = &ad5553_chip_info },

-- 
2.51.0

