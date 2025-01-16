From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Thu, 16 Jan 2025 09:04:29 +0100
Subject: [PATCH v2] power: supply: max1720x: add support for reading
 internal and thermistor temperatures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-max1720x-temperature-v2-1-9638969d091a@liebherr.com>
X-B4-Tracking: v=1; b=H4sIAIy9iGcC/4WNTQ6CMBBGr0JmbU2nqA2uuIdhAe0gk8hPpthgS
 O9u5QIu30u+9+0QSJgC3IsdhCIHnqcM5lSAG9rpSYp9ZjDaXDViqcZ2Q2v0plYaF5J2fQspR+5
 m++6isbKQp4tQz9uRfTSZBw7rLJ/jJeLP/glGVKicr7wvu8obtPWLqRtI5OzmEZqU0heKtsJSu
 wAAAA==
X-Change-ID: 20250113-max1720x-temperature-cec67fb40197
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Thomas Antoine <t.antoine@uclouvain.be>, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737014687; l=5333;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=fn4u6JBkLe9ziUbn1gD/a8EhRkjnGm3GtfEWO+TsGa8=;
 b=dAkFeQoN0VmR3Y+MbdFqyhxNmqSOMwbGpepG68DabcRXlIGiMeTUQZQAuwTaWt8V8q9Yl68f7
 60z7AXnRf3/AG60eHn5owQcyl0nhQPaN+tDcXKjfg3FSqc4UKOliR9R
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If enabled in the nPackCfg register, the Temp1, Temp2 and IntTemp registers
contain the temperature readings from the AIN1 thermistor, AIN2 thermistor
and internal die temperature respectively. Registers are shared between SBS
and normal IC functions and are always readable regardless of IC settings.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v2:
- Rename device attribute temp1 to temp_ain1
- Rename device attribute temp2 to temp_ain2
- Rename device attribute int_temp to temp_int
- Add documentation to max1720x to Documentation/ABI/testing/
- Link to v1: https://lore.kernel.org/r/20250113-max1720x-temperature-v1-1-cd9dd3b9d217@liebherr.com
---
 .../ABI/testing/sysfs-class-power-max1720x         | 32 ++++++++++++
 drivers/power/supply/max1720x_battery.c            | 60 +++++++++++++++++++++-
 2 files changed, 91 insertions(+), 1 deletion(-)

diff --git a/Documentation/ABI/testing/sysfs-class-power-max1720x b/Documentation/ABI/testing/sysfs-class-power-max1720x
new file mode 100644
index 0000000000000000000000000000000000000000..7d895bfda9ced2ba089723065b3ec27d1d3204ee
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-class-power-max1720x
@@ -0,0 +1,32 @@
+What:		/sys/class/power_supply/max1720x/temp_ain1
+Date:		January 2025
+KernelVersion:	6.14
+Contact:	Dimitri Fedrau <dimitri.fedrau@liebherr.com>
+Description:
+		Reports the current temperature reading from AIN1 thermistor.
+
+		Access: Read
+
+		Valid values: Represented in 1/10 Degrees Celsius
+
+What:		/sys/class/power_supply/max1720x/temp_ain2
+Date:		January 2025
+KernelVersion:	6.14
+Contact:	Dimitri Fedrau <dimitri.fedrau@liebherr.com>
+Description:
+		Reports the current temperature reading from AIN2 thermistor.
+
+		Access: Read
+
+		Valid values: Represented in 1/10 Degrees Celsius
+
+What:		/sys/class/power_supply/max1720x/temp_int
+Date:		January 2025
+KernelVersion:	6.14
+Contact:	Dimitri Fedrau <dimitri.fedrau@liebherr.com>
+Description:
+		Reports the current temperature reading from internal die.
+
+		Access: Read
+
+		Valid values: Represented in 1/10 Degrees Celsius
diff --git a/drivers/power/supply/max1720x_battery.c b/drivers/power/supply/max1720x_battery.c
index 9c7e14d2c7b87b8194511f36ade16e774281333e..11580e414713b7f42354a8bf4e4ef7bee6e33f36 100644
--- a/drivers/power/supply/max1720x_battery.c
+++ b/drivers/power/supply/max1720x_battery.c
@@ -16,6 +16,11 @@
 
 #include <linux/unaligned.h>
 
