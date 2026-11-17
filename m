From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 17 Nov 2026 20:08:37 +0200
Subject: [PATCH v2 3/4] iio: light: stk3310: add vdd regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-6768-stk3337-v2-3-92f4c7be3bc6@protonmail.com>
References: <20261117-6768-stk3337-v2-0-92f4c7be3bc6@protonmail.com>
In-Reply-To: <20261117-6768-stk3337-v2-0-92f4c7be3bc6@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794938915; l=1100;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=P5EyD85VDfSXBEox0JnVub85ggLxUGhVypoOaimLv4g=;
 b=sGQ05nVPy4oABTud4kewoqVpxi+MNMAJcrf7Yr6J0+c+luB23bpoF5N9EDfV4icN1JJyqiLIc
 9tdIblKgER9BdP2JWSqX/4+uPAGV0GodhnOezT5tWevCS15iIiZh1pV
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some boards, the sensor is powered by shared power rail. If the rail
is powered down, the chip can't function.

Add vdd regulator support to ensure the power supply is enabled for the
chip.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/iio/light/stk3310.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/iio/light/stk3310.c b/drivers/iio/light/stk3310.c
index e751e7c97bc1..2f4747c06f43 100644
--- a/drivers/iio/light/stk3310.c
+++ b/drivers/iio/light/stk3310.c
@@ -18,6 +18,7 @@
 #include <linux/pm.h>
 #include <linux/property.h>
 #include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
 #include <linux/sysfs.h>
 #include <linux/types.h>
 
@@ -745,6 +746,10 @@ static int stk3310_probe(struct i2c_client *client)
 	device_property_read_u32(&client->dev, "proximity-near-level",
 				 &data->ps_near_level);
 
+	ret = devm_regulator_get_enable(dev, "vdd");
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to get vdd supply\n");
+
 	mutex_init(&data->lock);
 
 	ret = stk3310_regmap_init(data);

-- 
2.56.1

