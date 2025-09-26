From: Frank Li <Frank.Li@nxp.com>
Date: Fri, 26 Sep 2025 14:19:41 -0400
Subject: [PATCH v4 2/4] usb: dwc3: Add software-managed properties for
 flattened model
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250926-ls_dma_coherence-v4-2-21e9c6bdb5cb@nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758910787; l=4644;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=foY7RCWiRMtd/hyGD7tQIhJ37+tlwQcoJoyShx+cdpA=;
 b=4ZuMRKtOLSVANqLsRHaHl5UTKt5HhOR82FNIgvuL5TsDXCivTvcTVaosT3LQWN/QzeqFtGn2Z
 1NsApUMpANKDwXAA7gQTvPhma8qDt9cXw6IngPPw0AlSVIfE/wlPCYG
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add software-managed properties for the flattened model, which does not
need to use device tree properties to pass down information to the
common DWC3 core.

Add 'properties' in dwc3_probe_data and set default values for existing
users (dwc3-qcom, dwc3-generic-plat).

No functional changes.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
change in v4
- new patch
---
 drivers/usb/dwc3/core.c              | 12 ++++++++++--
 drivers/usb/dwc3/dwc3-generic-plat.c |  1 +
 drivers/usb/dwc3/dwc3-qcom.c         |  1 +
 drivers/usb/dwc3/glue.h              | 14 ++++++++++++++
 4 files changed, 26 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index 805cd22f42e0961252b0371da9b16cc804e49342..35f9c566358886c106d360dea84f2e6f1ac19688 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -1668,7 +1668,8 @@ static void dwc3_core_exit_mode(struct dwc3 *dwc)
 	dwc3_set_prtcap(dwc, DWC3_GCTL_PRTCAP_DEVICE, true);
 }
 
-static void dwc3_get_software_properties(struct dwc3 *dwc)
+static void dwc3_get_software_properties(struct dwc3 *dwc,
+					 const struct dwc3_properties *properties)
 {
 	struct device *tmpdev;
 	u16 gsbuscfg0_reqinfo;
@@ -1676,6 +1677,12 @@ static void dwc3_get_software_properties(struct dwc3 *dwc)
 
 	dwc->gsbuscfg0_reqinfo = DWC3_GSBUSCFG0_REQINFO_UNSPECIFIED;
 
+	if (properties->gsbuscfg0_reqinfo !=
+	    DWC3_GSBUSCFG0_REQINFO_UNSPECIFIED) {
+		dwc->gsbuscfg0_reqinfo = properties->gsbuscfg0_reqinfo;
+		return;
+	}
+
 	/*
 	 * Iterate over all parent nodes for finding swnode properties
 	 * and non-DT (non-ABI) properties.
@@ -2208,7 +2215,7 @@ int dwc3_core_probe(const struct dwc3_probe_data *data)
 
 	dwc3_get_properties(dwc);
 
-	dwc3_get_software_properties(dwc);
+	dwc3_get_software_properties(dwc, &data->properties);
 
 	dwc->usb_psy = dwc3_get_usb_power_supply(dwc);
 	if (IS_ERR(dwc->usb_psy))
@@ -2358,6 +2365,7 @@ static int dwc3_probe(struct platform_device *pdev)
 
 	probe_data.dwc = dwc;
 	probe_data.res = res;
+	probe_data.properties = DWC3_DEFAULT_PROPERTIES;
 
 	return dwc3_core_probe(&probe_data);
 }
diff --git a/drivers/usb/dwc3/dwc3-generic-plat.c b/drivers/usb/dwc3/dwc3-generic-plat.c
index d96b20570002dc619ea813f4d6a8013636a0f346..af95a527dcc27a7a14d38dcc887f74a888ed91e6 100644
--- a/drivers/usb/dwc3/dwc3-generic-plat.c
+++ b/drivers/usb/dwc3/dwc3-generic-plat.c
@@ -75,6 +75,7 @@ static int dwc3_generic_probe(struct platform_device *pdev)
 	probe_data.dwc = &dwc3g->dwc;
 	probe_data.res = res;
 	probe_data.ignore_clocks_and_resets = true;
+	probe_data.properties = DWC3_DEFAULT_PROPERTIES;
 	ret = dwc3_core_probe(&probe_data);
 	if (ret)
 		return dev_err_probe(dev, ret, "failed to register DWC3 Core\n");
diff --git a/drivers/usb/dwc3/dwc3-qcom.c b/drivers/usb/dwc3/dwc3-qcom.c
index ded2ca86670c0bd7ceadd3cba3fa5ecf9e7e02b5..9ac75547820d978b4a32e570e5f59a2807be68a2 100644
--- a/drivers/usb/dwc3/dwc3-qcom.c
+++ b/drivers/usb/dwc3/dwc3-qcom.c
@@ -704,6 +704,7 @@ static int dwc3_qcom_probe(struct platform_device *pdev)
 	probe_data.dwc = &qcom->dwc;
 	probe_data.res = &res;
 	probe_data.ignore_clocks_and_resets = true;
+	probe_data.properties = DWC3_DEFAULT_PROPERTIES;
 	ret = dwc3_core_probe(&probe_data);
 	if (ret)  {
 		ret = dev_err_probe(dev, ret, "failed to register DWC3 Core\n");
diff --git a/drivers/usb/dwc3/glue.h b/drivers/usb/dwc3/glue.h
index 2efd00e763be4fc51911f32d43054059e61fb43a..300260e11adecb0e5b581bfe2b61c2c6928e874f 100644
--- a/drivers/usb/dwc3/glue.h
+++ b/drivers/usb/dwc3/glue.h
@@ -9,17 +9,31 @@
 #include <linux/types.h>
 #include "core.h"
 
+/**
+ * dwc3_properties: DWC3 core properties
+ * @gsbuscfg0_reqinfo: Value to be programmed in the GSBUSCFG0.REQINFO field
+ */
+struct dwc3_properties {
+	u32 gsbuscfg0_reqinfo;
+};
+
+#define DWC3_DEFAULT_PROPERTIES ((struct dwc3_properties){		\
+	.gsbuscfg0_reqinfo = DWC3_GSBUSCFG0_REQINFO_UNSPECIFIED,	\
+	})
+
 /**
  * dwc3_probe_data: Initialization parameters passed to dwc3_core_probe()
  * @dwc: Reference to dwc3 context structure
  * @res: resource for the DWC3 core mmio region
  * @ignore_clocks_and_resets: clocks and resets defined for the device should
  *		be ignored by the DWC3 core, as they are managed by the glue
+ * @properties: dwc3 software manage propertyies
  */
 struct dwc3_probe_data {
 	struct dwc3 *dwc;
 	struct resource *res;
 	bool ignore_clocks_and_resets;
+	struct dwc3_properties properties;
 };
 
 int dwc3_core_probe(const struct dwc3_probe_data *data);

-- 
2.34.1