+/* SBS compliant registers */
+#define MAX172XX_TEMP1			0x34
+#define MAX172XX_INT_TEMP		0x35
+#define MAX172XX_TEMP2			0x3B
+
 /* Nonvolatile registers */
 #define MAX1720X_NXTABLE0		0x80
 #define MAX1720X_NRSENSE		0xCF	/* RSense in 10^-5 Ohm */
@@ -113,11 +118,15 @@ static const struct regmap_config max1720x_regmap_cfg = {
 };
 
 static const struct regmap_range max1720x_nvmem_allow[] = {
+	regmap_reg_range(MAX172XX_TEMP1, MAX172XX_INT_TEMP),
+	regmap_reg_range(MAX172XX_TEMP2, MAX172XX_TEMP2),
 	regmap_reg_range(MAX1720X_NXTABLE0, MAX1720X_NDEVICE_NAME4),
 };
 
 static const struct regmap_range max1720x_nvmem_deny[] = {
-	regmap_reg_range(0x00, 0x7F),
+	regmap_reg_range(0x00, 0x33),
+	regmap_reg_range(0x36, 0x3A),
+	regmap_reg_range(0x3C, 0x7F),
 	regmap_reg_range(0xE0, 0xFF),
 };
 
@@ -388,6 +397,54 @@ static int max1720x_battery_get_property(struct power_supply *psy,
 	return ret;
 }
 
+static int max1720x_read_temp(struct device *dev, u8 reg, char *buf)
+{
+	struct power_supply *psy = dev_get_drvdata(dev);
+	struct max1720x_device_info *info = power_supply_get_drvdata(psy);
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(info->regmap_nv, reg, &val);
+	if (ret < 0)
+		return ret;
+
+	/*
+	 * Temperature in degrees Celsius starting at absolute zero, -273C or
+	 * 0K with an LSb of 0.1C
+	 */
+	return sysfs_emit(buf, "%d\n", val - 2730);
+}
+
+static ssize_t temp_ain1_show(struct device *dev, struct device_attribute *attr,
+			      char *buf)
+{
+	return max1720x_read_temp(dev, MAX172XX_TEMP1, buf);
+}
+
+static ssize_t temp_ain2_show(struct device *dev, struct device_attribute *attr,
+			      char *buf)
+{
+	return max1720x_read_temp(dev, MAX172XX_TEMP2, buf);
+}
+
+static ssize_t temp_int_show(struct device *dev, struct device_attribute *attr,
+			     char *buf)
+{
+	return max1720x_read_temp(dev, MAX172XX_INT_TEMP, buf);
+}
+
+static DEVICE_ATTR_RO(temp_ain1);
+static DEVICE_ATTR_RO(temp_ain2);
+static DEVICE_ATTR_RO(temp_int);
+
+static struct attribute *max1720x_attrs[] = {
+	&dev_attr_temp_ain1.attr,
+	&dev_attr_temp_ain2.attr,
+	&dev_attr_temp_int.attr,
+	NULL
+};
+ATTRIBUTE_GROUPS(max1720x);
+
 static
 int max1720x_nvmem_reg_read(void *priv, unsigned int off, void *val, size_t len)
 {
@@ -488,6 +545,7 @@ static int max1720x_probe(struct i2c_client *client)
 
 	psy_cfg.drv_data = info;
 	psy_cfg.fwnode = dev_fwnode(dev);
+	psy_cfg.attr_grp = max1720x_groups;
 	i2c_set_clientdata(client, info);
 	info->regmap = devm_regmap_init_i2c(client, &max1720x_regmap_cfg);
 	if (IS_ERR(info->regmap))

---
base-commit: 260d7c5e5392ac41c94152005d416172ba0a906d
change-id: 20250113-max1720x-temperature-cec67fb40197

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

