From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 23 Mar 2026 17:04:07 +0100
Subject: [PATCH v3 2/2] power: supply: gpio-charger: add support for
 fast-charge timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260323-gpio-charger-timer-v3-2-885796d681a5@liebherr.com>
References: <20260323-gpio-charger-timer-v3-0-885796d681a5@liebherr.com>
In-Reply-To: <20260323-gpio-charger-timer-v3-0-885796d681a5@liebherr.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774281855; l=5009;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=sgtWDyyuZOzl/ITkNr7NiW/b4yVbW9a70XFWcPAqKSc=;
 b=khD+6O5ZJXoDwSEK8kj9wRmS78UwMjnhg11By7S+c8YAjiZAWVzqQXBFviSKR3N9XtCjAsfXk
 Wz3DIG5x82+BP0chcR1TF47YU3QgPrVanpCXqGpgg3lYJ8kjWsVMJlY
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
 .../ABI/testing/sysfs-class-power-gpio-charger     | 14 ++++++
 drivers/power/supply/gpio-charger.c                | 56 +++++++++++++++++++++-
 2 files changed, 69 insertions(+), 1 deletion(-)

diff --git a/Documentation/ABI/testing/sysfs-class-power-gpio-charger b/Documentation/ABI/testing/sysfs-class-power-gpio-charger
new file mode 100644
index 0000000000000000000000000000000000000000..4a14d1d1bee3b96b6c77865e693c892d9bc3e5d6
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-class-power-gpio-charger
@@ -0,0 +1,14 @@
+What:		/sys/class/power_supply/<supply_name>/fast_charge_timer
+Date:		March 2026
+KernelVersion:	7.1.0
+Contact:	Dimitri Fedrau <dimitri.fedrau@liebherr.com>
+Description:
+		This entry enables or disables the timer in fast-charge mode.
+		When enabled the timer is started with a fixed timeout. After
+		timing out, charging is disabled. This provides a backup safety
+		for charge termination. Disabling the timer doesn't have any
+		impact on charge termination.
+
+		Access: Write
+
+		Valid values: 0 (disabled) or 1 (enabled)
diff --git a/drivers/power/supply/gpio-charger.c b/drivers/power/supply/gpio-charger.c
index 2504190eba82e69b79382320e67de6b8f3dedc77..8b67118be38ffd974a67f8bee3b47973903196c5 100644
--- a/drivers/power/supply/gpio-charger.c
+++ b/drivers/power/supply/gpio-charger.c
@@ -32,6 +32,7 @@ struct gpio_charger {
 	struct power_supply_desc charger_desc;
 	struct gpio_desc *gpiod;
 	struct gpio_desc *charge_status;
+	struct gpio_desc *timer;
 
 	struct gpio_descs *current_limit_gpios;
 	struct gpio_mapping *current_limit_map;
@@ -39,6 +40,18 @@ struct gpio_charger {
 	u32 charge_current_limit;
 };
 
+struct gpio_charger_data {
+	bool has_fast_charge_timer;
+};
+
+static const struct gpio_charger_data gpio_charger_data = {
+	.has_fast_charge_timer = false,
+};
+
+static const struct gpio_charger_data bq24081_data = {
+	.has_fast_charge_timer = true,
+};
+
 static irqreturn_t gpio_charger_irq(int irq, void *devid)
 {
 	struct power_supply *charger = devid;
@@ -259,6 +272,36 @@ static int init_charge_current_limit(struct device *dev,
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
@@ -274,6 +317,7 @@ static int gpio_charger_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
 	const struct gpio_charger_platform_data *pdata = dev->platform_data;
+	const struct gpio_charger_data *data = device_get_match_data(dev);
 	struct power_supply_config psy_cfg = {};
 	struct gpio_charger *gpio_charger;
 	struct power_supply_desc *charger_desc;
@@ -308,6 +352,13 @@ static int gpio_charger_probe(struct platform_device *pdev)
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
@@ -336,6 +387,8 @@ static int gpio_charger_probe(struct platform_device *pdev)
 
 	psy_cfg.fwnode = dev_fwnode(dev);
 	psy_cfg.drv_data = gpio_charger;
+	if (data->has_fast_charge_timer)
+		psy_cfg.attr_grp = gpio_charger_groups;
 
 	if (pdata) {
 		charger_desc->name = pdata->name;
@@ -402,7 +455,8 @@ static SIMPLE_DEV_PM_OPS(gpio_charger_pm_ops,
 		gpio_charger_suspend, gpio_charger_resume);
 
 static const struct of_device_id gpio_charger_match[] = {
-	{ .compatible = "gpio-charger" },
+	{ .compatible = "gpio-charger", .data = &gpio_charger_data, },
+	{ .compatible = "ti,bq24081", .data = &bq24081_data, },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, gpio_charger_match);

-- 
2.39.5

