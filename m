From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 17 Feb 2024 12:40:34 +0800
Subject: [PATCH 1/2] watchdog: sp805_wdt: deassert the reset if available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240217-hisi-wdt-v1-1-cdb9ddcab968@outlook.com>
References: <20240217-hisi-wdt-v1-0-cdb9ddcab968@outlook.com>
In-Reply-To: <20240217-hisi-wdt-v1-0-cdb9ddcab968@outlook.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Viresh Kumar <vireshk@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708144834; l=1680;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=Ni3PL21dVfacX58NyroZjoZbD5lmIJt2JGNnhuDX6xI=;
 b=qRRi4UH/YpnnK9zlhgdhzMq/aSkKISAB1wZOe9Q17jU37YPbo38JY3Un26vNgzqCE5uiWTDF+
 G80t5j/g/XSB7BOUhWmO7yYDvRHKf6erMqOReBZaT0lHNN9B18LzbWB
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the datasheet, the core has an WDOGRESn input signal that
needs to be deasserted before being operational. Implement it in the
driver.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/watchdog/sp805_wdt.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/watchdog/sp805_wdt.c b/drivers/watchdog/sp805_wdt.c
index 2756ed54ca3d..b4bcfdeb39e6 100644
--- a/drivers/watchdog/sp805_wdt.c
+++ b/drivers/watchdog/sp805_wdt.c
@@ -25,6 +25,7 @@
 #include <linux/moduleparam.h>
 #include <linux/pm.h>
 #include <linux/property.h>
+#include <linux/reset.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
 #include <linux/types.h>
@@ -59,6 +60,7 @@
  * @lock: spin lock protecting dev structure and io access
  * @base: base address of wdt
  * @clk: (optional) clock structure of wdt
+ * @rst: (optional) reset control signal of wdt
  * @rate: (optional) clock rate when provided via properties
  * @adev: amba device structure of wdt
  * @status: current status of wdt
@@ -69,6 +71,7 @@ struct sp805_wdt {
 	spinlock_t			lock;
 	void __iomem			*base;
 	struct clk			*clk;
+	struct reset_control		*rst;
 	u64				rate;
 	struct amba_device		*adev;
 	unsigned int			load_val;
@@ -264,6 +267,12 @@ sp805_wdt_probe(struct amba_device *adev, const struct amba_id *id)
 		return -ENODEV;
 	}
 
+	wdt->rst = devm_reset_control_get_optional(&adev->dev, NULL);
+	if (IS_ERR(wdt->rst))
+		return dev_err_probe(&adev->dev, PTR_ERR(wdt->rst), "Can not get reset\n");
+
+	reset_control_deassert(wdt->rst);
+
 	wdt->adev = adev;
 	wdt->wdd.info = &wdt_info;
 	wdt->wdd.ops = &wdt_ops;

-- 
2.43.0

