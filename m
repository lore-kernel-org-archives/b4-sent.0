From: Alessandro Di Chiara <alessandro.dichiara@se.com>
Date: Wed, 10 Dec 2025 21:19:59 +0100
Subject: [PATCH] rtc: pcf2127: clear the PWRMNG bits for pcf2131
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251210-rtc-pcf2131-clear-pwrmng-bits-v1-1-407c1c573726@se.com>
X-B4-Tracking: v=1; b=H4sIAO7VOWkC/x2O2wrCMBAFf6Xk2YVckIK/IlI266YJ2DRsUhVK/
 93Ux4E5w9lVZUlc1W3YlfA71bTmDuYyKIqYZ4b07KystldjjQZpBIWCNc4AvRgFykeWPINPrYL
 V5ByGcbSGVG94rAxeMFM8K308FWwUp7ZOW6lNGJfTK8Ihff8/7o/j+AHD5V3blwAAAA==
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: linux-rtc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alessandro Di Chiara <alessandro.dichiara@se.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765398011; l=1668;
 i=alessandro.dichiara@se.com; s=20251210; h=from:subject:message-id;
 bh=sdtnNaboWuo63u4CZWW9IBzWMWcDmWRWx8WFWRzaWEg=;
 b=UDvSzXBS9AYvzB8XJPf1w/I9KpG8bg18/NZGwLqttQMaro2jyNx7ktq912m1XquugeWfnAvj3
 VpeB9v36MVrBUi2JqDPwP6Ku2aosnlwExRGoVOBpiDGQaIiGi88xrob
X-Developer-Key: i=alessandro.dichiara@se.com; a=ed25519;
 pk=u2B6IoaKeBzT34cbldBoNPmpikSV4O5zEn0xUxy5vlM=
X-Endpoint-Received: by B4 Relay for alessandro.dichiara@se.com/20251210 with auth_id=575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pcf2131 does not retain the date by default. This is because the
reset value of the PWRMNG bits is 111, which is different from the
pcf2127/pcf2129, whose reset value is 000.

To keep consistency with the other rtc handled by the driver,
clear the PWRMNG bits for pcf2131 to enable:
	- Battery switch-over function in standard mode.
	- Battery low detection function.

Signed-off-by: Alessandro Di Chiara <alessandro.dichiara@se.com>
---
Hi,

this patch enables battery switch-over and low detection functions for
the rtc pcf2131.

Tested only with pcf2131.
---
 drivers/rtc/rtc-pcf2127.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/rtc/rtc-pcf2127.c b/drivers/rtc/rtc-pcf2127.c
index bb4fe81d3d62..c6ea679645f2 100644
--- a/drivers/rtc/rtc-pcf2127.c
+++ b/drivers/rtc/rtc-pcf2127.c
@@ -1329,8 +1329,11 @@ static int pcf2127_probe(struct device *dev, struct regmap *regmap,
 	 * Clear battery interrupt flags which can block new trigger events.
 	 * Note: This is the default chip behaviour but added to ensure
 	 * correct tamper timestamp and interrupt function.
+	 * For pcf2131, clear the PWRMNG bits[7:5] because the reset value
+	 * is 111, which is different from 2127/2129.
 	 */
 	ret = regmap_update_bits(pcf2127->regmap, PCF2127_REG_CTRL3,
+				 (pcf2127->cfg->type == PCF2131 ? PCF2127_CTRL3_PM : 0) |
 				 PCF2127_BIT_CTRL3_BTSE |
 				 PCF2127_BIT_CTRL3_BIE |
 				 PCF2127_BIT_CTRL3_BLIE, 0);

---
base-commit: 7d0a66e4bb9081d75c82ec4957c50034cb0ea449
change-id: 20251210-rtc-pcf2131-clear-pwrmng-bits-20c33af7721c

Best regards,
-- 
Alessandro Di Chiara <alessandro.dichiara@se.com>

