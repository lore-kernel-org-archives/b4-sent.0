From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Fri, 09 Jan 2026 19:41:20 +0100
Subject: [PATCH v2 2/2] power: supply: gpio-charger: add support for
 fast-charge timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260109-gpio-charger-timer-v2-2-63fd1ba75830@liebherr.com>
References: <20260109-gpio-charger-timer-v2-0-63fd1ba75830@liebherr.com>
In-Reply-To: <20260109-gpio-charger-timer-v2-0-63fd1ba75830@liebherr.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767984085; l=3484;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=p7cAOt/Kei0dwrov23S0iQygvZlwNI2XjIcLZTRyKRk=;
 b=6dESZ3MWxnkh4h/fOAmaWDg0coGjFZxphczIfrWb1oJXbFV2NLon2cmhGbrnCYdc++rrW/cMm
 9aXezOzC+hcBE82MF6bAuasro2NdqeqET3K2J9dlGSEuU4tkR93PKLC
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some devices like TIs BQ24081 battery charger it is possible to activate
or deactivate a fast-charge timer that provides a backup safety for charge
termination. In case of the BQ24081 it is a fixed 7-hour timer. Add support
for enabling/disabling the fast-charge timer via GPIO.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 .../ABI/testing/sysfs-class-power-gpio-charger     | 10 ++++++
 drivers/power/supply/gpio-charger.c                | 39 ++++++++++++++++++++++
 2 files changed, 49 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-class-power-gpio-charger b/Documentation/ABI/testing/sysfs-class-power-gpio-charger
new file mode 100644
index 0000000000000000000000000000000000000000..95fb31ac4af3d5354bdc642c98baa7df267d150d
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-class-power-gpio-charger
@@ -0,0 +1,10 @@
+What:		/sys/class/power_supply/<supply_name>/fast_charge_timer
+Date:		October 2025
+KernelVersion:	6.19.0
+Contact:	Dimitri Fedrau <dimitri.fedrau@liebherr.com>
+Description:
+		This entry enables or disables the timer in fast-charge mode.
+
+		Access: Write
+
+		Valid values: 0 (disabled) or 1 (enabled)
diff --git a/drivers/power/supply/gpio-charger.c b/drivers/power/supply/gpio-charger.c
index 2504190eba82e69b79382320e67de6b8f3dedc77..52997205879406fae600171b070a0328657fa79b 100644
--- a/drivers/power/supply/gpio-charger.c
+++ b/drivers/power/supply/gpio-charger.c
@@ -32,6 +32,7 @@ struct gpio_charger {
 	struct power_supply_desc charger_desc;
 	struct gpio_desc *gpiod;
 	struct gpio_desc *charge_status;
+	struct gpio_desc *timer;
 
 	struct gpio_descs *current_limit_gpios;
 	struct gpio_mapping *current_limit_map;
@@ -259,6 +260,36 @@ static int init_charge_current_limit(struct device *dev,
 	return 0;
 }
 
+static ssize_t fast_charge_timer_store(struct device *dev,
+				       struct device_attribute *attr,
+				       const char *buf, size_t count)
+{
+	struct power_supply *psy = dev_get_drvdata(dev);
+	struct gpio_charger *gpio_charger = power_supply_get_drvdata(psy);
+	int ret;
+	bool en;
+
+	if (kstrtobool(buf, &en))
+		return -EINVAL;
+
+	if (!gpio_charger->timer)
+		return -ENODEV;
+
+	ret = gpiod_set_value_cansleep(gpio_charger->timer, en);
+	if (ret)
+		return ret;
+
+	return count;
+}
+
+static DEVICE_ATTR_WO(fast_charge_timer);
+
+static struct attribute *gpio_charger_attrs[] = {
+	&dev_attr_fast_charge_timer.attr,
+	NULL
+};
+ATTRIBUTE_GROUPS(gpio_charger);
+
 /*
  * The entries will be overwritten by driver's probe routine depending
  * on the available features. This list ensures, that the array is big
@@ -308,6 +339,13 @@ static int gpio_charger_probe(struct platform_device *pdev)
 		num_props++;
 	}
 
+	gpio_charger->timer = devm_gpiod_get_optional(dev, "fast-charge-timer",
+						      GPIOD_OUT_HIGH);
+	if (IS_ERR(gpio_charger->timer)) {
+		return dev_err_probe(dev, PTR_ERR(gpio_charger->timer),
+				     "error getting fast-charge timer GPIO descriptor\n");
+	}
+
 	charge_status = devm_gpiod_get_optional(dev, "charge-status", GPIOD_IN);
 	if (IS_ERR(charge_status))
 		return PTR_ERR(charge_status);
@@ -336,6 +374,7 @@ static int gpio_charger_probe(struct platform_device *pdev)
 
 	psy_cfg.fwnode = dev_fwnode(dev);
 	psy_cfg.drv_data = gpio_charger;
+	psy_cfg.attr_grp = gpio_charger_groups;
 
 	if (pdata) {
 		charger_desc->name = pdata->name;

-- 
2.39.5

