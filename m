From: Gregory Fuchedgi <gfuchedgi@gmail.com>
Date: Thu, 04 Sep 2025 10:33:45 -0700
Subject: [PATCH v3 2/2] hwmon: (tps23861) add class restrictions and
 semi-auto mode support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-hwmon-tps23861-add-class-restrictions-v3-2-b4e33e6d066c@gmail.com>
References: <20250904-hwmon-tps23861-add-class-restrictions-v3-0-b4e33e6d066c@gmail.com>
In-Reply-To: <20250904-hwmon-tps23861-add-class-restrictions-v3-0-b4e33e6d066c@gmail.com>
To: Robert Marko <robert.marko@sartura.hr>, 
 Luka Perkov <luka.perkov@sartura.hr>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Gregory Fuchedgi <gfuchedgi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757007242; l=14027;
 i=gfuchedgi@gmail.com; s=20250811; h=from:subject:message-id;
 bh=uEEJhtco22XR9vWCDdxLHrPxqD55wHrJqx5SHjzRZ5g=;
 b=Ylg/s3OmMeKm9dRwkWbnLFL9yX9Y+dZvEMOwb1RXRU2sqUfJGgoLNpZ113LupDgDSRH6BJwgd
 JhCgfrJTjnmBwvRwXh+tYFqfPNTEWnFhNEqF1ANcAjvmJOOdz82l5F9
X-Developer-Key: i=gfuchedgi@gmail.com; a=ed25519;
 pk=J3o48+1a2mUIebH8K4S3SPuR5bmamUvjlsf8onoIccA=
X-Endpoint-Received: by B4 Relay for gfuchedgi@gmail.com/20250811 with auth_id=484
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit adds optional individual per-port device tree nodes, in which
ports can be:
  - restricted by class. For example, ti,class = <2> for a port would only
    enable power if class 1 or class 2 were negotiated. Requires interrupt
    handler to be configured if class != 4 (max supported). This is because
    hardware cannot be set with acceptable classes in advance. So the
    driver would enable Semi-Auto mode and in the interrupt handler would
    check negotiated class against device tree config and enable power only
    if it is acceptable class.
  - fully disabled. For boards that do not use all 4 ports. This would put
    disabled ports in Off state and would hide corresponding hwmon files.
  - off by default. The port is kept disabled, until enabled via
    corresponding in_enable in sysfs.

The driver keeps current behavior of using Auto mode for all ports if no
per-port device tree nodes given.

This commit also adds optional reset and ti,ports-shutdown pin support:
  - if reset pin is configured the chip will be reset in probe.
  - if both reset and shutdown pins are configured the driver would keep
    ports shut down while configuring the tps23861 over i2c. Having both
    shutdown and reset pins ensures no PoE activity happens while i2c
    configuration is happening.

Tested with hw poe tester:
 - Auto mode tested with no per-port DT settings as well as explicit port
   DT ti,class=4. Tested that no IRQ is required in this case.
 - Semi-Auto mode with class restricted to 0, 1, 2 or 3. IRQ required.
 - Tested current cut-offs in Semi-Auto mode.
 - On/off by default setting tested for both Auto and Semi-Auto modes.
 - Tested fully disabling the ports in DT.
 - Tested with both reset and ti,ports-shutdown gpios defined, as well as
   with reset only, as well as with neither reset nor shutdown.

Signed-off-by: Gregory Fuchedgi <gfuchedgi@gmail.com>
---
 Documentation/hwmon/tps23861.rst |   6 +-
 drivers/hwmon/tps23861.c         | 249 ++++++++++++++++++++++++++++++++++++++-
 2 files changed, 249 insertions(+), 6 deletions(-)

diff --git a/Documentation/hwmon/tps23861.rst b/Documentation/hwmon/tps23861.rst
index 46d121ff3f316d977ab3d1ab4e0d7b7736a57c60..5d14f683d0de11091f4a845a78a613604cbde4cc 100644
--- a/Documentation/hwmon/tps23861.rst
+++ b/Documentation/hwmon/tps23861.rst
@@ -22,9 +22,13 @@ and monitoring capabilities.
 
 TPS23861 offers three modes of operation: Auto, Semi-Auto and Manual.
 
-This driver only supports the Auto mode of operation providing monitoring
+This driver supports Auto and Semi-Auto modes of operation providing monitoring
 as well as enabling/disabling the four ports.
 
+Ports that do not have associated child device tree entry or do not restrict poe
+class to 3 or lower will operate in Auto mode. Otherwise the port will port will
+operate in Semi-Auto mode and require an interrupt pin.
+
 Sysfs entries
 -------------
 
