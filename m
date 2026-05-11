From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Sun, 10 May 2026 21:48:10 -0700
Subject: [PATCH v2 4/5] hwmon: (pmbus/adm1266) replace probe-time RTC seed
 with rtc_class device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260510-adm1266-v2-4-3a22b903c2f1@nexthop.ai>
References: <20260510-adm1266-v2-0-3a22b903c2f1@nexthop.ai>
In-Reply-To: <20260510-adm1266-v2-0-3a22b903c2f1@nexthop.ai>
To: Guenter Roeck <linux@roeck-us.net>, 
 Alexandru Tachici <alexandru.tachici@analog.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4478;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=4ibCJKgh5O0PlQIzarHRly8PpVR0ik1+YJcgF8LKXcQ=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZDHGL+UMLP8XKXzDPS2PU7T/hJqxqVLqkoNrbZtfd
 DNMvqa3cnpHKQuDGBeDrJgiy5xH/m/aOtoiNsQcsoeZw8oEMoSBi1MAJrLIn+F/rt71itWvv1XH
 Lb1fJqjfNrF7QVlGxPLVZ/Yd2n5mN99sO4b/6cFx2Ybimy9xVEwu+pRjHyBvudRUf8NTq8aZhYr
 r2R+zAwDp+0xS
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver currently writes the device's internal RTC at probe with
ktime_get_seconds(), which returns CLOCK_MONOTONIC seconds since boot
and is not a wall-clock value. The resulting timestamps embedded in
blackbox records are therefore meaningless across reboots, defeating
the cross-reboot record-correlation use case the field exists for.

Switching the seed to ktime_get_real_seconds() does not actually fix
this: at probe the system wall clock may not yet have been set (no
external RTC, no userspace NTP), and seeding unconditionally also
clobbers whatever valid time the ADM1266 retained across a warm
reboot.

The data sheet (Rev. D, p. 22) recommends "frequently send the time
stamp to the ADM1266 to synchronize the UNIX time and reduce the time
from drifting" when running on the internal oscillator. The clean way
to expose that policy is an rtc_class device backed by SET_RTC, so
that userspace tooling (hwclock, chrony, systemd-timesyncd) can drive
the re-sync against /dev/rtcN once it trusts the system clock - with
no driver-specific sysfs ABI.

Drop the probe-time seed and adm1266_set_rtc() entirely. Add an
rtc_class device whose ->read_time and ->set_time callbacks read and
write the SET_RTC frame. The rtc_class API is second-precision, so
the SET_RTC fractional-seconds bytes are always written as zero.

Fixes: 15609d189302 ("hwmon: (pmbus/adm1266) read blackbox")
Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/hwmon/pmbus/adm1266.c | 70 ++++++++++++++++++++++++++++++++++++-------
 1 file changed, 60 insertions(+), 10 deletions(-)

diff --git a/drivers/hwmon/pmbus/adm1266.c b/drivers/hwmon/pmbus/adm1266.c
index 99e92a8365fb..0dfb02db8683 100644
--- a/drivers/hwmon/pmbus/adm1266.c
+++ b/drivers/hwmon/pmbus/adm1266.c
@@ -18,8 +18,8 @@
 #include <linux/nvmem-consumer.h>
 #include <linux/nvmem-provider.h>
 #include "pmbus.h"
+#include <linux/rtc.h>
 #include <linux/slab.h>
-#include <linux/timekeeping.h>
 
 #define ADM1266_IC_DEVICE_REV	0xAE
 #define ADM1266_BLACKBOX_CONFIG	0xD3
@@ -513,21 +513,71 @@ static int adm1266_config_nvmem(struct adm1266_data *data)
 	return 0;
 }
 
-static int adm1266_set_rtc(struct adm1266_data *data)
+/*
+ * SET_RTC frame layout (datasheet Rev. D, Table 84):
+ *   bytes [1:0] = fractional seconds, LSB = 1/65536 s
+ *   bytes [5:2] = seconds since 1970-01-01 UTC
+ * The rtc_class API is second-precision, so the fractional bytes are
+ * always written as zero.
+ */
+static int adm1266_write_rtc(struct i2c_client *client, time64_t secs)
 {
-	time64_t kt;
-	char write_buf[6];
+	u8 buf[6] = { 0 };
 	int i;
 
-	kt = ktime_get_seconds();
+	for (i = 0; i < 4; i++)
+		buf[2 + i] = (secs >> (i * 8)) & 0xFF;
+
+	return i2c_smbus_write_block_data(client, ADM1266_SET_RTC, sizeof(buf), buf);
+}
+
+static int adm1266_rtc_read_time(struct device *dev, struct rtc_time *tm)
+{
+	struct i2c_client *client = to_i2c_client(dev);
+	u8 buf[I2C_SMBUS_BLOCK_MAX];
+	u32 secs;
+	int ret;
+	int i;
 
-	memset(write_buf, 0, sizeof(write_buf));
+	ret = i2c_smbus_read_block_data(client, ADM1266_SET_RTC, buf);
+	if (ret < 0)
+		return ret;
+	if (ret != 6)
+		return -EIO;
 
+	secs = 0;
 	for (i = 0; i < 4; i++)
-		write_buf[2 + i] = (kt >> (i * 8)) & 0xFF;
+		secs |= (u32)buf[2 + i] << (i * 8);
+
+	rtc_time64_to_tm(secs, tm);
+	return 0;
+}
+
+static int adm1266_rtc_set_time(struct device *dev, struct rtc_time *tm)
+{
+	struct i2c_client *client = to_i2c_client(dev);
+
+	return adm1266_write_rtc(client, rtc_tm_to_time64(tm));
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
 
-	return i2c_smbus_write_block_data(data->client, ADM1266_SET_RTC, sizeof(write_buf),
-					  write_buf);
+	return devm_rtc_register_device(rtc);
 }
 
 static int adm1266_probe(struct i2c_client *client)
@@ -553,7 +603,7 @@ static int adm1266_probe(struct i2c_client *client)
 	if (ret < 0)
 		return ret;
 
-	ret = adm1266_set_rtc(data);
+	ret = adm1266_register_rtc(data);
 	if (ret < 0)
 		return ret;
 

-- 
2.53.0

