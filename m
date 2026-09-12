From: Roman Vivchar <rva333@protonmail.com>
Date: Sat, 12 Sep 2026 20:59:05 +0300
Subject: [PATCH] Input: synaptics-rmi4 - add support for reset gpios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260912-rmi4-reset-v1-1-4a3fc8856830@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDQAxG4atI1h0Yowj2KtLFqL8aQSuJiiDe3
 bFdfov3TjKowOidnKTYxeQ7R6SvhJohzD2ctNHEngtfpux0ktwpDKsrQ9Yyh+A5B8VgUXRy/Gb
 V52/b6hHN+hzoum5syBkebgAAAA==
X-Change-ID: 20260912-rmi4-reset-9a3d22aa024e
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789236069; l=8397;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=SC4bkSgscCz+QLd+mGi3E8BCJE+tAFj7zaREBtUQLHs=;
 b=8n+44RCzB8TMGYrpXtr1As+8TbD0RyZSlJY0hiQO3yrSkJX7PAYHBa8ealuSoCh2w5r8Q37hj
 rp9LmF6GOPyBHJqIq0dy1pRzkTZUORANrHBlzFVkqtJsU2vo3t83XaP
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In some cases, the touchscreen is wired to the always-on regulator, so
resetting is required for proper I2C communication. Add reset support to
the rmi_i2c driver.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Tested on Lenovo Vibe X2 (S3528 IC).
Before:
[    3.944523] rmi4_i2c 2-0038: rmi_set_page: set page failed: -6.
[    3.944615] rmi4_i2c 2-0038: Failed to set page select to 0
[    3.944747] rmi4_i2c 2-0038: Dropping the link to regulator.29
[    3.944917] rmi4_i2c 2-0038: Dropping the link to regulator.0
[    3.945052] rmi4_i2c 2-0038: probe with driver rmi4_i2c rejects match -6

