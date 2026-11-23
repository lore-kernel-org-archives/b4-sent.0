From: Shigeaki Asai <y-asai.0816@docomonet.jp>
Date: Mon, 23 Nov 2026 23:18:24 +0900
Subject: [PATCH RFC 2/2] clk: samsung: exynos5-subcmu: defer probe until
 power domains are registered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-exynos5-subcmu-defer-v1-2-43aef47d4f2b@docomonet.jp>
References: <20261123-exynos5-subcmu-defer-v1-0-43aef47d4f2b@docomonet.jp>
In-Reply-To: <20261123-exynos5-subcmu-defer-v1-0-43aef47d4f2b@docomonet.jp>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Marek Szyprowski <m.szyprowski@samsung.com>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Shigeaki Asai <y-asai.0816@docomonet.jp>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795443504; l=4200;
 i=y-asai.0816@docomonet.jp; s=20261004; h=from:subject:message-id;
 bh=06wGL2OqoYzK5WTk4tX/mGxzOuQQyJdcsjmAmiOi95k=;
 b=De7pQ0KDp06OwJJM4PZolf4jW8UVsKntB1DYNyexEkHDE6wWOnybAAzOtp6kMInVJ5bwNGIUs
 uPLGYaZQuhkB93P9XKCNnR5yJc3UQrHyJ+xAi+e+Ter2V3Sv/eeDWUo
X-Developer-Key: i=y-asai.0816@docomonet.jp; a=ed25519;
 pk=jkd95ViSn8i/X3oPMHYG1A8mae8IOwOKGE64kzLqC5c=
X-Endpoint-Received: by B4 Relay for y-asai.0816@docomonet.jp/20261004 with auth_id=1110
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the Exynos power domain driver became a regular platform driver,
exynos5_clk_probe() may run before the power domains are registered.
The sub-CMU devices are created by the clock driver without a DT node,
so fw_devlink cannot order them after their power domains.
of_genpd_add_device() then fails silently, the sub-CMU devices are added
without a power domain and their clock setup is not restored across
power domain off/on cycles. On ODROID-XU4 this leaves the G3D clocks
misconfigured, causing very poor GPU performance and panfrost
"gpu sched timeout" errors.

Attach all sub-CMU devices to their power domains first, and defer the
probe if a power domain provider is not registered yet.

This patch was written with the help of Claude (claude-opus-5-5).

Fixes: c09a3e6c97f0 ("soc: samsung: pm_domains: Convert to regular platform driver")
Signed-off-by: Shigeaki Asai <y-asai.0816@docomonet.jp>
---
 drivers/clk/samsung/clk-exynos5-subcmu.c | 85 ++++++++++++++++++++++----------
 1 file changed, 58 insertions(+), 27 deletions(-)

diff --git a/drivers/clk/samsung/clk-exynos5-subcmu.c b/drivers/clk/samsung/clk-exynos5-subcmu.c
index 373129847301..797ec9f059cb 100644
--- a/drivers/clk/samsung/clk-exynos5-subcmu.c
+++ b/drivers/clk/samsung/clk-exynos5-subcmu.c
@@ -9,6 +9,7 @@
 #include <linux/platform_device.h>
 #include <linux/pm_domain.h>
 #include <linux/pm_runtime.h>
+#include <linux/slab.h>
 
 #include "clk.h"
 #include "clk-exynos5-subcmu.h"
@@ -131,43 +132,73 @@ static struct platform_driver exynos5_subcmu_driver __refdata = {
 	.probe = exynos5_subcmu_probe,
 };
 
-static int __init exynos5_clk_register_subcmu(struct device *parent,
-					 const struct exynos5_subcmu_info *info,
-					      struct device_node *pd_node)
-{
-	struct of_phandle_args genpdspec = { .np = pd_node };
-	struct platform_device *pdev;
-	int ret;
-
-	pdev = platform_device_alloc("exynos5-subcmu", PLATFORM_DEVID_AUTO);
-	if (!pdev)
-		return -ENOMEM;
-
-	pdev->dev.parent = parent;
-	platform_set_drvdata(pdev, (void *)info);
-	of_genpd_add_device(&genpdspec, &pdev->dev);
-	ret = platform_device_add(pdev);
-	if (ret)
-		platform_device_put(pdev);
-
-	return ret;
-}
-
 static int __init exynos5_clk_probe(struct platform_device *pdev)
 {
+	struct platform_device **subcmus;
 	struct device_node *np;
 	const char *name;
-	int i;
+	int i, n = 0, ret;
+
+	subcmus = kcalloc(nr_cmus, sizeof(*subcmus), GFP_KERNEL);
+	if (!subcmus)
+		return -ENOMEM;
 
 	for_each_compatible_node(np, NULL, "samsung,exynos4210-pd") {
+		struct of_phandle_args genpdspec = { .np = np };
+
 		if (of_property_read_string(np, "label", &name) < 0)
 			continue;
-		for (i = 0; i < nr_cmus; i++)
-			if (strcmp(cmu[i]->pd_name, name) == 0)
-				exynos5_clk_register_subcmu(&pdev->dev,
-							    cmu[i], np);
+		for (i = 0; i < nr_cmus && n < nr_cmus; i++) {
+			struct platform_device *sub;
+
+			if (strcmp(cmu[i]->pd_name, name) != 0)
+				continue;
+
+			sub = platform_device_alloc("exynos5-subcmu",
+						    PLATFORM_DEVID_AUTO);
+			if (!sub) {
+				of_node_put(np);
+				ret = -ENOMEM;
+				goto err;
+			}
+			sub->dev.parent = &pdev->dev;
+			platform_set_drvdata(sub, (void *)cmu[i]);
+
+			ret = of_genpd_add_device(&genpdspec, &sub->dev);
+			if (ret == -ENOENT || ret == -EPROBE_DEFER) {
+				platform_device_put(sub);
+				of_node_put(np);
+				ret = dev_err_probe(&pdev->dev, -EPROBE_DEFER,
+						    "power domain %s not ready\n",
+						    name);
+				goto err;
+			} else if (ret) {
+				dev_warn(&pdev->dev,
+					 "failed to add %s sub-CMU to its power domain: %d\n",
+					 name, ret);
+			}
+			subcmus[n++] = sub;
+		}
+	}
+
+	for (i = 0; i < n; i++) {
+		ret = platform_device_add(subcmus[i]);
+		if (ret) {
+			pm_genpd_remove_device(&subcmus[i]->dev);
+			platform_device_put(subcmus[i]);
+		}
 	}
+
+	kfree(subcmus);
 	return 0;
+
+err:
+	while (n--) {
+		pm_genpd_remove_device(&subcmus[n]->dev);
+		platform_device_put(subcmus[n]);
+	}
+	kfree(subcmus);
+	return ret;
 }
 
 static const struct of_device_id exynos5_clk_of_match[] = {

-- 
2.43.0

