From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sun, 08 Nov 2026 16:55:18 +0100
Subject: [PATCH 2/2] Input: wacom_w9000 - add support for Wacom WEZ01
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-wacom-w9000-wez01-v1-2-c2b5e3466187@dxdmail.cc>
References: <20261108-b4-wacom-w9000-wez01-v1-0-c2b5e3466187@dxdmail.cc>
In-Reply-To: <20261108-b4-wacom-w9000-wez01-v1-0-c2b5e3466187@dxdmail.cc>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hendrik Noack <hendrik-noack@gmx.de>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794153317; l=5466;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=uHsNPsSVjwZ9k3pBmLEr4EVDJPo0qTTh5VfrkgYYpvk=;
 b=euTrEclM8hhUEUb7FkaNgmpgDthAZmc2mpblWZTNJleNRJzRkOihJ29I5KKJ6YBH/mjsU6VmV
 9u+Tz54jIsZDqjzTc19SnmakRFDeVAqplryWMPyHW9oWlmpvBHaiYRD
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The WEZ01 uses the W9000 query and coordinate layout, but it is queried
with a plain 32-byte read that returns the query at offset 16. Its
messages are 17 bytes long, with the packet type in the low nibble of
the first byte, and only coordinate messages (type 1) are handled.
Pressure is 12 bits wide.

The protocol comes from Samsung's GPL driver for the Galaxy Tab S9.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 drivers/input/touchscreen/Kconfig       |  2 +-
 drivers/input/touchscreen/wacom_w9000.c | 53 ++++++++++++++++++++++++++++-----
 2 files changed, 46 insertions(+), 9 deletions(-)

diff --git a/drivers/input/touchscreen/Kconfig b/drivers/input/touchscreen/Kconfig
index 9b9ae8ac3f7f..3c55362cf0d0 100644
--- a/drivers/input/touchscreen/Kconfig
+++ b/drivers/input/touchscreen/Kconfig
@@ -615,7 +615,7 @@ config TOUCHSCREEN_WACOM_W9000
 	depends on I2C
 	help
 	  Say Y here if you have a Wacom W9000-series penabled I2C touchscreen.
-	  This driver supports models W9002 and W9007A.
+	  This driver supports models W9002, W9007A and WEZ01.
 
 	  If unsure, say N.
 
diff --git a/drivers/input/touchscreen/wacom_w9000.c b/drivers/input/touchscreen/wacom_w9000.c
index 4a2629a54167..af319fc3de73 100644
--- a/drivers/input/touchscreen/wacom_w9000.c
+++ b/drivers/input/touchscreen/wacom_w9000.c
@@ -22,8 +22,8 @@
 #define CMD_QUERY_RETRIES	8
 
 /* Message length */
-#define CMD_QUERY_NUM_MAX	9
-#define MSG_COORD_NUM_MAX	12
+#define CMD_QUERY_NUM_MAX	32
+#define MSG_COORD_NUM_MAX	17
 
 /* Commands */
 #define CMD_QUERY		0x2a
@@ -31,6 +31,10 @@
 struct wacom_w9000_variant {
 	const u8 cmd_query_num;
 	const u8 msg_coord_num;
+	/* If set, the query is a plain read and starts at this offset */
+	const u8 query_offset;
+	const u8 msg_coord_type;
+	const u16 pressure_mask;
 	const char *name;
 };
 
@@ -81,18 +85,33 @@ static int wacom_w9000_read(struct i2c_client *client, u8 command, u8 len, u8 *d
 	return 0;
 }
 
