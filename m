From: Colin Huang <u8813345@gmail.com>
Date: Tue, 19 May 2026 15:45:58 +0800
Subject: [PATCH linux dev-6.18 2/2] hwmon: (pmbus) Add Delta Q54SN120A1
 Q54SW120A7 chip
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-dev-6-18-add-delta-q54sn120a1-q54sw120a7-v1-2-9b5eb2c0752e@gmail.com>
References: <20260519-dev-6-18-add-delta-q54sn120a1-q54sw120a7-v1-0-9b5eb2c0752e@gmail.com>
In-Reply-To: <20260519-dev-6-18-add-delta-q54sn120a1-q54sw120a7-v1-0-9b5eb2c0752e@gmail.com>
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779176769; l=2436;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=PebGsfq1DuqlFezv5ighrmMT+0lm6uGfBIr+dq7+zSI=;
 b=f1z+o6sSALXICrqbHd4eszFRFWKyJ/JBo0XfuI2PXC6nJTk5LjLTW/o8HMTzfgj+QyX0yZhg8
 rr1f55mf+vACzVIEWNQG+HhNhwLDYF/ukBEEvxzNor6I+K/1y3luoGK
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the DELTA chips Q54SN120A1, Q54SW120A7 in q54sj108a2,
1/4 Brick DC/DC Regulated Power Module with PMBus support

Signed-off-by: Colin Huang <u8813345@gmail.com>
Link: https://lore.kernel.org/r/20260316-add-q54sn120a1-q54q54sw120a7-v2-2-60e6182cc4a7@gmail.com
Signed-off-by: Guenter Roeck <linux@roeck-us.net>
---
 drivers/hwmon/pmbus/q54sj108a2.c | 18 +++++++++++++++---
 1 file changed, 15 insertions(+), 3 deletions(-)

diff --git a/drivers/hwmon/pmbus/q54sj108a2.c b/drivers/hwmon/pmbus/q54sj108a2.c
index 7b0d292a425a..3068983ceacf 100644
--- a/drivers/hwmon/pmbus/q54sj108a2.c
+++ b/drivers/hwmon/pmbus/q54sj108a2.c
@@ -270,6 +270,8 @@ static const struct file_operations q54sj108a2_fops = {
 
 static const struct i2c_device_id q54sj108a2_id[] = {
 	{ "q54sj108a2", q54sj108a2 },
+	{ "q54sn120a1", q54sj108a2 },
+	{ "q54sw120a7", q54sj108a2 },
 	{ },
 };
 
@@ -279,6 +281,7 @@ static int q54sj108a2_probe(struct i2c_client *client)
 {
 	struct device *dev = &client->dev;
 	u8 buf[I2C_SMBUS_BLOCK_MAX + 1];
+	const struct i2c_device_id *mid;
 	enum chips chip_id;
 	int ret, i;
 	struct dentry *debugfs;
@@ -315,8 +318,12 @@ static int q54sj108a2_probe(struct i2c_client *client)
 		dev_err(dev, "Failed to read Manufacturer Model\n");
 		return ret;
 	}
-	if (ret != 14 || strncmp(buf, "Q54SJ108A2", 10)) {
-		buf[ret] = '\0';
+	buf[ret] = '\0';
+	for (mid = q54sj108a2_id; mid->name[0]; mid++) {
+		if (!strncasecmp(mid->name, buf, strlen(mid->name)))
+			break;
+	}
+	if (!mid->name[0]) {
 		dev_err(dev, "Unsupported Manufacturer Model '%s'\n", buf);
 		return -ENODEV;
 	}
@@ -326,7 +333,10 @@ static int q54sj108a2_probe(struct i2c_client *client)
 		dev_err(dev, "Failed to read Manufacturer Revision\n");
 		return ret;
 	}
-	if (ret != 4 || buf[0] != 'S') {
+	/*
+	 * accept manufacturer revision with optional NUL byte
+	 */
+	if (!(ret == 4 || ret == 5) || buf[0] != 'S') {
 		buf[ret] = '\0';
 		dev_err(dev, "Unsupported Manufacturer Revision '%s'\n", buf);
 		return -ENODEV;
@@ -403,6 +413,8 @@ static int q54sj108a2_probe(struct i2c_client *client)
 
 static const struct of_device_id q54sj108a2_of_match[] = {
 	{ .compatible = "delta,q54sj108a2", .data = (void *)q54sj108a2 },
+	{ .compatible = "delta,q54sn120a1", .data = (void *)q54sj108a2 },
+	{ .compatible = "delta,q54sw120a7", .data = (void *)q54sj108a2 },
 	{ },
 };
 

-- 
2.34.1

