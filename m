From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 18 Dec 2024 09:35:01 +0100
Subject: [PATCH v3 2/2] power: supply: gpio-charger: add support for
 default charge current limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-default-charge-current-limit-v3-2-b26118cf06b5@liebherr.com>
References: <20241218-default-charge-current-limit-v3-0-b26118cf06b5@liebherr.com>
In-Reply-To: <20241218-default-charge-current-limit-v3-0-b26118cf06b5@liebherr.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734510905; l=2214;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=8kkaeG3Fu8A0mMHCllTq6XlCfvacmcvVln/ePhFAfLE=;
 b=BsFCVnrWbJa0Tq6woukkKhmEd6zHKDqChEwZAYq1d4oKSBXaRfVP4dP/WQgR2xOle8V6HHKcq
 NBAX9wHlSfpBOzHhNzqzQSd0aGKPoQpLn/b8UWQpV4xPUFcCTbZ0fV+
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With DT properties charge-current-limit-gpios and
charge-current-limit-mapping one can define charge current limits in uA
using up to 32 GPIOs. At the moment the driver defaults to smallest charge
current limitation for safety reasons. When disabling charging is
supported, which should be common, the driver defaults to non charging on
probe. By having a default, charging can be enabled on probe for such
devices.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/power/supply/gpio-charger.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/power/supply/gpio-charger.c b/drivers/power/supply/gpio-charger.c
index 68212b39785beabfe5536a18fa15bc249f7b1eea..56149545a1dc6004b474cec44984c6dfad3413b5 100644
--- a/drivers/power/supply/gpio-charger.c
+++ b/drivers/power/supply/gpio-charger.c
@@ -187,6 +187,8 @@ static int init_charge_current_limit(struct device *dev,
 {
 	int i, len;
 	u32 cur_limit = U32_MAX;
+	bool set_def_limit;
+	u32 def_limit;
 
 	gpio_charger->current_limit_gpios = devm_gpiod_get_array_optional(dev,
 		"charge-current-limit", GPIOD_OUT_LOW);
@@ -220,6 +222,9 @@ static int init_charge_current_limit(struct device *dev,
 	if (len < 0)
 		return len;
 
+	set_def_limit = !device_property_read_u32(dev,
+						  "charge-current-limit-default-microamp",
+						  &def_limit);
 	for (i=0; i < gpio_charger->current_limit_map_size; i++) {
 		if (gpio_charger->current_limit_map[i].limit_ua > cur_limit) {
 			dev_err(dev, "charge-current-limit-mapping not sorted by current in descending order\n");
@@ -227,8 +232,16 @@ static int init_charge_current_limit(struct device *dev,
 		}
 
 		cur_limit = gpio_charger->current_limit_map[i].limit_ua;
+		if (set_def_limit && def_limit == cur_limit) {
+			set_charge_current_limit(gpio_charger, cur_limit);
+			return 0;
+		}
 	}
 
+	if (set_def_limit)
+		dev_warn(dev, "charge-current-limit-default-microamp %u not listed in charge-current-limit-mapping\n",
+			 def_limit);
+
 	/* default to smallest current limitation for safety reasons */
 	len = gpio_charger->current_limit_map_size - 1;
 	set_charge_current_limit(gpio_charger,

-- 
2.39.5

