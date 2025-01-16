From: Vasiliy Doylov <nekodevelopper@gmail.com>
Date: Thu, 16 Jan 2025 16:52:44 +0300
Subject: [PATCH RESEND v4 3/5] iio: accel: mc3230: add OF match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-mainlining-mc3510c-v4-3-a41308b85ec2@gmail.com>
References: <20250116-mainlining-mc3510c-v4-0-a41308b85ec2@gmail.com>
In-Reply-To: <20250116-mainlining-mc3510c-v4-0-a41308b85ec2@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=922;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=Eg7uHGOE8j/UlALdyIln75Y0DBThMlnXhDZzImwRew8=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNI7+aNrtu8PdDjAGj3vxqWZ3yKLm320nptcZHpQ8nt/O
 OMpBWaujlIWBjEuBlkxRRabjR6zxfLDJSdNe6oAM4eVCWQIAxenAEzk8lJGhncfk978aZnKN/82
 15xpP9pFNtwJm//22fezPaf2Sk1b187OyHDCZcKUOR8vX90QxlFzr1NyT6q91MKDx+3/an7gviK
 /cRkHAA==
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This will make the driver auto loaded via device-tree.

Signed-off-by: Vasiliy Doylov <nekodevelopper@gmail.com>
---
 drivers/iio/accel/mc3230.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/iio/accel/mc3230.c b/drivers/iio/accel/mc3230.c
index 48787c0494ae6f0ef1d4d22bc5a4608035cbe123..443b5b30c83144478c27a86dbdc12e4e944a34df 100644
--- a/drivers/iio/accel/mc3230.c
+++ b/drivers/iio/accel/mc3230.c
@@ -205,9 +205,16 @@ static const struct i2c_device_id mc3230_i2c_id[] = {
 };
 MODULE_DEVICE_TABLE(i2c, mc3230_i2c_id);
 
+static const struct of_device_id mc3230_of_match[] = {
+	{ .compatible = "mcube,mc3230" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, mc3230_of_match);
+
 static struct i2c_driver mc3230_driver = {
 	.driver = {
 		.name = "mc3230",
+		.of_match_table = mc3230_of_match,
 		.pm = pm_sleep_ptr(&mc3230_pm_ops),
 	},
 	.probe		= mc3230_probe,

-- 
2.47.1

