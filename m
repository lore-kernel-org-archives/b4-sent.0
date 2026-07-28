From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 28 Jul 2026 17:03:50 +0100
Subject: [PATCH 3/5] hwmon: (pmbus/core) Add mapping function to
 pmbus_read_block_data()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260728-hwmon-max20826-support-v1-3-224766e0acd1@analog.com>
References: <20260728-hwmon-max20826-support-v1-0-224766e0acd1@analog.com>
In-Reply-To: <20260728-hwmon-max20826-support-v1-0-224766e0acd1@analog.com>
To: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org
Cc: Mark Brown <broonie@kernel.org>, 
 Alan Tull <atull@opensource.altera.com>, Guenter Roeck <linux@roeck-us.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785254629; l=2984;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=MpoqGzL/f8xXIX/4rv/9LHforDgeFadYOUlsVFzvy08=;
 b=CoNE+nExAud6IUgiFgWP5usMfZRc9+WxlzckO/g26elMTrj7nQL5FZQsoWaD8txnnxMHQpNLJ
 nPjumM52J6ICFKBtHdcMtbaCey4M9rGtL7Z+22KWb38SR62hh/2Ig7f
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is in preparation for adding support to a device which needs to
use it's own read_block implementation.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/hwmon/pmbus/pmbus.h      |  3 +++
 drivers/hwmon/pmbus/pmbus_core.c | 24 ++++++++++++++++++++++--
 2 files changed, 25 insertions(+), 2 deletions(-)

diff --git a/drivers/hwmon/pmbus/pmbus.h b/drivers/hwmon/pmbus/pmbus.h
index 3d5586c67f84..d697939ec892 100644
--- a/drivers/hwmon/pmbus/pmbus.h
+++ b/drivers/hwmon/pmbus/pmbus.h
@@ -459,6 +459,9 @@ struct pmbus_driver_info {
 	int (*read_byte_data)(struct i2c_client *client, int page, int reg);
 	int (*read_word_data)(struct i2c_client *client, int page, int phase,
 			      int reg);
+	/* size of data_buf is I2C_SMBUS_BLOCK_MAX + 2 */
+	int (*read_block_data)(struct i2c_client *client, int page, u8 reg,
+			       char *data_buf);
 	int (*write_byte_data)(struct i2c_client *client, int page, int reg,
 			      u8 byte);
 	int (*write_word_data)(struct i2c_client *client, int page, int reg,
diff --git a/drivers/hwmon/pmbus/pmbus_core.c b/drivers/hwmon/pmbus/pmbus_core.c
index 7b58f7198574..ff4572c473b7 100644
--- a/drivers/hwmon/pmbus/pmbus_core.c
+++ b/drivers/hwmon/pmbus/pmbus_core.c
@@ -533,6 +533,26 @@ static int pmbus_read_block_data(struct i2c_client *client, int page, u8 reg,
 	return rv;
 }
 
+/*
+ * _pmbus_read_block_data() is similar to pmbus_read_block_data(), but checks if
+ * a device specific mapping function exists and calls it if necessary.
+ */
+static int _pmbus_read_block_data(struct i2c_client *client, int page, u8 reg,
+				  char *data_buf)
+{
+	struct pmbus_data *data = i2c_get_clientdata(client);
+	const struct pmbus_driver_info *info = data->info;
+	int status;
+
+	if (info->read_block_data) {
+		status = info->read_block_data(client, page, reg, data_buf);
+		if (status != -ENODATA)
+			return status;
+	}
+
+	return pmbus_read_block_data(client, page, reg, data_buf);
+}
+
 static struct pmbus_sensor *pmbus_find_sensor(struct pmbus_data *data, int page,
 					      int reg)
 {
@@ -678,7 +698,7 @@ static bool __maybe_unused pmbus_check_block_register(struct i2c_client *client,
 	struct pmbus_data *data = i2c_get_clientdata(client);
 	char data_buf[I2C_SMBUS_BLOCK_MAX + 2];
 
-	rv = pmbus_read_block_data(client, page, reg, data_buf);
+	rv = _pmbus_read_block_data(client, page, reg, data_buf);
 	if (rv >= 0 && !(data->flags & PMBUS_SKIP_STATUS_CHECK))
 		rv = pmbus_check_status_cml(client);
 	if (rv < 0 && (data->flags & PMBUS_READ_STATUS_AFTER_FAILED_CHECK))
@@ -3564,7 +3584,7 @@ static ssize_t pmbus_debugfs_block_read(struct file *file, char __user *buf,
 	char data[I2C_SMBUS_BLOCK_MAX + 2] = { 0 };
 
 	scoped_guard(pmbus_lock, client) {
-		rc = pmbus_read_block_data(client, entry->page, entry->reg, data);
+		rc = _pmbus_read_block_data(client, entry->page, entry->reg, data);
 		if (rc < 0)
 			return rc;
 	}

-- 
2.55.0

