From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 31 Oct 2025 12:31:31 +0000
Subject: [PATCH v3 10/10] iio: dac: ad5446: Add AD5542 to the spi id table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251031-dev-add-ad5542-v3-10-d3541036c0e6@analog.com>
References: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
In-Reply-To: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761913895; l=1707;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=/OfQFB0/UcOV1OFJoyHe7o8DYKnhhHQOcnOWnnCI1R4=;
 b=dDgW35FgKe1VnCQUTlWgGLcTZtPpheOgVbI1ADIVZGFMM+TMZ50k02iAT+UkF2JOjPOAMf5cl
 XJlnVSlE/p1BgGgWXj8YvKk76s8fHlPdz5Qgpra2o4WRNugpozaOLd+
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
index 7419b17a455f..34d4a737156d 100644
--- a/drivers/iio/dac/ad5446-spi.c
+++ b/drivers/iio/dac/ad5446-spi.c
@@ -177,6 +177,7 @@ static const struct spi_device_id ad5446_spi_ids[] = {
 	{"ad5453", (kernel_ulong_t)&ad5446_chip_info}, /* ad5453 is compatible to the ad5446 */
 	{"ad5512a", (kernel_ulong_t)&ad5512a_chip_info},
 	{"ad5541a", (kernel_ulong_t)&ad5541a_chip_info},
+	{"ad5542", (kernel_ulong_t)&ad5541a_chip_info}, /* ad5541a and ad5542 are compatible */
 	{"ad5542a", (kernel_ulong_t)&ad5541a_chip_info}, /* ad5541a and ad5542a are compatible */
 	{"ad5543", (kernel_ulong_t)&ad5541a_chip_info}, /* ad5541a and ad5543 are compatible */
 	{"ad5553", (kernel_ulong_t)&ad5553_chip_info},
@@ -213,6 +214,7 @@ static const struct of_device_id ad5446_of_ids[] = {
 	{ .compatible = "adi,ad5453", .data = &ad5446_chip_info },
 	{ .compatible = "adi,ad5512a", .data = &ad5512a_chip_info },
 	{ .compatible = "adi,ad5541a", .data = &ad5541a_chip_info },
+	{ .compatible = "adi,ad5542", .data = &ad5541a_chip_info },
 	{ .compatible = "adi,ad5542a", .data = &ad5541a_chip_info },
 	{ .compatible = "adi,ad5543", .data = &ad5541a_chip_info },
 	{ .compatible = "adi,ad5553", .data = &ad5553_chip_info },

-- 
2.51.0

