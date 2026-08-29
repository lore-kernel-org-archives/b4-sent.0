From: Matt Eaton <linux@divinehawk.com>
Date: Sat, 29 Aug 2026 22:04:11 +0200
Subject: [PATCH v2 2/3] usb: dwc3: add xhci_no_soft_retry software property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-xhci-no-soft-retry-v2-2-0efe22f1c2f8@divinehawk.com>
References: <20260829-xhci-no-soft-retry-v2-0-0efe22f1c2f8@divinehawk.com>
In-Reply-To: <20260829-xhci-no-soft-retry-v2-0-0efe22f1c2f8@divinehawk.com>
To: Mathias Nyman <mathias.nyman@intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Matt Eaton <linux@divinehawk.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788033855; l=3697;
 i=linux@divinehawk.com; s=20260828; h=from:subject:message-id;
 bh=8I5kFxZQTwOwXEoL87NTYKHACEZsZUaVcRMYWJSXOYw=;
 b=O5lEqcGo/HbB5TD3tPVFvLyPYoBq0ArNwyh9Jh7lgzWQFjiNZw0tKAkHWMPneOxzTAJCclEf0
 gyF7fV4TD9GA7m4iXdsEhvMEH6aE4aqocDyzTJJf0v32bSS5hjfj4wC
X-Developer-Key: i=linux@divinehawk.com; a=ed25519;
 pk=UG4KnKXGwxjTNdirUPh/nySblET4aRxWYWSMTQwzlMw=
X-Endpoint-Received: by B4 Relay for linux@divinehawk.com/20260828 with auth_id=982
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some DWC3 instances cannot carry out xHCI 1.0 Soft Retry correctly. Add a
software property so a glue driver can say so on behalf of hardware it
recognises from its compatible, carry it into struct dwc3, and pass it on
to xhci-plat as an xhci-no-soft-retry-quirk swnode property alongside the
other xHCI properties dwc3_host_init() already sets.

Nothing sets it yet, so no platform changes behaviour.

Suggested-by: Thinh Nguyen <Thinh.Nguyen@synopsys.com>
Signed-off-by: Matt Eaton <linux@divinehawk.com>
---
 drivers/usb/dwc3/core.c | 3 +++
 drivers/usb/dwc3/core.h | 3 +++
 drivers/usb/dwc3/glue.h | 3 +++
 drivers/usb/dwc3/host.c | 5 ++++-
 4 files changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index fd5c2cd36c59..1acfad333271 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -1694,6 +1694,9 @@ static void dwc3_get_software_properties(struct dwc3 *dwc,
 	if (properties->needs_full_reinit)
 		dwc->needs_full_reinit = true;
 
+	if (properties->xhci_no_soft_retry)
+		dwc->xhci_no_soft_retry = true;
+
 	dwc->gsbuscfg0_reqinfo = DWC3_GSBUSCFG0_REQINFO_UNSPECIFIED;
 
 	if (properties->gsbuscfg0_reqinfo !=
diff --git a/drivers/usb/dwc3/core.h b/drivers/usb/dwc3/core.h
index 608daeb7ef10..c8beca1b10b3 100644
--- a/drivers/usb/dwc3/core.h
+++ b/drivers/usb/dwc3/core.h
@@ -1123,6 +1123,8 @@ struct dwc3_glue_ops {
  * @usb2_gadget_lpm_disable: set to disable usb2 lpm for gadget
  * @needs_full_reinit: set to indicate the core may lose power and need full
  *			initialization during system pm
+ * @xhci_no_soft_retry: set to indicate the xHCI cannot carry out Soft Retry
+ *			correctly
  * @disable_scramble_quirk: set if we enable the disable scramble quirk
  * @u2exit_lfps_quirk: set if we enable u2exit lfps quirk
  * @u2ss_inp3_quirk: set if we enable P3 OK for U2/SS Inactive quirk
@@ -1384,6 +1386,7 @@ struct dwc3 {
 	unsigned		usb2_lpm_disable:1;
 	unsigned		usb2_gadget_lpm_disable:1;
 	unsigned		needs_full_reinit:1;
+	unsigned		xhci_no_soft_retry:1;
 
 	unsigned		disable_scramble_quirk:1;
 	unsigned		u2exit_lfps_quirk:1;
diff --git a/drivers/usb/dwc3/glue.h b/drivers/usb/dwc3/glue.h
index d738e1739ae0..595880332d19 100644
--- a/drivers/usb/dwc3/glue.h
+++ b/drivers/usb/dwc3/glue.h
@@ -14,10 +14,13 @@
  * @gsbuscfg0_reqinfo: Value to be programmed in the GSBUSCFG0.REQINFO field
  * @needs_full_reinit: indicate the controller may not remain power during system
  *			pm and need full initialization
+ * @xhci_no_soft_retry: indicate the controller cannot carry out xHCI Soft
+ *			Retry correctly
  */
 struct dwc3_properties {
 	u32 gsbuscfg0_reqinfo;
 	unsigned needs_full_reinit:1;
+	unsigned xhci_no_soft_retry:1;
 };
 
 #define DWC3_DEFAULT_PROPERTIES ((struct dwc3_properties){		\
diff --git a/drivers/usb/dwc3/host.c b/drivers/usb/dwc3/host.c
index c5674161b2b0..e22a8dc5d090 100644
--- a/drivers/usb/dwc3/host.c
+++ b/drivers/usb/dwc3/host.c
@@ -130,7 +130,7 @@ static int dwc3_host_get_irq(struct dwc3 *dwc)
 
 int dwc3_host_init(struct dwc3 *dwc)
 {
-	struct property_entry	props[6];
+	struct property_entry	props[7];
 	struct platform_device	*xhci;
 	int			ret, irq;
 	int			prop_idx = 0;
@@ -186,6 +186,9 @@ int dwc3_host_init(struct dwc3 *dwc)
 	if (DWC3_VER_IS_WITHIN(DWC3, ANY, 300A))
 		props[prop_idx++] = PROPERTY_ENTRY_BOOL("quirk-broken-port-ped");
 
+	if (dwc->xhci_no_soft_retry)
+		props[prop_idx++] = PROPERTY_ENTRY_BOOL("xhci-no-soft-retry-quirk");
+
 	props[prop_idx++] = PROPERTY_ENTRY_U16("num-hc-interrupters",
 					       dwc->num_hc_interrupters);
 

-- 
2.43.0

