From: Vasiliy Doylov <nekodevelopper@gmail.com>
Date: Sun, 12 Jan 2025 15:25:37 +0300
Subject: [PATCH v3 3/5] iio: accel: mc3230: add OF match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250112-mainlining-mc3510c-v3-3-9ee6520ab69d@gmail.com>
References: <20250112-mainlining-mc3510c-v3-0-9ee6520ab69d@gmail.com>
In-Reply-To: <20250112-mainlining-mc3510c-v3-0-9ee6520ab69d@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=921;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=CXzfdvJmi3hz61iMY9QNCk/KSoxBmTl8+cAWMbpfFFg=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNKbt7y6x7/qffH/JYs9JHu/B3S5CZk2Pzf8uMrvC1s49
 0Gn8y89OkpZGMS4GGTFFFlsNnrMFssPl5w07akCzBxWJpAhDFycAjCRS/8YGTozdjL070rM1Vba
 NXtOxewrPh6bYm0fbbw3TybTbP9CaTVGhj1Ht2TeemwR+Njw6LPqIy/TJ0bfKvBdsnG7tteW3c+
 61nADAA==
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
index a153a3f715ed7f2f1417618715767f265b49191d..ba30c904d3f67002deeb3ca5a7e12bfae312e05f 100644
--- a/drivers/iio/accel/mc3230.c
+++ b/drivers/iio/accel/mc3230.c
@@ -205,9 +205,16 @@ static const struct i2c_device_id mc3230_i2c_id[] = {
 };
 MODULE_DEVICE_TABLE(i2c, mc3230_i2c_id);
 
+static const struct of_device_id mc3230_of_match[] = {
+	{ .compatible = "mcube,mc3230" },
+	{}
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