-static int wacom_w9000_query(struct wacom_w9000_data *wacom_data)
+static int wacom_w9000_read_query(struct wacom_w9000_data *wacom_data, u8 *buf)
 {
+	const struct wacom_w9000_variant *variant = wacom_data->variant;
 	struct i2c_client *client = wacom_data->client;
+	int len = variant->query_offset + variant->cmd_query_num;
+	int error;
+
+	if (!variant->query_offset)
+		return wacom_w9000_read(client, CMD_QUERY, len, buf);
+
+	error = i2c_master_recv(client, buf, len);
+	if (error != len)
+		return error < 0 ? error : -EIO;
+
+	return 0;
+}
+
+static int wacom_w9000_query(struct wacom_w9000_data *wacom_data)
+{
 	struct device *dev = &wacom_data->client->dev;
-	u8 data[CMD_QUERY_NUM_MAX];
+	u8 buf[CMD_QUERY_NUM_MAX];
+	const u8 *data = &buf[wacom_data->variant->query_offset];
 	int retry;
 	int error;
 
 	for (retry = 0; retry < CMD_QUERY_RETRIES; retry++) {
-		error = wacom_w9000_read(client, CMD_QUERY,
-					 wacom_data->variant->cmd_query_num,
-					 data);
+		error = wacom_w9000_read_query(wacom_data, buf);
 		if (!error && data[0] == 0x0f)
 			break;
 	}
@@ -169,6 +188,10 @@ static void wacom_w9000_coord(struct wacom_w9000_data *wacom_data)
 
 	dev_dbg(dev, "data: %*ph\n", wacom_data->variant->msg_coord_num, data);
 
+	if (wacom_data->variant->msg_coord_type &&
+	    (data[0] & GENMASK(3, 0)) != wacom_data->variant->msg_coord_type)
+		return;
+
 	if (data[0] & BIT(7)) {
 		wacom_data->pen_proximity = true;
 
@@ -179,6 +202,8 @@ static void wacom_w9000_coord(struct wacom_w9000_data *wacom_data)
 		x = get_unaligned_be16(&data[1]);
 		y = get_unaligned_be16(&data[3]);
 		pressure = get_unaligned_be16(&data[5]);
+		if (wacom_data->variant->pressure_mask)
+			pressure &= wacom_data->variant->pressure_mask;
 
 		if (wacom_data->variant->msg_coord_num > 7)
 			distance = data[7];
@@ -266,7 +291,8 @@ static int wacom_w9000_probe(struct i2c_client *client)
 		return -EINVAL;
 	}
 
-	if (wacom_data->variant->cmd_query_num > CMD_QUERY_NUM_MAX ||
+	if (wacom_data->variant->query_offset +
+	    wacom_data->variant->cmd_query_num > CMD_QUERY_NUM_MAX ||
 	    wacom_data->variant->msg_coord_num > MSG_COORD_NUM_MAX) {
 		dev_err(dev, "Length of message for %s exceeds the maximum\n",
 			wacom_data->variant->name);
@@ -412,10 +438,20 @@ static const struct wacom_w9000_variant w9007a_v1 = {
 	.name = "Wacom W9007A V1 Digitizer",
 };
 
+static const struct wacom_w9000_variant wez01_gts9 = {
+	.cmd_query_num	= 16,
+	.msg_coord_num	= 17,
+	.query_offset	= 16,
+	.msg_coord_type	= 1,
+	.pressure_mask	= GENMASK(11, 0),
+	.name = "Wacom WEZ01 GTS9 Digitizer",
+};
+
 static const struct of_device_id wacom_w9000_of_match[] = {
 	{ .compatible = "wacom,w9002", .data = &w9002 },
 	{ .compatible = "wacom,w9007a-lt03", .data = &w9007a_lt03, },
 	{ .compatible = "wacom,w9007a-v1", .data = &w9007a_v1, },
+	{ .compatible = "wacom,wez01-gts9", .data = &wez01_gts9 },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, wacom_w9000_of_match);
@@ -424,6 +460,7 @@ static const struct i2c_device_id wacom_w9000_id[] = {
 	{ .name = "w9002", .driver_data = (kernel_ulong_t)&w9002 },
 	{ .name = "w9007a-lt03", .driver_data = (kernel_ulong_t)&w9007a_lt03 },
 	{ .name = "w9007a-v1", .driver_data = (kernel_ulong_t)&w9007a_v1 },
+	{ .name = "wez01-gts9", .driver_data = (kernel_ulong_t)&wez01_gts9 },
 	{ }
 };
 MODULE_DEVICE_TABLE(i2c, wacom_w9000_id);

-- 
2.56.0

