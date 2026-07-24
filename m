From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 24 Jul 2026 13:03:12 +0100
Subject: [PATCH v2 2/6] iio: dac: ad5696: add AD5673R/AD5677R entries to
 of_match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-ad5686-extend-dev-support-v2-2-cfc2b30ce988@analog.com>
References: <20260724-ad5686-extend-dev-support-v2-0-cfc2b30ce988@analog.com>
In-Reply-To: <20260724-ad5686-extend-dev-support-v2-0-cfc2b30ce988@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784894592; l=1114;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=5Oxnj8pPzQue9O/xIA3Xd8dZvO/9iV+KIKkDlYyJfAE=;
 b=kBLV+Hb03n6ywm6cD88gfwkisa6vtI2zjXZ/T8bO5UQ8q3NMVbf6HT1guJm0HRgrfdXj4L954
 D8hmwZLAvGSA/n4GA6apDKuz6CKNlRPxmUWgXxUCnWxduVCo5lSktyn
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Populate of_match table with AD5673R/AD5677R entries, already supported by
the driver and available in the id_table.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5696-i2c.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index 31439567f00f..4ddf2e151d47 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -104,7 +104,9 @@ static const struct of_device_id ad5686_of_match[] = {
 	{ .compatible = "adi,ad5337r", .data = &ad5337r_chip_info },
 	{ .compatible = "adi,ad5338r", .data = &ad5338r_chip_info },
 	{ .compatible = "adi,ad5671r", .data = &ad5672r_chip_info },
+	{ .compatible = "adi,ad5673r", .data = &ad5674r_chip_info },
 	{ .compatible = "adi,ad5675r", .data = &ad5676r_chip_info },
+	{ .compatible = "adi,ad5677r", .data = &ad5679r_chip_info },
 	{ .compatible = "adi,ad5691r", .data = &ad5681r_chip_info },
 	{ .compatible = "adi,ad5692r", .data = &ad5682r_chip_info },
 	{ .compatible = "adi,ad5693",  .data = &ad5683_chip_info },

-- 
2.43.0

