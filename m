From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 11 Jun 2025 17:26:12 +0100
Subject: [PATCH 1/2] hwmon: ltc4282: avoid repeated register write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250611-fix-ltc4282-repetead-write-v1-1-fe46edd08cf1@analog.com>
References: <20250611-fix-ltc4282-repetead-write-v1-0-fe46edd08cf1@analog.com>
In-Reply-To: <20250611-fix-ltc4282-repetead-write-v1-0-fe46edd08cf1@analog.com>
To: linux-hwmon@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749659172; l=1018;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=BLNIO1ilzbGQmaH4UUriCna8h5c9+a/6ajPl5KE0E58=;
 b=5rthojdXxUsrIK9oo+gos74eZGG/e+X4rE5scXJYPUOKwpEp1op7eoxu5CJt0zv3vKDu0+May
 JipsatGCUCJBgFeqP7k/1yvQUKWq5AFlg+c9wZrLHVkpeMZJNuDZLib
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fault enabled bits were being mistankenly enabled twice in case the FW
property is present. Remove one of the writes.

Fixes: cbc29538dbf7 ("hwmon: Add driver for LTC4282")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/hwmon/ltc4282.c | 7 -------
 1 file changed, 7 deletions(-)

diff --git a/drivers/hwmon/ltc4282.c b/drivers/hwmon/ltc4282.c
index 7f38d269623965c22424dea837ff451bb880f81e..f607fe8f793702da534902d3c3878581ac2bca1f 100644
--- a/drivers/hwmon/ltc4282.c
+++ b/drivers/hwmon/ltc4282.c
@@ -1511,13 +1511,6 @@ static int ltc4282_setup(struct ltc4282_state *st, struct device *dev)
 			return ret;
 	}
 
-	if (device_property_read_bool(dev, "adi,fault-log-enable")) {
-		ret = regmap_set_bits(st->map, LTC4282_ADC_CTRL,
-				      LTC4282_FAULT_LOG_EN_MASK);
-		if (ret)
-			return ret;
-	}
-
 	if (device_property_read_bool(dev, "adi,fault-log-enable")) {
 		ret = regmap_set_bits(st->map, LTC4282_ADC_CTRL, LTC4282_FAULT_LOG_EN_MASK);
 		if (ret)

-- 
2.49.0

