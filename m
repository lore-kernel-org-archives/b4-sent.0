From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:16:43 +0000
Subject: [PATCH 1/2] usb: dwc3: Tell xhci-plat when the core lost its state
 on resume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-dwc3-s2idle-v1-1-2ef4cc3f8130@gmail.com>
References: <20261110-dwc3-s2idle-v1-0-2ef4cc3f8130@gmail.com>
In-Reply-To: <20261110-dwc3-s2idle-v1-0-2ef4cc3f8130@gmail.com>
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295002; l=4289;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=jNMsntzexEFNYfvDvDfuJ1KLAm+5KZPCiIvtScpupXE=;
 b=QO7vX1Lcl0MQX0fO7sobHVSzRC745nTiR5dLX9At9xSg2WDjOEM4+yKaJ2RVG8AoRUEBSUUlK
 irImipT+BBlDEFN6RazPmOo407/JtCyBE7WnpvmM6+TVM3bv01C+t0b
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In host mode without wakeup, dwc3_suspend_common() tears the core down
with dwc3_core_exit() and dwc3_resume_common() initialises it again, so
the xHCI registers are back at their reset values when xhci-plat resumes.
xhci_resume() is not told about this: it writes the saved operational
registers back and asks the controller to restore its internal state
(USBCMD.CRS), which cannot work on a freshly reset core. It fails with
USBSTS.SRE, and xhci_resume() only then falls back to a full reset:

  xhci-hcd xhci-hcd.1.auto: xHC error in resume, USBSTS 0x401, Reinit

xhci-plat already has a way for the glue to report this:
xhci_plat_priv.power_lost, which cdns3 sets the same way. Set it from
dwc3_resume_common() whenever the core was re-initialised (and clear it
when it was kept running for wakeup), so xhci_resume() goes straight to
the reset and re-init path.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/dwc3/core.c |  3 +++
 drivers/usb/dwc3/core.h |  3 +++
 drivers/usb/dwc3/host.c | 29 ++++++++++++++++++++++++++---
 3 files changed, 32 insertions(+), 3 deletions(-)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index fd5c2cd36c59..2b31f146e43f 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -2639,8 +2639,10 @@ static int dwc3_resume_common(struct dwc3 *dwc, pm_message_t msg)
 			if (ret)
 				return ret;
 			dwc3_set_prtcap(dwc, DWC3_GCTL_PRTCAP_HOST, true);
+			dwc3_host_resume(dwc, true);
 			break;
 		}
+		dwc3_host_resume(dwc, false);
 		/* Restore GUSB2PHYCFG bits that were modified in suspend */
 		for (i = 0; i < dwc->num_usb2_ports; i++) {
 			reg = dwc3_readl(dwc, DWC3_GUSB2PHYCFG(i));
@@ -2672,6 +2674,7 @@ static int dwc3_resume_common(struct dwc3 *dwc, pm_message_t msg)
 		dwc3_otg_init(dwc);
 		if (dwc->current_otg_role == DWC3_OTG_ROLE_HOST) {
 			dwc3_otg_host_init(dwc);
+			dwc3_host_resume(dwc, true);
 		} else if (dwc->current_otg_role == DWC3_OTG_ROLE_DEVICE) {
 			dwc3_gadget_resume(dwc);
 		}
diff --git a/drivers/usb/dwc3/core.h b/drivers/usb/dwc3/core.h
index f3dabb37f806..862818e081af 100644
--- a/drivers/usb/dwc3/core.h
+++ b/drivers/usb/dwc3/core.h
@@ -1677,11 +1677,14 @@ static inline void dwc3_pre_run_stop(struct dwc3 *dwc, bool is_on)
 #if IS_ENABLED(CONFIG_USB_DWC3_HOST) || IS_ENABLED(CONFIG_USB_DWC3_DUAL_ROLE)
 int dwc3_host_init(struct dwc3 *dwc);
 void dwc3_host_exit(struct dwc3 *dwc);
+void dwc3_host_resume(struct dwc3 *dwc, bool power_lost);
 #else
 static inline int dwc3_host_init(struct dwc3 *dwc)
 { return 0; }
 static inline void dwc3_host_exit(struct dwc3 *dwc)
 { }
+static inline void dwc3_host_resume(struct dwc3 *dwc, bool power_lost)
+{ }
 #endif
 
 #if IS_ENABLED(CONFIG_USB_DWC3_GADGET) || IS_ENABLED(CONFIG_USB_DWC3_DUAL_ROLE)
diff --git a/drivers/usb/dwc3/host.c b/drivers/usb/dwc3/host.c
index c5674161b2b0..fb09b4f58414 100644
--- a/drivers/usb/dwc3/host.c
+++ b/drivers/usb/dwc3/host.c
@@ -14,9 +14,7 @@
 #include <linux/usb/hcd.h>
 #include <linux/bitfield.h>
 
-#include "../host/xhci-port.h"
-#include "../host/xhci-ext-caps.h"
-#include "../host/xhci-caps.h"
+#include "../host/xhci.h"
 #include "../host/xhci-plat.h"
 #include "core.h"
 
@@ -223,6 +221,31 @@ int dwc3_host_init(struct dwc3 *dwc)
 }
 EXPORT_SYMBOL_GPL(dwc3_host_init);
 
+/**
+ * dwc3_host_resume - tell xhci-plat whether the controller lost its state
+ * @dwc: pointer to our controller context structure
+ * @power_lost: true if the core was re-initialised during system resume
+ *
+ * When the core is torn down in system suspend (dwc3_core_exit()) and
+ * initialised again on resume, the xHCI registers are back at their reset
+ * values. xhci_resume() must then reset and re-initialise the host instead
+ * of trying to restore its saved register state with CRS, which fails
+ * (USBSTS.SRE) on a freshly reset controller.
+ */
+void dwc3_host_resume(struct dwc3 *dwc, bool power_lost)
+{
+	struct usb_hcd *hcd;
+
+	if (!dwc->xhci)
+		return;
+
+	hcd = platform_get_drvdata(dwc->xhci);
+	if (!hcd)
+		return;
+
+	hcd_to_xhci_priv(hcd)->power_lost = power_lost;
+}
+
 void dwc3_host_exit(struct dwc3 *dwc)
 {
 	if (dwc->sys_wakeup)

-- 
2.55.0

