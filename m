From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Fri, 08 May 2026 16:33:13 -0700
Subject: [PATCH 1/7] hwmon: (pmbus/adm1266) use wall-clock seconds for
 SET_RTC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-adm1266-v1-1-ec08bf29e0ce@nexthop.ai>
References: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
In-Reply-To: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
To: Guenter Roeck <linux@roeck-us.net>, 
 Alexandru Tachici <alexandru.tachici@analog.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1535;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=ilxPiiB4ccinJ7vJjFyIeKd85ogX/E6EI9hbrqCCbB4=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZP4rOnyAdcas3bP+hx03nBD3QepsOosI999zO3wkl
 728phiwesvajlIWBjEuBlkxRZY5j/zftHW0RWyIOWQPM4eVCWQIAxenAEzkdAQjQ4vja+cQ87/y
 15yOGaqz/r9pWCoiP1N/5keWuW4eZ8PtrBgZdrRytZpE5vLOeyiRsUHL5/6MewknN6g1vjN8uZn
 7qME2NgCWJU2l
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADM1266 RTC seeds the timestamp embedded in every blackbox record.
The driver currently sets it from ktime_get_seconds(), which returns
CLOCK_MONOTONIC seconds (i.e. seconds since boot). The intent of the
register, per the data sheet (Rev. D, "Setting UNIX Time Using
SET_RTC"), is the elapsed time since 1970-01-01 UTC.

As a result, blackbox records are stamped with "seconds since this
boot," making cross-reboot correlation against host syslog impossible
and making the timestamps in two records taken on different boots
non-comparable.

Switch to ktime_get_real_seconds() so the device is seeded with
wall-clock time, as the data sheet specifies. The internal RTC will
drift from this seed (the data sheet recommends periodic re-sync from
the host); a follow-up patch exposes the device via rtc_class so
standard userspace time-sync tooling can keep it aligned.

Fixes: 15609d189302 ("hwmon: (pmbus/adm1266) read blackbox")
Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/hwmon/pmbus/adm1266.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/hwmon/pmbus/adm1266.c b/drivers/hwmon/pmbus/adm1266.c
index d90f8f80be8e..a86666c73a5e 100644
--- a/drivers/hwmon/pmbus/adm1266.c
+++ b/drivers/hwmon/pmbus/adm1266.c
@@ -432,7 +432,7 @@ static int adm1266_set_rtc(struct adm1266_data *data)
 	char write_buf[6];
 	int i;
 
-	kt = ktime_get_seconds();
+	kt = ktime_get_real_seconds();
 
 	memset(write_buf, 0, sizeof(write_buf));
 

-- 
2.53.0