diff --git a/drivers/hwmon/tps23861.c b/drivers/hwmon/tps23861.c
index 4cb3960d51704f6ad4106adc927f213d090c0f9a..c43c667c5d7e6f7813f8ac6bc5267cb8fe562f9c 100644
--- a/drivers/hwmon/tps23861.c
+++ b/drivers/hwmon/tps23861.c
@@ -10,13 +10,26 @@
 #include <linux/bitfield.h>
 #include <linux/debugfs.h>
 #include <linux/delay.h>
+#include <linux/gpio/consumer.h>
 #include <linux/hwmon-sysfs.h>
 #include <linux/hwmon.h>
 #include <linux/i2c.h>
+#include <linux/interrupt.h>
 #include <linux/module.h>
 #include <linux/of.h>
+#include <linux/of_irq.h>
 #include <linux/regmap.h>
 
+#define MAX_SUPPORTED_POE_CLASS		4
+#define INTERRUPT_STATUS		0x0
+#define INTERRUPT_ENABLE		0x1
+#define INTERRUPT_CLASS			BIT(4)
+#define DETECTION_EVENT			0x5
+#define POWER_STATUS			0x10
+#define PORT_1_ICUT			0x2A
+#define PORT_1_ICUT_MASK		GENMASK(2, 0)
+#define RESET				0x1a
+#define RESET_CLRAIN			0x80
 #define TEMPERATURE			0x2c
 #define INPUT_VOLTAGE_LSB		0x2e
 #define INPUT_VOLTAGE_MSB		0x2f
@@ -102,6 +115,12 @@
 #define TPS23861_GENERAL_MASK_1		0x17
 #define TPS23861_CURRENT_SHUNT_MASK	BIT(0)
 
+#define TPS23861_TIME_RESET_US		5
+#define TPS23861_TIME_RESET_US_MAX	1000
+
+#define TPS23861_TIME_POWER_ON_RESET_MS 23
+#define TPS23861_TIME_I2C_MS		20
+
 #define TEMPERATURE_LSB			652 /* 0.652 degrees Celsius */
 #define VOLTAGE_LSB			3662 /* 3.662 mV */
 #define SHUNT_RESISTOR_DEFAULT		255000 /* 255 mOhm */
@@ -110,10 +129,28 @@
 #define RESISTANCE_LSB			110966 /* 11.0966 Ohm*/
 #define RESISTANCE_LSB_LOW		157216 /* 15.7216 Ohm*/
 
+struct tps23861_port_data { // From DT.
+	const char *label;
+	/* Maximum class accepted by the port. The hardware cannot be
+	 * preconfigured to accept certain class only, so classification
+	 * interrupt handler is required to for power-on decision if class is
+	 * not MAX_SUPPORTED_POE_CLASS.
+	 */
+	u32 class;
+	/* true if the port is disabled in the DT */
+	bool fully_disabled;
+	/* true if the port shouldn't be enabled on driver init */
+	bool off_by_default;
+};
+
 struct tps23861_data {
 	struct regmap *regmap;
 	u32 shunt_resistor;
 	struct i2c_client *client;
+	struct gpio_desc *reset_gpio;
+	struct gpio_desc *shutdown_gpio;
+	int irq;
+	struct tps23861_port_data ports[TPS23861_NUM_PORTS];
 };
 
 static const struct regmap_config tps23861_regmap_config = {
@@ -205,13 +242,19 @@ static int tps23861_port_enable(struct tps23861_data *data, int channel)
 	regval |= BIT(channel);
 	regval |= BIT(channel + 4);
 	err = regmap_write(data->regmap, DETECT_CLASS_RESTART, regval);
-
-	return err;
+	if (err)
+		return err;
+	return regmap_write(data->regmap, RESET, RESET_CLRAIN);
 }
 
