From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Mon, 30 Sep 2024 10:57:40 +0200
Subject: [PATCH] rtc: Makefile: Replace spaces with tab.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240930-rtc-makefile-spaces-v1-1-e936e0a7b02a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAANo+mYC/x2MSwqDQBAFryK9TsM4Bn9XCS6a8amNX6ZFAuLdM
 2RZFFU3GaLCqM1uirjUdN8S5K+MwiTbCNY+MXnn364pHMcz8CozBl3AdkiAsS+Rl1JBirqiVB4
 x6e//+ume5wfBo0OTZQAAAA==
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: linux-rtc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727686660; l=913;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=DO0jltegohA+gSXye9IARyoHoswXbGhgo3i6eJ4aPs0=;
 b=KsjtGzLRud2lZZRAj3zioqjjGCyJo+4/bzT3bbaLEOXLKcM9aYyqNbGfBnKRAXmsoU2/g2uHX
 b/y1EG6oNEoA31ZPgW6l15miaDYLqK1FVwJSEW4A84d21Q7Rvj/+io0
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a style error.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
 drivers/rtc/Makefile | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/rtc/Makefile b/drivers/rtc/Makefile
index f62340ecc534..3deacb1ee71f 100644
--- a/drivers/rtc/Makefile
+++ b/drivers/rtc/Makefile
@@ -164,7 +164,7 @@ obj-$(CONFIG_RTC_DRV_S5M)	+= rtc-s5m.o
 obj-$(CONFIG_RTC_DRV_SA1100)	+= rtc-sa1100.o
 obj-$(CONFIG_RTC_DRV_SC27XX)	+= rtc-sc27xx.o
 obj-$(CONFIG_RTC_DRV_SD2405AL)	+= rtc-sd2405al.o
-obj-$(CONFIG_RTC_DRV_SD3078)   += rtc-sd3078.o
+obj-$(CONFIG_RTC_DRV_SD3078)	+= rtc-sd3078.o
 obj-$(CONFIG_RTC_DRV_SH)	+= rtc-sh.o
 obj-$(CONFIG_RTC_DRV_SNVS)	+= rtc-snvs.o
 obj-$(CONFIG_RTC_DRV_SPEAR)	+= rtc-spear.o

---
base-commit: 9852d85ec9d492ebef56dc5f229416c925758edc
change-id: 20240930-rtc-makefile-spaces-26e16a7ea387

Best regards,
-- 
Tóth János <gomba007@gmail.com>

