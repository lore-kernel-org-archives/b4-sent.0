From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 05:34:54 +0000
Subject: [PATCH] i2c: slave-eeprom: Add an OF match table for module
 autoload
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-i2c-slave-eeprom-of-match-v1-1-8f762bf06205@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDuQpGC1VyldTOJER6qRjEpBv
 HvTdvkW/x+gnIUV7tUBmXdRSXOBvVQQBpp7RumKwRlXW2sNiguoL9oZmZecJkwRJ1rDgJ7a2Pn
 6Rs3VQOmXzFHev/fj+bdufuSwfodwnh9v7hfcfQAAAA==
X-Change-ID: 20261110-i2c-slave-eeprom-of-match-ba9fdb67a830
To: Andi Shyti <andi.shyti@kernel.org>
Cc: Wolfram Sang <wsa+renesas@sang-engineering.com>, 
 linux-i2c@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794288894; l=3226;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=+qcDKxFvuppZ5+abhrsTQv7e2tAroi0xdMF1879SZxg=;
 b=pm0iwkmNmpUWmwlTZ2MwsyckhAzbSKCamcj+JRKNzWGeYPeOuzMQeknDip50mM8/cPhSwpjFf
 F1boVCkr0loBcJXeYnO7ZXwzWxuwcLjPuUWC0b3/HCppgjejGqz5R+x
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A backend instantiated from the device tree (compatible "slave-24c02",
reg = <(0x64 | I2C_OWN_SLAVE_ADDRESS)>) gets an i2c client, but the
uevent of a client with an of_node carries an of: modalias
(of:N...Cslave-24c02). The module only declares i2c: aliases, so udev
never loads it and the client stays unbound: there is no slave-eeprom
file and no target is registered, with nothing in the log. Only the
sysfs new_device path (i2c: modalias) or a manual modprobe works.

Declare the same names as an OF table and export it, so the module
autoloads for DT and overlay clients. Matching and probe are unchanged:
the client name is the compatible without a vendor prefix, so
i2c_client_get_device_id() still finds the size and flags.

Tested on an Orange Pi Zero2 (H616) with a slave-24c02 node under TWI3
from a DT overlay, using a local target-mode patch for i2c-mv64xxx:
without this change the client stays unbound after boot; with it the
module autoloads, binds to 3-1064 and creates the 256-byte slave-eeprom
file.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
The slave backends have no DT binding (they are debug devices, as
Documentation/i2c/slave-testunit-backend.rst says), so checkpatch reports
the compatibles as undocumented.

This patch was developed with Claude (Anthropic) as a coding assistant:
it investigated the problem, wrote the code and the commit message. I
reviewed it, and it was tested on an Orange Pi Zero2 (H616) as described
above.
---
 drivers/i2c/i2c-slave-eeprom.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/drivers/i2c/i2c-slave-eeprom.c b/drivers/i2c/i2c-slave-eeprom.c
index 226d722af662..a08abd895412 100644
--- a/drivers/i2c/i2c-slave-eeprom.c
+++ b/drivers/i2c/i2c-slave-eeprom.c
@@ -20,6 +20,7 @@
 #include <linux/firmware.h>
 #include <linux/i2c.h>
 #include <linux/init.h>
+#include <linux/mod_devicetable.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/slab.h>
@@ -203,9 +204,28 @@ static const struct i2c_device_id i2c_slave_eeprom_id[] = {
 };
 MODULE_DEVICE_TABLE(i2c, i2c_slave_eeprom_id);
 
+/*
+ * A backend instantiated from the device tree, with the I2C id as
+ * compatible and I2C_OWN_SLAVE_ADDRESS in reg, announces an of: modalias.
+ * List the same names here so that the module autoloads for it.
+ */
+static const struct of_device_id i2c_slave_eeprom_of_match[] = {
+	{ .compatible = "slave-24c02" },
+	{ .compatible = "slave-24c02ro" },
+	{ .compatible = "slave-24c32" },
+	{ .compatible = "slave-24c32ro" },
+	{ .compatible = "slave-24c64" },
+	{ .compatible = "slave-24c64ro" },
+	{ .compatible = "slave-24c512" },
+	{ .compatible = "slave-24c512ro" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, i2c_slave_eeprom_of_match);
+
 static struct i2c_driver i2c_slave_eeprom_driver = {
 	.driver = {
 		.name = "i2c-slave-eeprom",
+		.of_match_table = i2c_slave_eeprom_of_match,
 	},
 	.probe = i2c_slave_eeprom_probe,
 	.remove = i2c_slave_eeprom_remove,

---
base-commit: 00fb8097ca5a4fcf0e0cc1550075aa7313bbd32a
change-id: 20261110-i2c-slave-eeprom-of-match-ba9fdb67a830

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

