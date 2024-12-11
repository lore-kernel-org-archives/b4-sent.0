From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 11 Dec 2024 08:29:10 +0100
Subject: [PATCH 2/2] power: supply: gpio-charger: add support for default
 charge current limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241211-default-charge-current-limit-v1-2-7819ba06ee2a@liebherr.com>
References: <20241211-default-charge-current-limit-v1-0-7819ba06ee2a@liebherr.com>
In-Reply-To: <20241211-default-charge-current-limit-v1-0-7819ba06ee2a@liebherr.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733902172; l=1905;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=5B4rPOB+5702QfWy45U125DyTvkQjxqeDuDwvqB5EFA=;
 b=l8QShK3uZiH18nY4r7xOEo4cv0gfqVRaW/2J265DhezaihkaAy0HwBwCqQ+G6mRZfyWcwg0Sa
 0VNOLf+2hZQD7E3yzorunI2tX/1KVje4RqETuOmCDQ7PLRD3q3h3ut6
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver defaults to smallest current limitation for safety reasons. Add
support for setting default current limitation via DT.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/power/supply/gpio-charger.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/power/supply/gpio-charger.c b/drivers/power/supply/gpio-charger.c
index 68212b39785beabfe5536a18fa15bc249f7b1eea..1c1fce6579464b61dbaf4125d0a91dc34c18c4d0 100644
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
+						  "charge-current-limit-default",
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
+		dev_warn(dev, "charge-current-limit-default %u not listed in charge-current-limit-mapping\n",
+			 def_limit);
+
 	/* default to smallest current limitation for safety reasons */
 	len = gpio_charger->current_limit_map_size - 1;
 	set_charge_current_limit(gpio_charger,

-- 
2.39.5

