From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 11 Jun 2025 17:26:13 +0100
Subject: [PATCH 2/2] hwmon: ltc4282: fix copy past on variable name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250611-fix-ltc4282-repetead-write-v1-2-fe46edd08cf1@analog.com>
References: <20250611-fix-ltc4282-repetead-write-v1-0-fe46edd08cf1@analog.com>
In-Reply-To: <20250611-fix-ltc4282-repetead-write-v1-0-fe46edd08cf1@analog.com>
To: linux-hwmon@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749659172; l=1114;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Axt5mflHjtEQ8Pvm+CtnA/aSKL3YMFtBVCFhqgZVWgs=;
 b=5SHjr1sAltP5PP3H5TJQJ69QApXVI0zFIDP66iZcN8Df3c5+rU80FxNTluFj8+yP2X7fmPO7l
 vTWT1Z6Zm6ZBAW5UX7oVVDc8DyRqnifihdGBTrHUgdrsyovmqWNuVUJ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The struct hwmon_chip_info was named ltc2947_chip_info which is
obviously a copy paste leftover. Name it accordingly.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/hwmon/ltc4282.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/hwmon/ltc4282.c b/drivers/hwmon/ltc4282.c
index f607fe8f793702da534902d3c3878581ac2bca1f..424fa9e3a0993f74d7bd1b2e3c98acd954217a98 100644
--- a/drivers/hwmon/ltc4282.c
+++ b/drivers/hwmon/ltc4282.c
@@ -1596,7 +1596,7 @@ static const struct hwmon_ops ltc4282_hwmon_ops = {
 	.read_string = ltc4282_read_labels,
 };
 
-static const struct hwmon_chip_info ltc2947_chip_info = {
+static const struct hwmon_chip_info ltc4282_chip_info = {
 	.ops = &ltc4282_hwmon_ops,
 	.info = ltc4282_info,
 };
@@ -1717,7 +1717,7 @@ static int ltc4282_probe(struct i2c_client *i2c)
 
 	mutex_init(&st->lock);
 	hwmon = devm_hwmon_device_register_with_info(dev, "ltc4282", st,
-						     &ltc2947_chip_info,
+						     &ltc4282_chip_info,
 						     ltc4282_groups);
 	if (IS_ERR(hwmon))
 		return PTR_ERR(hwmon);

-- 
2.49.0

