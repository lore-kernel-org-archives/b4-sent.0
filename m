From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Fri, 15 Sep 2023 11:10:56 +0300
Subject: [PATCH v4 14/42] rtc: ep93xx: add DT support for Cirrus EP93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230915-ep93xx-v4-14-a1d779dcec10@maquefel.me>
References: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
In-Reply-To: <20230915-ep93xx-v4-0-a1d779dcec10@maquefel.me>
To: Alessandro Zummo <a.zummo@towertech.it>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: linux-rtc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Andy Shevchenko <andy.shevchenko@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694765525; l=1082;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=p80xCnz+NiYVYSqsKWTadEzof+wILB6tYu5g6z/UQHM=;
 b=5o3Yk09uQHB6rSVNBOSYUARYgtDmO/npd1JvYZ7zPPxiZeant3v1EDCH+4HoeQBCbNXAMgS6Hz8Q
 F4LqkKUrCYmh9RfkZt88PHzOK9mvSjOZO6yKlztjR0F/7RI9tUUM
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add OF ID match table.

Reviewed-by: Andy Shevchenko <andy.shevchenko@gmail.com>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/rtc/rtc-ep93xx.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/rtc/rtc-ep93xx.c b/drivers/rtc/rtc-ep93xx.c
index acae7f16808f..1fdd20d01560 100644
--- a/drivers/rtc/rtc-ep93xx.c
+++ b/drivers/rtc/rtc-ep93xx.c
@@ -7,6 +7,7 @@
  */
 
 #include <linux/module.h>
+#include <linux/mod_devicetable.h>
 #include <linux/rtc.h>
 #include <linux/platform_device.h>
 #include <linux/io.h>
@@ -148,9 +149,16 @@ static int ep93xx_rtc_probe(struct platform_device *pdev)
 	return devm_rtc_register_device(ep93xx_rtc->rtc);
 }
 
+static const struct of_device_id ep93xx_rtc_of_ids[] = {
+	{ .compatible = "cirrus,ep9301-rtc" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, ep93xx_rtc_of_ids);
+
 static struct platform_driver ep93xx_rtc_driver = {
 	.driver		= {
 		.name	= "ep93xx-rtc",
+		.of_match_table = ep93xx_rtc_of_ids,
 	},
 	.probe		= ep93xx_rtc_probe,
 };

-- 
2.39.2

