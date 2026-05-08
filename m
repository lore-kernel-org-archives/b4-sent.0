From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Fri, 08 May 2026 16:33:18 -0700
Subject: [PATCH 6/7] hwmon: (pmbus/adm1266) register rtc_class device
 backed by SET_RTC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-adm1266-v1-6-ec08bf29e0ce@nexthop.ai>
References: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
In-Reply-To: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
To: Guenter Roeck <linux@roeck-us.net>, 
 Alexandru Tachici <alexandru.tachici@analog.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4580;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=Sbalav5wpk7aw5LhFxxqpIjXgttjJK4J1yM10NZgh4g=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZP4rOtL6fVH/4WoW1Y13jF/utZVOsXC8JG/Otm3Lb
 XG+jvdvL8/oKGVhEONikBVTZJnzyP9NW0dbxIaYQ/Ywc1iZQIYwcHEKwETMvzEy7CvU/VF1kZE9
 si1bKGrzm8gJjiV3l4dlzL6hnTM7Q7uVm5Hh1NLqqBmrk+zmFm9qX5T4zO7LCY4vtZuPTZS34Zj
 Y8dmPHQCjYU9s
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADM1266 internal oscillator is not specified for accurate time
keeping. Per the datasheet Rev. D, page 22, host software should
"frequently send the time stamp to the ADM1266 to synchronize the
UNIX time and reduce the time from drifting." Today the driver
seeds the RTC once at probe and provides no way for userspace to
re-seed it later, so blackbox record timestamps drift unboundedly
on long-uptime systems.

Register an rtc_class device backed by the SET_RTC block-R/W
register (0xDF, datasheet Rev. D, Table 84). This creates a
standard /dev/rtcN device whose ->set_time and ->read_time write
and read the same 6-byte SET_RTC frame (32-bit seconds since
1970-01-01 UTC plus a 16-bit fractional-seconds field). Standard
userspace tooling (hwclock --systohc, chrony, systemd-timesyncd)
can now drive the periodic re-sync the data sheet recommends, with
no driver-specific sysfs ABI.

The probe-time wall-clock seed is preserved so the device has a
sane RTC even before userspace runs.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/hwmon/pmbus/adm1266.c | 90 ++++++++++++++++++++++++++++++++++++-------
 1 file changed, 76 insertions(+), 14 deletions(-)

diff --git a/drivers/hwmon/pmbus/adm1266.c b/drivers/hwmon/pmbus/adm1266.c
index a058616d4215..07c20746f083 100644
--- a/drivers/hwmon/pmbus/adm1266.c
+++ b/drivers/hwmon/pmbus/adm1266.c
@@ -18,6 +18,7 @@
 #include <linux/nvmem-consumer.h>
 #include <linux/nvmem-provider.h>
 #include "pmbus.h"
+#include <linux/rtc.h>
 #include <linux/slab.h>
 #include <linux/timekeeping.h>
 
@@ -513,28 +514,85 @@ static int adm1266_config_nvmem(struct adm1266_data *data)
 	return 0;
 }
 
-static int adm1266_set_rtc(struct adm1266_data *data)
+/*
+ * SET_RTC frame layout (datasheet Rev. D, Table 84):
+ *   bytes [1:0] = fractional seconds, LSB = 1/65536 s
+ *   bytes [5:2] = seconds since 1970-01-01 UTC
+ */
+static int adm1266_write_rtc(struct i2c_client *client, const struct timespec64 *ts)
 {
-	struct timespec64 ts;
-	char write_buf[6];
+	u8 buf[6];
 	u16 frac;
 	int i;
 
+	frac = (u16)(((u64)ts->tv_nsec << 16) / NSEC_PER_SEC);
+	for (i = 0; i < 2; i++)
+		buf[i] = (frac >> (i * 8)) & 0xFF;
+	for (i = 0; i < 4; i++)
+		buf[2 + i] = (ts->tv_sec >> (i * 8)) & 0xFF;
+
+	return i2c_smbus_write_block_data(client, ADM1266_SET_RTC, sizeof(buf), buf);
+}
+
+static int adm1266_set_rtc(struct adm1266_data *data)
+{
+	struct timespec64 ts;
+
 	ktime_get_real_ts64(&ts);
+	return adm1266_write_rtc(data->client, &ts);
+}
 
-	/*
-	 * SET_RTC frame layout (datasheet Rev. D, Table 84):
-	 *   bytes [1:0] = fractional seconds, LSB = 1/65536 s
-	 *   bytes [5:2] = seconds since 1970-01-01 UTC
-	 */
-	frac = (u16)(((u64)ts.tv_nsec << 16) / NSEC_PER_SEC);
-	for (i = 0; i < 2; i++)
-		write_buf[i] = (frac >> (i * 8)) & 0xFF;
+static int adm1266_rtc_read_time(struct device *dev, struct rtc_time *tm)
+{
+	struct i2c_client *client = to_i2c_client(dev);
+	u8 buf[I2C_SMBUS_BLOCK_MAX];
+	u32 secs;
+	int ret;
+	int i;
+
+	ret = i2c_smbus_read_block_data(client, ADM1266_SET_RTC, buf);
+	if (ret < 0)
+		return ret;
+	if (ret != 6)
+		return -EIO;
+
+	secs = 0;
 	for (i = 0; i < 4; i++)
-		write_buf[2 + i] = (ts.tv_sec >> (i * 8)) & 0xFF;
+		secs |= (u32)buf[2 + i] << (i * 8);
 
-	return i2c_smbus_write_block_data(data->client, ADM1266_SET_RTC, sizeof(write_buf),
-					  write_buf);
+	rtc_time64_to_tm(secs, tm);
+	return 0;
+}
+
+static int adm1266_rtc_set_time(struct device *dev, struct rtc_time *tm)
+{
+	struct i2c_client *client = to_i2c_client(dev);
+	struct timespec64 ts = {
+		.tv_sec = rtc_tm_to_time64(tm),
+		.tv_nsec = 0,
+	};
+
+	return adm1266_write_rtc(client, &ts);
+}
+
+static const struct rtc_class_ops adm1266_rtc_ops = {
+	.read_time = adm1266_rtc_read_time,
+	.set_time = adm1266_rtc_set_time,
+};
+
+static int adm1266_register_rtc(struct adm1266_data *data)
+{
+	struct rtc_device *rtc;
+
+	rtc = devm_rtc_allocate_device(&data->client->dev);
+	if (IS_ERR(rtc))
+		return PTR_ERR(rtc);
+
+	rtc->ops = &adm1266_rtc_ops;
+	rtc->range_min = 0;
+	rtc->range_max = U32_MAX;
+
+	return devm_rtc_register_device(rtc);
 }
 
 static int adm1266_probe(struct i2c_client *client)
@@ -564,6 +622,10 @@ static int adm1266_probe(struct i2c_client *client)
 	if (ret < 0)
 		return ret;
 
+	ret = adm1266_register_rtc(data);
+	if (ret < 0)
+		return ret;
+
 	ret = adm1266_config_nvmem(data);
 	if (ret < 0)
 		return ret;

-- 
2.53.0

