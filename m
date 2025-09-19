From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Fri, 19 Sep 2025 16:38:49 +0800
Subject: [PATCH] hwmon: (gpd-fan) Fix range check for pwm input
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250919-hwmon-v1-1-2b69c8b9c062@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAJgWzWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDS0NL3Yzy3Pw8XUtzA+NE45REQ0vTRCWg2oKi1LTMCrA50bG1tQAG7sl
 gVwAAAA==
X-Change-ID: 20250919-hwmon-9703a3da195a
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 niecheng1@uniontech.com, zhanjun@uniontech.com, 
 Chenx Dust <chenx_dust@outlook.com>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758271130; l=1169;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=afIndOhFyRIpJBSDKmekESS308i/EUBmxUVarGxW7lY=;
 b=UU9NK+el/HvToO6JeXG6lF9yDJmp4kowqe6RJJadveUBwOdNADYAxD1khU+xxXv4hM3W4QeOh
 IpqArxawtJUDtaQ3kP05C6UCZf8qYy9M7ViixdgkK9JDo53JpeXoTNU
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixed the maximum value in the PWM input range check, allowing the
input to be set to 255.

Fixes: 0ab88e239439 ("hwmon: add GPD devices sensor driver")
Reported-by: Chenx Dust <chenx_dust@outlook.com>
Link: https://github.com/Cryolitia/gpd-fan-driver/pull/18
Co-developed-by: Chenx Dust <chenx_dust@outlook.com>
Signed-off-by: Chenx Dust <chenx_dust@outlook.com>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 drivers/hwmon/gpd-fan.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/hwmon/gpd-fan.c b/drivers/hwmon/gpd-fan.c
index e0b3b46e1bf12a10097600f857c627a766f61a27..644dc3ca9df7da0174e513c47a820a6ff39eb0ef 100644
--- a/drivers/hwmon/gpd-fan.c
+++ b/drivers/hwmon/gpd-fan.c
@@ -571,7 +571,7 @@ static int gpd_fan_hwmon_write(__always_unused struct device *dev,
 			ret = 0;
 			goto OUT;
 		case hwmon_pwm_input:
-			if (!in_range(val, 0, 255)) {
+			if (!in_range(val, 0, 256)) {
 				ret = -ERANGE;
 				goto OUT;
 			}

---
base-commit: 80038a758b7fc0cdb6987532cbbf3f75b13e0826
change-id: 20250919-hwmon-9703a3da195a

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

