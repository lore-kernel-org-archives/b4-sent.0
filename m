From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 21 Feb 2024 19:56:41 +0800
Subject: [PATCH v3 1/2] watchdog: sp805_wdt: deassert the reset if
 available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-hisi-wdt-v3-1-9642613dc2e6@outlook.com>
References: <20240221-hisi-wdt-v3-0-9642613dc2e6@outlook.com>
In-Reply-To: <20240221-hisi-wdt-v3-0-9642613dc2e6@outlook.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Viresh Kumar <vireshk@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708516604; l=1308;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=Yulf71GztXVGablEgkhT6BHnqYqWblq9L42vUSDAg9k=;
 b=+BBcG1xmGtzehN6g+Xwdx1UJPNgY6Spl76NJKL/19umtdnMNqtXf/NjvXINZy1aot1GKR3UgT
 5vXzcsBnhRuCceep7KHoaoAakAuReSP6/t0rNrqDPmpqBKs3CU+rMjj
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the datasheet, the core has an WDOGRESn input signal that
needs to be deasserted before being operational. Implement it in the
driver.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/watchdog/sp805_wdt.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/watchdog/sp805_wdt.c b/drivers/watchdog/sp805_wdt.c
index 2756ed54ca3d..109e2e37e8f0 100644
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
@@ -232,6 +233,7 @@ static int
 sp805_wdt_probe(struct amba_device *adev, const struct amba_id *id)
 {
 	struct sp805_wdt *wdt;
+	struct reset_control *rst;
 	u64 rate = 0;
 	int ret = 0;
 
@@ -264,6 +266,12 @@ sp805_wdt_probe(struct amba_device *adev, const struct amba_id *id)
 		return -ENODEV;
 	}
 
+	rst = devm_reset_control_get_optional_exclusive(&adev->dev, NULL);
+	if (IS_ERR(rst))
+		return dev_err_probe(&adev->dev, PTR_ERR(rst), "Can not get reset\n");
+
+	reset_control_deassert(rst);
+
 	wdt->adev = adev;
 	wdt->wdd.info = &wdt_info;
 	wdt->wdd.ops = &wdt_ops;

-- 
2.43.0

