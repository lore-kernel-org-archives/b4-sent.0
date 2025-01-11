From: Vasiliy Doylov <nekodevelopper@gmail.com>
Date: Sat, 11 Jan 2025 23:11:07 +0300
Subject: [PATCH 2/4] iio: accel: mc3230: add OF match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250111-mainlining-mc3510c-v1-2-57be503addf8@gmail.com>
References: <20250111-mainlining-mc3510c-v1-0-57be503addf8@gmail.com>
In-Reply-To: <20250111-mainlining-mc3510c-v1-0-57be503addf8@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1074;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=7FltGDA7Coxid4ukNBq4MOgPx0ilGEOInxc3SWRtDZo=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNKbLkQXqk604ZqZ3uD3w+n9O5OpE+e7r5Y7UG8U2vfKb
 NGhgqRVHaUsDGJcDLJiiiw2Gz1mi+WHS06a9lQBZg4rE8gQBi5OAZgI7wFGhs+ZeXaLuH+/9zb+
 9jhy6Y16dv6WzU6hE/at1V/V+uX5Q19Ghovsls9ktq6dIb/xb/R2jfRGqxlSwpN0GF1Pybbe3r+
 PnxEA
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This will make the driver probe-able via device-tree.
While the I2C match table may be sufficient, this should extend the cover
of this driver being probed by other methods.

Signed-off-by: Vasiliy Doylov <nekodevelopper@gmail.com>
---
 drivers/iio/accel/mc3230.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/iio/accel/mc3230.c b/drivers/iio/accel/mc3230.c
index 48787c0494ae6f0ef1d4d22bc5a4608035cbe123..3cad6f2d7a2a79df38f90e5656763f6ed019a920 100644
--- a/drivers/iio/accel/mc3230.c
+++ b/drivers/iio/accel/mc3230.c
@@ -205,10 +205,17 @@ static const struct i2c_device_id mc3230_i2c_id[] = {
 };
 MODULE_DEVICE_TABLE(i2c, mc3230_i2c_id);
 
+static const struct of_device_id mc3230_of_match[] = {
+	{ .compatible = "mcube,mc3230" },
+	{ },
+};
+MODULE_DEVICE_TABLE(of, mc3230_of_match);
+
 static struct i2c_driver mc3230_driver = {
 	.driver = {
 		.name = "mc3230",
 		.pm = pm_sleep_ptr(&mc3230_pm_ops),
+		.of_match_table = mc3230_of_match,
 	},
 	.probe		= mc3230_probe,
 	.remove		= mc3230_remove,

-- 
2.47.1

