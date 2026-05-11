From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Sun, 10 May 2026 21:48:09 -0700
Subject: [PATCH v2 3/5] hwmon: (pmbus/adm1266) add powerup_counter debugfs
 entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260510-adm1266-v2-3-3a22b903c2f1@nexthop.ai>
References: <20260510-adm1266-v2-0-3a22b903c2f1@nexthop.ai>
In-Reply-To: <20260510-adm1266-v2-0-3a22b903c2f1@nexthop.ai>
To: Guenter Roeck <linux@roeck-us.net>, 
 Alexandru Tachici <alexandru.tachici@analog.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2726;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=Fvs4izgDZLwvwAFpe9E0YJJPp97a8WERWKXmnjgLvo4=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZDHGLw35elgxt/ybAsPUKVXcllc7Nd8Xvgv4u3y9y
 ef3fGJnk5I6SlkYxLgYZMUUWeY88n/T1tEWsSHmkD3MHFYmkCEMXJwCMJFXUgz/qwyKWG3XJ6ve
 vrdGat4Wnq2ajDry2c+XbtRwrO7LZDHfwMjQoRn040pLieR9njZ7tel3GfZUauod+/Gr8M9CL+F
 jHusZAWV7S4M=
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADM1266 maintains a 16-bit non-volatile POWERUP_COUNTER register
(0xE4, datasheet Rev. D, Table 93) that increments on every power
cycle and cannot be reset by the host. Each blackbox record already
embeds the counter at record time, so the standalone live value is
primarily useful for matching a captured record back to the boot it
came from when correlating logs.

Expose it as a read-only debugfs file alongside firmware_revision.
The block-read returns two payload bytes in little-endian order.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/hwmon/pmbus/adm1266.c | 28 ++++++++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/drivers/hwmon/pmbus/adm1266.c b/drivers/hwmon/pmbus/adm1266.c
index 31aefa8fc75f..99e92a8365fb 100644
--- a/drivers/hwmon/pmbus/adm1266.c
+++ b/drivers/hwmon/pmbus/adm1266.c
@@ -28,6 +28,7 @@
 #define ADM1266_READ_BLACKBOX	0xDE
 #define ADM1266_SET_RTC		0xDF
 #define ADM1266_GPIO_CONFIG	0xE1
+#define ADM1266_POWERUP_COUNTER	0xE4
 #define ADM1266_BLACKBOX_INFO	0xE6
 #define ADM1266_PDIO_STATUS	0xE9
 #define ADM1266_GPIO_STATUS	0xEA
@@ -356,6 +357,31 @@ static int adm1266_firmware_revision_read(struct seq_file *s, void *pdata)
 	return 0;
 }
 
+/*
+ * POWERUP_COUNTER (0xE4) is a 2-byte little-endian non-volatile counter
+ * that increments on every device power cycle (datasheet Rev. D, Table
+ * 93). It saturates at 65535 and cannot be reset by the host. Each
+ * blackbox record embeds the counter value at record time, so this live
+ * read is mainly useful for matching a record back to its boot.
+ */
+static int adm1266_powerup_counter_read(struct seq_file *s, void *pdata)
+{
+	struct device *dev = s->private;
+	struct i2c_client *client = to_i2c_client(dev);
+	u8 buf[I2C_SMBUS_BLOCK_MAX];
+	int ret;
+
+	ret = i2c_smbus_read_block_data(client, ADM1266_POWERUP_COUNTER, buf);
+	if (ret < 0)
+		return ret;
+	if (ret != 2)
+		return -EIO;
+
+	seq_printf(s, "%u\n", buf[0] | (buf[1] << 8));
+
+	return 0;
+}
+
 /*
  * Clearing the blackbox is required when the device is configured in
  * single-recording mode (BLACKBOX_CONFIG[0] = 0): once the 32-record
@@ -400,6 +426,8 @@ static void adm1266_init_debugfs(struct adm1266_data *data)
 				    adm1266_state_read);
 	debugfs_create_devm_seqfile(&data->client->dev, "firmware_revision", data->debugfs_dir,
 				    adm1266_firmware_revision_read);
+	debugfs_create_devm_seqfile(&data->client->dev, "powerup_counter", data->debugfs_dir,
+				    adm1266_powerup_counter_read);
 	debugfs_create_file("clear_blackbox", 0200, data->debugfs_dir, data->client,
 			    &adm1266_clear_blackbox_fops);
 }

-- 
2.53.0

