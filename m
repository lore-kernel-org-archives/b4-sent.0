From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 23 Feb 2024 18:10:20 +0800
Subject: [PATCH v2 2/2] drivers: bus: simple-pm-bus: Get and deassert
 resets exclusively
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240223-b4-bus-v2-2-da8ba83c1a5f@outlook.com>
References: <20240223-b4-bus-v2-0-da8ba83c1a5f@outlook.com>
In-Reply-To: <20240223-b4-bus-v2-0-da8ba83c1a5f@outlook.com>
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708683020; l=2336;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=IavnxoIeWBK3APBnyHNZI/y56/+6lr1F3uzJe1D+hR0=;
 b=MP/vK9i/hsQIRpsFr8imCB448rwViVkMEJMYN2xWPt0Iguka38Nnv3GNOFlLDLlttOq20rWiG
 hBYhuRFxbd1BPzl4xoRlQ8X0jYQE6ZXq9r0vXmfusoz4ngVIahx9XGT
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Simple Power-Managed bus controller may need functional reset(s)
to be deasserted before child devices connected to the bus can be
accessed.  Get the reset(s) as an array and assert/deassert the
reset(s) when the bus is being power managed.

One example is that HiSilicon USB2 INNO PHY test bus needs to deassert
the reset to the bus before accessing its registers.

Reviewed-by: Geert Uytterhoeven <geert+renesas@glider.be>
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/bus/simple-pm-bus.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/drivers/bus/simple-pm-bus.c b/drivers/bus/simple-pm-bus.c
index 50870c827889..f2e98eac0bb4 100644
--- a/drivers/bus/simple-pm-bus.c
+++ b/drivers/bus/simple-pm-bus.c
@@ -16,15 +16,17 @@
 #include <linux/of_platform.h>
 #include <linux/platform_device.h>
 #include <linux/pm_runtime.h>
+#include <linux/reset.h>
 
 struct simple_pm_bus {
 	struct clk_bulk_data *clks;
+	struct reset_control *rsts;
 	int num_clks;
 };
 
 static int simple_pm_bus_probe(struct platform_device *pdev)
 {
-	const struct device *dev = &pdev->dev;
+	struct device *dev = &pdev->dev;
 	const struct of_dev_auxdata *lookup = dev_get_platdata(dev);
 	struct device_node *np = dev->of_node;
 	const struct of_device_id *match;
@@ -62,6 +64,10 @@ static int simple_pm_bus_probe(struct platform_device *pdev)
 	if (bus->num_clks < 0)
 		return dev_err_probe(&pdev->dev, bus->num_clks, "failed to get clocks\n");
 
+	bus->rsts = devm_reset_control_array_get_optional_exclusive(dev);
+	if (IS_ERR(bus->rsts))
+		return dev_err_probe(&pdev->dev, PTR_ERR(bus->rsts), "failed to get resets\n");
+
 	dev_set_drvdata(&pdev->dev, bus);
 
 	dev_dbg(&pdev->dev, "%s\n", __func__);
@@ -92,7 +98,7 @@ static int simple_pm_bus_runtime_suspend(struct device *dev)
 
 	clk_bulk_disable_unprepare(bus->num_clks, bus->clks);
 
-	return 0;
+	return reset_control_assert(bus->rsts);
 }
 
 static int simple_pm_bus_runtime_resume(struct device *dev)
@@ -106,6 +112,12 @@ static int simple_pm_bus_runtime_resume(struct device *dev)
 		return ret;
 	}
 
+	ret = reset_control_deassert(bus->rsts);
+	if (ret) {
+		dev_err(dev, "failed to deassert resets: %d\n", ret);
+		return ret;
+	}
+
 	return 0;
 }
 

-- 
2.43.0

