From: Frank Li <Frank.Li@nxp.com>
Date: Fri, 26 Sep 2025 14:19:42 -0400
Subject: [PATCH v4 3/4] usb: dwc3: dwc3-generic-plat: Add layerscape dwc3
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250926-ls_dma_coherence-v4-3-21e9c6bdb5cb@nxp.com>
References: <20250926-ls_dma_coherence-v4-0-21e9c6bdb5cb@nxp.com>
In-Reply-To: <20250926-ls_dma_coherence-v4-0-21e9c6bdb5cb@nxp.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, Shawn Guo <shawnguo@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 bjorn.andersson@oss.qualcomm.com, imx@lists.linux.dev, 
 Frank Li <Frank.Li@nxp.com>, Ze Huang <huang.ze@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758910787; l=2222;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=x/YV7GviRuKrxoFTMOltiDCmXq8scFHKV8v3SyDackg=;
 b=zZv6x5+g8lfoX1KRaaggYbBkew2o/+XvY0hrd96Jjw8UPPJxQY0NRQWt4cPlSUCLsW32ifK71
 nSDr3kZJ75IA3vYcn4qGZcMwlwp0IBo4XbvweePGgD892OhcCvN/iaI
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add layerscape dwc3 support by using flatten dwc3 core library. Layerscape
dwc3 need set gsbuscfg0-reqinfo as 0x2222 when dma-coherence set.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
chagne in v4
- rename gsbuscfg0 to gsbuscfg0_reqinfo
- use flatten core's properties.

change in v3 (skipped)
---
 drivers/usb/dwc3/dwc3-generic-plat.c | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/dwc3/dwc3-generic-plat.c b/drivers/usb/dwc3/dwc3-generic-plat.c
index af95a527dcc27a7a14d38dcc887f74a888ed91e6..cfcefeffd7ad6c0a21ccc9aaa4483b9acb9dc4e0 100644
--- a/drivers/usb/dwc3/dwc3-generic-plat.c
+++ b/drivers/usb/dwc3/dwc3-generic-plat.c
@@ -8,6 +8,7 @@
  */
 
 #include <linux/clk.h>
+#include <linux/of_address.h>
 #include <linux/platform_device.h>
 #include <linux/reset.h>
 #include "glue.h"
@@ -29,6 +30,7 @@ static void dwc3_generic_reset_control_assert(void *data)
 
 static int dwc3_generic_probe(struct platform_device *pdev)
 {
+	const struct dwc3_properties *properties;
 	struct dwc3_probe_data probe_data = {};
 	struct device *dev = &pdev->dev;
 	struct dwc3_generic *dwc3g;
@@ -75,7 +77,13 @@ static int dwc3_generic_probe(struct platform_device *pdev)
 	probe_data.dwc = &dwc3g->dwc;
 	probe_data.res = res;
 	probe_data.ignore_clocks_and_resets = true;
-	probe_data.properties = DWC3_DEFAULT_PROPERTIES;
+
+	properties = of_device_get_match_data(dev);
+	if (of_dma_is_coherent(pdev->dev.of_node) && properties)
+		probe_data.properties = *properties;
+	else
+		probe_data.properties = DWC3_DEFAULT_PROPERTIES;
+
 	ret = dwc3_core_probe(&probe_data);
 	if (ret)
 		return dev_err_probe(dev, ret, "failed to register DWC3 Core\n");
@@ -146,8 +154,13 @@ static const struct dev_pm_ops dwc3_generic_dev_pm_ops = {
 		       dwc3_generic_runtime_idle)
 };
 
+static const struct dwc3_properties fsl_ls1028_dwc3 = {
+	.gsbuscfg0_reqinfo = 0x2222,
+};
+
 static const struct of_device_id dwc3_generic_of_match[] = {
 	{ .compatible = "spacemit,k1-dwc3", },
+	{ .compatible = "fsl,ls1028a-dwc3", &fsl_ls1028_dwc3},
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, dwc3_generic_of_match);

-- 
2.34.1

