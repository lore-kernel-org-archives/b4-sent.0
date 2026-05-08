From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Fri, 08 May 2026 16:33:16 -0700
Subject: [PATCH 4/7] hwmon: (pmbus/adm1266) add clear_blackbox debugfs
 entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-adm1266-v1-4-ec08bf29e0ce@nexthop.ai>
References: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
In-Reply-To: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
To: Guenter Roeck <linux@roeck-us.net>, 
 Alexandru Tachici <alexandru.tachici@analog.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2640;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=k9XGGAziLKna9OD3zoDFGbWFq64Y+DfU8TmPayUhAPg=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZP4rOhLF4R476eTDJDWTCnnva0bvAw4UeUy4p5mxi
 N152uW81486SlkYxLgYZMUUWeY88n/T1tEWsSHmkD3MHFYmkCEMXJwCMBEOKUaGqRVNVgni0ic7
 raZn7j77sKDzv+WP5z1cNdv3zTjnu/VXOsNPxoiuH5+d8nJ9Q9jfS4g+qXPp2Zw1p/z5vociV5l
 Fgo4zAQA54U+X
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADM1266 blackbox can be configured in two recording modes via
BLACKBOX_CONFIG[0]: cyclic, where the device overwrites the oldest
record once the 32-record buffer fills, and single, where it stops
recording until the buffer is cleared. Deployments that need to
preserve the full record history across multiple fault episodes
typically run in single mode and need a way to clear the buffer
after the records have been collected.

Expose a write-only debugfs file alongside sequencer_state. Writing
any data to it issues the documented clear-blackbox sub-command:
a 2-byte block-write to READ_BLACKBOX (0xDE) with payload
{0xFE, 0x00} (datasheet Rev. D).

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/hwmon/pmbus/adm1266.c | 32 ++++++++++++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/drivers/hwmon/pmbus/adm1266.c b/drivers/hwmon/pmbus/adm1266.c
index 5cfca00a4468..4c8d2e9e07dd 100644
--- a/drivers/hwmon/pmbus/adm1266.c
+++ b/drivers/hwmon/pmbus/adm1266.c
@@ -356,6 +356,36 @@ static int adm1266_firmware_revision_read(struct seq_file *s, void *pdata)
 	return 0;
 }
 
+/*
+ * Clearing the blackbox is required when the device is configured in
+ * single-recording mode (BLACKBOX_CONFIG[0] = 0): once the 32-record
+ * buffer is full the device stops recording until cleared.
+ *
+ * The clear is issued as a 2-byte block-write to READ_BLACKBOX with
+ * payload {0xFE, 0x00} per the datasheet.
+ */
+static ssize_t adm1266_clear_blackbox_write(struct file *file, const char __user *ubuf,
+					    size_t count, loff_t *ppos)
+{
+	struct i2c_client *client = file->private_data;
+	u8 payload[2] = { 0xFE, 0x00 };
+	int ret;
+
+	ret = i2c_smbus_write_block_data(client, ADM1266_READ_BLACKBOX,
+					 sizeof(payload), payload);
+	if (ret < 0)
+		return ret;
+
+	return count;
+}
+
+static const struct file_operations adm1266_clear_blackbox_fops = {
+	.owner = THIS_MODULE,
+	.open = simple_open,
+	.write = adm1266_clear_blackbox_write,
+	.llseek = noop_llseek,
+};
+
 static void adm1266_init_debugfs(struct adm1266_data *data)
 {
 	struct dentry *root;
@@ -370,6 +400,8 @@ static void adm1266_init_debugfs(struct adm1266_data *data)
 				    adm1266_state_read);
 	debugfs_create_devm_seqfile(&data->client->dev, "firmware_revision", data->debugfs_dir,
 				    adm1266_firmware_revision_read);
+	debugfs_create_file("clear_blackbox", 0200, data->debugfs_dir, data->client,
+			    &adm1266_clear_blackbox_fops);
 }
 
 static int adm1266_nvmem_read_blackbox(struct adm1266_data *data, u8 *read_buff)

-- 
2.53.0

