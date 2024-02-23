From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 23 Feb 2024 11:49:47 +0800
Subject: [PATCH 2/2] drivers: bus: simple-pm-bus: Get and deassert resets
 exclusively
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240223-b4-bus-v1-2-2803c3ac4673@outlook.com>
References: <20240223-b4-bus-v1-0-2803c3ac4673@outlook.com>
In-Reply-To: <20240223-b4-bus-v1-0-2803c3ac4673@outlook.com>
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708660187; l=1979;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=JWFA4aEPe9UmKX/cnL2dAlkZhpNjtIvdqZ32qXjuGyM=;
 b=qcHy1AJ2U0hzEwKWQHgC3iK0+xqjk8WbWl2uq7fhr6LqaRXcHt0ct/VyrmF1YNi9UhZRUXtJi
 6PhcXTFCv+eBZKsu7+gUxThU6jlKAvTTFu0oUsKCCNpUvnj66v+mIiW
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

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/bus/simple-pm-bus.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/bus/simple-pm-bus.c b/drivers/bus/simple-pm-bus.c
index 50870c827889..d84dbd61c02b 100644
--- a/drivers/bus/simple-pm-bus.c
+++ b/drivers/bus/simple-pm-bus.c
@@ -16,9 +16,11 @@
 #include <linux/of_platform.h>
 #include <linux/platform_device.h>
 #include <linux/pm_runtime.h>
+#include <linux/reset.h>
 
 struct simple_pm_bus {
 	struct clk_bulk_data *clks;
+	struct reset_control *rsts;
 	int num_clks;
 };
 
@@ -62,6 +64,10 @@ static int simple_pm_bus_probe(struct platform_device *pdev)
 	if (bus->num_clks < 0)
 		return dev_err_probe(&pdev->dev, bus->num_clks, "failed to get clocks\n");
 
+	bus->rsts = devm_reset_control_array_get(dev, false, true);
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

