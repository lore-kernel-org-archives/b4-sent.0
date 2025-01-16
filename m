From: Vasiliy Doylov <nekodevelopper@gmail.com>
Date: Thu, 16 Jan 2025 16:52:46 +0300
Subject: [PATCH RESEND v4 5/5] iio: accel: mc3230: add mc3510c support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-mainlining-mc3510c-v4-5-a41308b85ec2@gmail.com>
References: <20250116-mainlining-mc3510c-v4-0-a41308b85ec2@gmail.com>
In-Reply-To: <20250116-mainlining-mc3510c-v4-0-a41308b85ec2@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1524;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=9Z3q0OsDzL5ZwgOvYT7Efze32gsUcd3XbTfzqI4bFbA=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNI7+aOn5M9Vtetu2X/nb0/DoXDuDWe/3jxhnbnT3ODbK
 mOu+qupHaUsDGJcDLJiiiw2Gz1mi+WHS06a9lQBZg4rE8gQBi5OAZiIRinDH/6Q44tOh6uIhUkt
 f3//fn/Mc5tXJTbxkkXBf25F+B/SMWb476qVyJ6RcI8r68E9qY9tDJeire4d8/He2Hmo+O8z383
 +jAA=
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This change integrates mc3510c support into the mc3230 driver.
MC3510C uses the same registers as MC3230, but a different value scale.

Tested on Huawei MediaPad T3 10 (huawei-agassi)

Signed-off-by: Vasiliy Doylov <nekodevelopper@gmail.com>
---
 drivers/iio/accel/mc3230.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/iio/accel/mc3230.c b/drivers/iio/accel/mc3230.c
index c8d394c3ecf08fad60f0f2ae7be6fd992327d843..e2853090fa6e15f4dd74e996fae8520b30471d3b 100644
--- a/drivers/iio/accel/mc3230.c
+++ b/drivers/iio/accel/mc3230.c
@@ -46,6 +46,14 @@ static const struct mc3230_chip_info mc3230_chip_info = {
 	.scale = 115411765,
 };
 
+static const struct mc3230_chip_info mc3510c_chip_info = {
+	.name = "mc3510c",
+	.chip_id = 0x23,
+	.product_code = 0x10,
+	/* Was obtained empirically */
+	.scale = 625000000,
+};
+
 #define MC3230_CHANNEL(reg, axis) {	\
 	.type = IIO_ACCEL,	\
 	.address = reg,	\
@@ -225,12 +233,14 @@ static DEFINE_SIMPLE_DEV_PM_OPS(mc3230_pm_ops, mc3230_suspend, mc3230_resume);
 
 static const struct i2c_device_id mc3230_i2c_id[] = {
 	{ "mc3230", (kernel_ulong_t)&mc3230_chip_info },
+	{ "mc3510c", (kernel_ulong_t)&mc3510c_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(i2c, mc3230_i2c_id);
 
 static const struct of_device_id mc3230_of_match[] = {
 	{ .compatible = "mcube,mc3230", &mc3230_chip_info },
+	{ .compatible = "mcube,mc3510c", &mc3510c_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, mc3230_of_match);

-- 
2.47.1

