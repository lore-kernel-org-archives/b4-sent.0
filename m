From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Fri, 08 May 2026 16:33:14 -0700
Subject: [PATCH 2/7] hwmon: (pmbus/adm1266) write fractional-seconds field
 of SET_RTC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-adm1266-v1-2-ec08bf29e0ce@nexthop.ai>
References: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
In-Reply-To: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
To: Guenter Roeck <linux@roeck-us.net>, 
 Alexandru Tachici <alexandru.tachici@analog.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1736;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=zgclZid47CWbHlZWQwfDY1h7EjKE5ZC3dtjfgCW8+38=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZP4rOtK/4lPRG2eD5cw+Kx7tlT0ZuFNWb5tUrzVDQ
 fz3WSuvPjzWUcrCIMbFICumyDLnkf+bto62iA0xh+xh5rAygQxh4OIUgIlwz2T4X2ywM7jk1v/w
 zb8+VMpcm7v27/IH5Ukfylfkz5+bdD8iKJSR4UaSPeOLa194uf5dDz4qyKVk/3XjwqmNCyauWOQ
 66cqCmbwAw5BUjQ==
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SET_RTC register is six bytes wide: bytes [1:0] hold fractional
seconds (LSB = 1/65536 s) and bytes [5:2] hold whole seconds. The
driver was zeroing the fractional bytes, which loses sub-second
resolution when timestamping blackbox records.

Sample wall-clock time as a struct timespec64 and convert tv_nsec to
the device's 16-bit fractional representation. The conversion uses
64-bit arithmetic to avoid overflow on the (nsec << 16) intermediate.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/hwmon/pmbus/adm1266.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/drivers/hwmon/pmbus/adm1266.c b/drivers/hwmon/pmbus/adm1266.c
index a86666c73a5e..ba8a02509528 100644
--- a/drivers/hwmon/pmbus/adm1266.c
+++ b/drivers/hwmon/pmbus/adm1266.c
@@ -428,16 +428,23 @@ static int adm1266_config_nvmem(struct adm1266_data *data)
 
 static int adm1266_set_rtc(struct adm1266_data *data)
 {
-	time64_t kt;
+	struct timespec64 ts;
 	char write_buf[6];
+	u16 frac;
 	int i;
 
-	kt = ktime_get_real_seconds();
-
-	memset(write_buf, 0, sizeof(write_buf));
+	ktime_get_real_ts64(&ts);
 
+	/*
+	 * SET_RTC frame layout (datasheet Rev. D, Table 84):
+	 *   bytes [1:0] = fractional seconds, LSB = 1/65536 s
+	 *   bytes [5:2] = seconds since 1970-01-01 UTC
+	 */
+	frac = (u16)(((u64)ts.tv_nsec << 16) / NSEC_PER_SEC);
+	for (i = 0; i < 2; i++)
+		write_buf[i] = (frac >> (i * 8)) & 0xFF;
 	for (i = 0; i < 4; i++)
-		write_buf[2 + i] = (kt >> (i * 8)) & 0xFF;
+		write_buf[2 + i] = (ts.tv_sec >> (i * 8)) & 0xFF;
 
 	return i2c_smbus_write_block_data(data->client, ADM1266_SET_RTC, sizeof(write_buf),
 					  write_buf);

-- 
2.53.0

