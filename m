From: Vasiliy Doylov <nekodevelopper@gmail.com>
Date: Sun, 12 Jan 2025 15:25:39 +0300
Subject: [PATCH v3 5/5] iio: accel: mc3230: add mc3510c support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250112-mainlining-mc3510c-v3-5-9ee6520ab69d@gmail.com>
References: <20250112-mainlining-mc3510c-v3-0-9ee6520ab69d@gmail.com>
In-Reply-To: <20250112-mainlining-mc3510c-v3-0-9ee6520ab69d@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1445;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=8NnUIWTvd4feGzNACN4tIbU/CIslPoRvUoNTUHEipMg=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNKbt7yyUji+dZfq45fBdxmu7yhbtZv3poPu457vmyZo3
 JwTa3ltd0cpC4MYF4OsmCKLzUaP2WL54ZKTpj1VgJnDygQyhIGLUwAmsqqKkWFrmQrTofY9AXtl
 dGtmLmV10j0W1FSVsDhFtYCP+cmLE5MYGS7qntzKMV90ywX3W+8X9KwQUYisFNzyV++h05OlN6c
 02TADAA==
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit integrates support for the mc3510c into the mc3230 driver.

Tested on Huawei MediaPad T3 10 (huawei-agassi)

Signed-off-by: Vasiliy Doylov <nekodevelopper@gmail.com>
---
 drivers/iio/accel/mc3230.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/iio/accel/mc3230.c b/drivers/iio/accel/mc3230.c
index 1b58f3ea50655b6563a78a2531b16a8088e8f8d5..92934975edc77b11ed6dc3da077a28d317314fab 100644
--- a/drivers/iio/accel/mc3230.c
+++ b/drivers/iio/accel/mc3230.c
@@ -46,6 +46,14 @@ static struct mc3230_chip_info mc3230_chip_info = {
 	.scale = 115411765,
 };
 
+static struct mc3230_chip_info mc3510c_chip_info = {
+	.chip_id = 0x23,
+	.name = "mc3510c",
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
 	{}
 };
 MODULE_DEVICE_TABLE(i2c, mc3230_i2c_id);
 
 static const struct of_device_id mc3230_of_match[] = {
 	{ .compatible = "mcube,mc3230", &mc3230_chip_info },
+	{ .compatible = "mcube,mc3510c", &mc3510c_chip_info },
 	{}
 };
 MODULE_DEVICE_TABLE(of, mc3230_of_match);

-- 
2.47.1