After:
[    3.824640] rmi4_i2c 1-0038: using DT '/soc/i2c@11009000/touchscreen@38' for 'reset' GPIO lookup
[    3.964557] rmi4_i2c 1-0038: registering I2C-connected sensor
[    3.964655] device: 'rmi4-00': device_add
[    3.964682] bus: 'rmi4': add device rmi4-00
[    3.964716] PM: Adding info for rmi4:rmi4-00
[    3.964752] rmi4 rmi4-00: bus: 'rmi4': __driver_probe_device: matched device with driver rmi4_physical
[    3.964768] rmi4 rmi4-00: bus: 'rmi4': really_probe: probing driver rmi4_physical with device
[    3.964788] rmi4_physical rmi4-00: no default pinctrl state
[    4.131969] device: 'rmi4-00.fn34': device_add
[    4.132003] bus: 'rmi4': add device rmi4-00.fn34
[    4.132041] PM: Adding info for rmi4:rmi4-00.fn34
[    4.132077] rmi4 rmi4-00.fn34: bus: 'rmi4': __driver_probe_device: matched device with driver rmi4_f34
[    4.132099] rmi4 rmi4-00.fn34: bus: 'rmi4': really_probe: probing driver rmi4_f34 with device
[    4.132121] rmi4_f34 rmi4-00.fn34: no default pinctrl state
[    4.133001] rmi4_f34 rmi4-00.fn34: rmi_f34v7_probe: Unrecognized bootloader version: 29 (\x1d) 16 (\x10)
[    4.133118] rmi4_f34 rmi4-00.fn34: probe with driver rmi4_f34 failed with error -22
[    4.134425] device: 'rmi4-00.fn01': device_add
[    4.134448] bus: 'rmi4': add device rmi4-00.fn01
[    4.134477] PM: Adding info for rmi4:rmi4-00.fn01
[    4.134502] rmi4 rmi4-00.fn01: bus: 'rmi4': __driver_probe_device: matched device with driver rmi4_f01
[    4.134517] rmi4 rmi4-00.fn01: bus: 'rmi4': really_probe: probing driver rmi4_f01 with device
[    4.134534] rmi4_f01 rmi4-00.fn01: no default pinctrl state
[    4.141919] rmi4_f01 rmi4-00.fn01: found RMI device, manufacturer: Synaptics, product: X2, fw id: 1730877
[    4.144846] rmi4_f01 rmi4-00.fn01: driver: 'rmi4_f01': driver_bound: bound to device
[    4.144898] rmi4_f01 rmi4-00.fn01: bus: 'rmi4': really_probe: bound device to driver rmi4_f01
[    4.145874] device: 'rmi4-00.fn12': device_add
[    4.145901] bus: 'rmi4': add device rmi4-00.fn12
[    4.145935] PM: Adding info for rmi4:rmi4-00.fn12
[    4.145963] rmi4 rmi4-00.fn12: bus: 'rmi4': __driver_probe_device: matched device with driver rmi4_f12
[    4.145980] rmi4 rmi4-00.fn12: bus: 'rmi4': really_probe: probing driver rmi4_f12 with device
[    4.145998] rmi4_f12 rmi4-00.fn12: no default pinctrl state
[    4.159397] rmi4_f12 rmi4-00.fn12: driver: 'rmi4_f12': driver_bound: bound to device
[    4.159446] rmi4_f12 rmi4-00.fn12: bus: 'rmi4': really_probe: bound device to driver rmi4_f12
[    4.161703] device: 'rmi4-00.fn54': device_add
[    4.161730] bus: 'rmi4': add device rmi4-00.fn54
[    4.161764] PM: Adding info for rmi4:rmi4-00.fn54
[    4.164027] device: 'rmi4-00.fn1a': device_add
[    4.164052] bus: 'rmi4': add device rmi4-00.fn1a
[    4.164085] PM: Adding info for rmi4:rmi4-00.fn1a
[    4.164113] rmi4 rmi4-00.fn1a: bus: 'rmi4': __driver_probe_device: matched device with driver rmi4_f1a
[    4.164128] rmi4 rmi4-00.fn1a: bus: 'rmi4': really_probe: probing driver rmi4_f1a with device
[    4.164148] rmi4_f1a rmi4-00.fn1a: no default pinctrl state
[    4.164262] rmi4_f1a rmi4-00.fn1a: driver: 'rmi4_f1a': driver_bound: bound to device
[    4.164302] rmi4_f1a rmi4-00.fn1a: bus: 'rmi4': really_probe: bound device to driver rmi4_f1a
[    4.166558] device: 'rmi4-00.fn55': device_add
[    4.166588] bus: 'rmi4': add device rmi4-00.fn55
[    4.166619] PM: Adding info for rmi4:rmi4-00.fn55
[    4.166648] rmi4 rmi4-00.fn55: bus: 'rmi4': __driver_probe_device: matched device with driver rmi4_f55
[    4.166664] rmi4 rmi4-00.fn55: bus: 'rmi4': really_probe: probing driver rmi4_f55 with device
[    4.166683] rmi4_f55 rmi4-00.fn55: no default pinctrl state
[    4.173199] rmi4_f55 rmi4-00.fn55: driver: 'rmi4_f55': driver_bound: bound to device
[    4.173233] rmi4_f55 rmi4-00.fn55: bus: 'rmi4': really_probe: bound device to driver rmi4_f55
[    4.175496] device: 'rmi4-00.fn51': device_add
[    4.175523] bus: 'rmi4': add device rmi4-00.fn51
[    4.175557] PM: Adding info for rmi4:rmi4-00.fn51
[    4.180078] input: Synaptics X2 as /devices/platform/soc/11009000.i2c/i2c-1/1-0038/rmi4-00/input/input2
[    4.184031] rmi4_physical rmi4-00: driver: 'rmi4_physical': driver_bound: bound to device
[    4.184072] rmi4_physical rmi4-00: bus: 'rmi4': really_probe: bound device to driver rmi4_physical
[    4.184095] rmi4_i2c 1-0038: driver: 'rmi4_i2c': driver_bound: bound to device
[    4.184151] rmi4_i2c 1-0038: bus: 'i2c': really_probe: bound device to driver rmi4_i2c
---
 drivers/input/rmi4/rmi_i2c.c | 29 ++++++++++++++++++++++++++---
 1 file changed, 26 insertions(+), 3 deletions(-)