-static umode_t tps23861_is_visible(const void *data, enum hwmon_sensor_types type,
+static umode_t tps23861_is_visible(const void *input_data, enum hwmon_sensor_types type,
 				   u32 attr, int channel)
 {
+	const struct tps23861_data *data = input_data;
+
+	/* Channel may be >=TPS23861_NUM_PORTS for common Input voltage */
+	if (channel < TPS23861_NUM_PORTS && data->ports[channel].fully_disabled)
+		return 0;
 	switch (type) {
 	case hwmon_temp:
 		switch (attr) {
@@ -325,10 +368,15 @@ static int tps23861_read_string(struct device *dev,
 				enum hwmon_sensor_types type,
 				u32 attr, int channel, const char **str)
 {
+	struct tps23861_data *data = dev_get_drvdata(dev);
+
 	switch (type) {
 	case hwmon_in:
 	case hwmon_curr:
-		*str = tps23861_port_label[channel];
+		if (channel < TPS23861_NUM_PORTS)
+			*str = data->ports[channel].label;
+		else
+			*str = tps23861_port_label[channel];
 		break;
 	case hwmon_temp:
 		*str = "Die";
@@ -502,17 +550,155 @@ static int tps23861_port_status_show(struct seq_file *s, void *data)
 
 DEFINE_SHOW_ATTRIBUTE(tps23861_port_status);
 
+static inline bool tps23861_auto_mode(struct tps23861_port_data *port)
+{
+	return port->class == MAX_SUPPORTED_POE_CLASS;
+}
+
+static irqreturn_t tps23861_irq_handler(int irq, void *dev_id)
+{
+	struct tps23861_data *data = (struct tps23861_data *)dev_id;
+	struct tps23861_port_data *ports = data->ports;
+	struct device *dev = &data->client->dev;
+
+	unsigned int intr_status, status, class, i;
+	unsigned int det_status = 0;
+	int ret;
+
+	ret = regmap_read(data->regmap, INTERRUPT_STATUS, &intr_status);
+	if (ret || intr_status == 0)
+		return IRQ_NONE;
+	if (intr_status & INTERRUPT_CLASS) {
+		regmap_read(data->regmap, DETECTION_EVENT, &det_status);
+		for (i = 0; i < TPS23861_NUM_PORTS; i++) {
+			if (tps23861_auto_mode(ports + i))
+				continue;
+			if (!(det_status & BIT(i + 4)))
+				continue;
+			ret = regmap_read(data->regmap, PORT_1_STATUS + i, &status);
+			if (ret)
+				continue;
+			class = FIELD_GET(PORT_STATUS_CLASS_MASK, status);
+			if (class == PORT_CLASS_0) {
+				/* class 0 is same power as class 3, change 0 to
+				 * 3 for easy comparison
+				 */
+				class = 3;
+			}
+			if (class == PORT_CLASS_UNKNOWN ||
+			    class > MAX_SUPPORTED_POE_CLASS)
+				continue;
+			if (class > ports[i].class) {
+				dev_info(dev, "%s class mismatch: got %d, want <= %d",
+					 ports[i].label, class, ports[i].class);
+				continue;
+			}
+			regmap_read(data->regmap, POWER_STATUS, &status);
+			if (status & BIT(i))
+				continue; /* already enabled */
+			/* Set ICUT and poe+ according to class. Values in ICUT table happen
+			 * to match class values, so just set class.
+			 */
+			regmap_update_bits(data->regmap,
+					   PORT_1_ICUT + i / 2,
+					   PORT_1_ICUT_MASK << ((i % 2) * 4),
+					   class << ((i % 2) * 4));
+			regmap_update_bits(data->regmap, POE_PLUS,
+					   BIT(i + 4),
+					   class > 3 ? BIT(i + 4) : 0);
+			dev_info(dev, "%s class %d, enabling power",
+				 ports[i].label, class);
+			regmap_write(data->regmap, POWER_ENABLE, BIT(i));
+		}
+	}
+	regmap_write(data->regmap, RESET, RESET_CLRAIN);
+	return IRQ_HANDLED;
+}
+
+static int tps23861_reset(struct i2c_client *client)
+{
+	struct tps23861_data *data = i2c_get_clientdata(client);
+	unsigned int val;
+
+	if (data->reset_gpio) {
+		gpiod_direction_output(data->reset_gpio, true);
+		/* If shutdown pin is defined, use it to keep ports off, while
+		 * turning the chip on for i2c configuration.
+		 */
+		if (data->shutdown_gpio)
+			gpiod_direction_output(data->shutdown_gpio, true);
+		usleep_range(TPS23861_TIME_RESET_US, TPS23861_TIME_RESET_US_MAX);
+		gpiod_set_value_cansleep(data->reset_gpio, false);
+		msleep(TPS23861_TIME_POWER_ON_RESET_MS);
+		if (data->shutdown_gpio)
+			gpiod_set_value_cansleep(data->shutdown_gpio, false);
+		msleep(TPS23861_TIME_I2C_MS);
+	}
+
+	/* Check the device is responsive */
+	return regmap_read(data->regmap, OPERATING_MODE, &val);
+}
+
+static void tps23861_init_ports(struct i2c_client *client)
+{
+	struct tps23861_data *data = i2c_get_clientdata(client);
+	struct tps23861_port_data *ports = data->ports;
+	unsigned int i, mode;
+
+	for (i = 0; i < TPS23861_NUM_PORTS; i++) {
+		mode = ports[i].fully_disabled	     ? OPERATING_MODE_OFF :
+		       tps23861_auto_mode(&ports[i]) ? OPERATING_MODE_AUTO :
+						       OPERATING_MODE_SEMI;
+		regmap_update_bits(data->regmap, OPERATING_MODE,
+				   OPERATING_MODE_PORT_1_MASK << (2 * i),
+				   mode << (2 * i));
+		if (ports[i].fully_disabled)
+			continue;
+		if (ports[i].off_by_default)
+			tps23861_port_disable(data, i);
+		else
+			tps23861_port_enable(data, i);
+	}
+}
+
 static int tps23861_probe(struct i2c_client *client)
 {
 	struct device *dev = &client->dev;
 	struct tps23861_data *data;
+	struct tps23861_port_data *ports;
 	struct device *hwmon_dev;
+	struct gpio_desc *gpio;
+	struct device_node *child;
 	u32 shunt_resistor;
+	int ret;
+	unsigned int i;
+	bool need_irq = false;
+	const char *hwmon_name = client->name;
 
 	data = devm_kzalloc(dev, sizeof(*data), GFP_KERNEL);
 	if (!data)
 		return -ENOMEM;
 
+	ports = data->ports;
+	for (i = 0; i < TPS23861_NUM_PORTS; i++) {
+		ports[i].label = tps23861_port_label[i];
+		ports[i].class = MAX_SUPPORTED_POE_CLASS;
+	}
+
+	gpio = devm_gpiod_get_optional(dev, "reset", GPIOD_ASIS);
+	if (IS_ERR(gpio)) {
+		devm_kfree(dev, data);
+		return -EPROBE_DEFER;
+	}
+	data->reset_gpio = gpio;
+
+	gpio = devm_gpiod_get_optional(dev, "ti,ports-shutdown", GPIOD_ASIS);
+	if (IS_ERR(gpio)) {
+		devm_kfree(dev, data);
+		return -EPROBE_DEFER;
+	}
+	data->shutdown_gpio = gpio;
+
 	data->client = client;
 	i2c_set_clientdata(client, data);
 
@@ -521,6 +707,55 @@ static int tps23861_probe(struct i2c_client *client)
 		dev_err(dev, "failed to allocate register map\n");
 		return PTR_ERR(data->regmap);
 	}
+	ret = tps23861_reset(client);
+	if (ret)
+		return -ENODEV;
+	for_each_child_of_node(dev->of_node, child) {
+		ret = of_property_read_u32(child, "reg", &i);
+		if (ret || i >= TPS23861_NUM_PORTS) {
+			dev_err(dev, "node %s must define 'reg' < %d\n",
+				child->name, TPS23861_NUM_PORTS);
+			continue;
+		}
+		if (!of_device_is_available(child)) {
+			ports[i].fully_disabled = true;
+			continue;
+		}
+		ports[i].off_by_default = of_property_read_bool(child, "ti,off-by-default");
+		of_property_read_string(child, "label", &ports[i].label);
+		of_property_read_u32(child, "ti,class", &ports[i].class);
+		if (ports[i].class > MAX_SUPPORTED_POE_CLASS) {
+			dev_err(dev, "%s invalid class, disabling\n", ports[i].label);
+			ports[i].fully_disabled = true;
+			continue;
+		}
+		if (ports[i].class == 0) {
+			/* class 0 is same power as class 3, change 0 to 3 for
+			 * easy comparison
+			 */
+			ports[i].class = 3;
+		}
+		need_irq = need_irq || !tps23861_auto_mode(&ports[i]);
+		dev_info(dev, "%s: max class: %d, %s by default\n",
+			 ports[i].label, ports[i].class,
+			 ports[i].off_by_default ? "off" : "on");
+	}
+	if (need_irq) {
+		data->irq = irq_of_parse_and_map(dev->of_node, 0);
+		if (!data->irq) {
+			dev_err(dev, "failed to configure irq\n");
+			return -EINVAL;
+		}
+		ret = devm_request_threaded_irq(dev, data->irq, NULL,
+						tps23861_irq_handler,
+						IRQF_TRIGGER_FALLING,
+						"tps23861_irq", data);
+		if (ret) {
+			dev_err(dev, "failed to request irq %d\n", data->irq);
+			return ret;
+		}
+		regmap_write(data->regmap, INTERRUPT_ENABLE, INTERRUPT_CLASS);
+	}
 
 	if (!of_property_read_u32(dev->of_node, "shunt-resistor-micro-ohms", &shunt_resistor))
 		data->shunt_resistor = shunt_resistor;
@@ -536,7 +771,11 @@ static int tps23861_probe(struct i2c_client *client)
 				TPS23861_GENERAL_MASK_1,
 				TPS23861_CURRENT_SHUNT_MASK);
 
-	hwmon_dev = devm_hwmon_device_register_with_info(dev, client->name,
+	of_property_read_string(dev->of_node, "label", &hwmon_name);
+
+	tps23861_init_ports(client);
+
+	hwmon_dev = devm_hwmon_device_register_with_info(dev, hwmon_name,
 							 data, &tps23861_chip_info,
 							 NULL);
 	if (IS_ERR(hwmon_dev))

-- 
2.43.0