diff --git a/drivers/input/rmi4/rmi_i2c.c b/drivers/input/rmi4/rmi_i2c.c
index e11d0acb9b96..da560988f44a 100644
--- a/drivers/input/rmi4/rmi_i2c.c
+++ b/drivers/input/rmi4/rmi_i2c.c
@@ -8,6 +8,7 @@
 #include <linux/rmi.h>
 #include <linux/of.h>
 #include <linux/delay.h>
+#include <linux/gpio/consumer.h>
 #include <linux/regulator/consumer.h>
 #include "rmi_driver.h"
 
@@ -40,6 +41,7 @@ struct rmi_i2c_xport {
 
 	struct regulator_bulk_data supplies[2];
 	u32 startup_delay;
+	struct gpio_desc *reset_gpio;
 };
 
 #define RMI_PAGE_SELECT_REGISTER 0xff
@@ -198,6 +200,16 @@ static void rmi_i2c_unregister_transport(void *data)
 	rmi_unregister_transport_device(&rmi_i2c->xport);
 }
 
+static void rmi_i2c_release_reset(struct rmi_i2c_xport *rmi_i2c)
+{
+	if (rmi_i2c->reset_gpio) {
+		usleep_range(10000, 20000);
+		gpiod_set_value_cansleep(rmi_i2c->reset_gpio, 0);
+	}
+
+	msleep(rmi_i2c->startup_delay);
+}
+
 static int rmi_i2c_probe(struct i2c_client *client)
 {
 	struct rmi_device_platform_data *pdata;
@@ -235,6 +247,11 @@ static int rmi_i2c_probe(struct i2c_client *client)
 	if (error < 0)
 		return error;
 
+	rmi_i2c->reset_gpio = devm_gpiod_get_optional(&client->dev, "reset",
+						      GPIOD_OUT_HIGH);
+	if (IS_ERR(rmi_i2c->reset_gpio))
+		return PTR_ERR(rmi_i2c->reset_gpio);
+
 	error = regulator_bulk_enable(ARRAY_SIZE(rmi_i2c->supplies),
 				       rmi_i2c->supplies);
 	if (error < 0)
@@ -249,7 +266,7 @@ static int rmi_i2c_probe(struct i2c_client *client)
 	of_property_read_u32(client->dev.of_node, "syna,startup-delay-ms",
 			     &rmi_i2c->startup_delay);
 
-	msleep(rmi_i2c->startup_delay);
+	rmi_i2c_release_reset(rmi_i2c);
 
 	rmi_i2c->client = client;
 	mutex_init(&rmi_i2c->page_mutex);
@@ -297,6 +314,9 @@ static int rmi_i2c_suspend(struct device *dev)
 	if (ret)
 		dev_warn(dev, "Failed to resume device: %d\n", ret);
 
+	if (rmi_i2c->reset_gpio)
+		gpiod_set_value_cansleep(rmi_i2c->reset_gpio, 1);
+
 	regulator_bulk_disable(ARRAY_SIZE(rmi_i2c->supplies),
 			       rmi_i2c->supplies);
 
@@ -314,7 +334,7 @@ static int rmi_i2c_resume(struct device *dev)
 	if (ret)
 		return ret;
 
-	msleep(rmi_i2c->startup_delay);
+	rmi_i2c_release_reset(rmi_i2c);
 
 	ret = rmi_driver_resume(rmi_i2c->xport.rmi_dev, true);
 	if (ret)
@@ -333,6 +353,9 @@ static int rmi_i2c_runtime_suspend(struct device *dev)
 	if (ret)
 		dev_warn(dev, "Failed to resume device: %d\n", ret);
 
+	if (rmi_i2c->reset_gpio)
+		gpiod_set_value_cansleep(rmi_i2c->reset_gpio, 1);
+
 	regulator_bulk_disable(ARRAY_SIZE(rmi_i2c->supplies),
 			       rmi_i2c->supplies);
 
@@ -350,7 +373,7 @@ static int rmi_i2c_runtime_resume(struct device *dev)
 	if (ret)
 		return ret;
 
-	msleep(rmi_i2c->startup_delay);
+	rmi_i2c_release_reset(rmi_i2c);
 
 	ret = rmi_driver_resume(rmi_i2c->xport.rmi_dev, false);
 	if (ret)

---
base-commit: 68142f986ff04b2b70b31db00f719bf690f64a9a
change-id: 20260912-rmi4-reset-9a3d22aa024e

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

