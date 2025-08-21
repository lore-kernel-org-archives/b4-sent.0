From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:38:56 +0000
Subject: [PATCH RFC 04/22] usb: dwc3: apple: Reset dwc3 during role
 switches
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-4-172beda182b8@kernel.org>
References: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
In-Reply-To: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8338; i=sven@kernel.org;
 h=from:subject:message-id; bh=a5iByOwmuIst1Br18o+6QngL0G+1LuBDoKuObEUxjUA=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy28VH+d89+XTrz3pPE9mDy1KzVPocVvPxzWGfX5HYd
 2WXoHB5RykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAimYsZ/icnpUZm3Xe4mjS5
 +Qorx6RFOncyV62PZsn4Vr90Q9eUf3sYGV7/vlLVzCxi77rda0qeT+LUSXcTGGyNZA5oTRPuO8e
 +iQUA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As mad as it sounds, the dwc3 controller present on the Apple M1 must be
reset and reinitialized whenever a device is unplugged from the root
port or when the PHY mode is changed.

This is required for at least the following reasons:

  - The USB2 D+/D- lines are connected through a stateful eUSB2 repeater
    which in turn is controlled by a variant of the TI TPS6598x USB PD
    chip. When the USB PD controller detects a hotplug event it resets
    the eUSB2 repeater. Afterwards, no new device is recognized before
    the DWC3 core and PHY are reset as well because the eUSB2 repeater
    and the PHY/dwc3 block disagree about the current state.

  - It's possible to completely break the dwc3 controller by switching
    it to device mode and unplugging the cable at just the wrong time.
    If this happens dwc3 behaves as if no device is connected.
    CORESOFTRESET will also never clear after it has been set. The only
    workaround is to trigger a hard reset of the entire dwc3 core with
    its external reset line.

  - Whenever the PHY mode is changed (to e.g. transition to DisplayPort
    alternate mode or USB4) dwc3 has to be shutdown and reinitialized.
    Otherwise the Type-C port will not be usable until the entire SoC
    has been reset.

All of this can be easily worked around by respecting transitions to
USB_ROLE_NONE and making sure the external reset line is asserted when
switching roles. We additionally have to ensure that the PHY is
suspended during init.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/dwc3/core.c | 61 +++++++++++++++++++++++++++++++++++++++++++++----
 drivers/usb/dwc3/core.h |  3 +++
 drivers/usb/dwc3/drd.c  | 11 ++++++++-
 drivers/usb/dwc3/host.c |  3 ++-
 4 files changed, 72 insertions(+), 6 deletions(-)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index 8002c23a5a02acb8f3e87b2662a53998a4cf4f5c..26aa507a738f001409a97ef563c6561433a1cac5 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -158,6 +158,9 @@ void dwc3_set_prtcap(struct dwc3 *dwc, u32 mode, bool ignore_susphy)
 	dwc->current_dr_role = mode;
 }
 
+static void dwc3_core_exit(struct dwc3 *dwc);
+static int dwc3_core_init_for_resume(struct dwc3 *dwc);
+
 static void __dwc3_set_mode(struct work_struct *work)
 {
 	struct dwc3 *dwc = work_to_dwc(work);
@@ -177,7 +180,7 @@ static void __dwc3_set_mode(struct work_struct *work)
 	if (dwc->current_dr_role == DWC3_GCTL_PRTCAP_OTG)
 		dwc3_otg_update(dwc, 0);
 
-	if (!desired_dr_role)
+	if (!desired_dr_role && !dwc->role_switch_reset_quirk)
 		goto out;
 
 	if (desired_dr_role == dwc->current_dr_role)
@@ -205,13 +208,32 @@ static void __dwc3_set_mode(struct work_struct *work)
 		break;
 	}
 
+	if (dwc->role_switch_reset_quirk) {
+		if (dwc->current_dr_role) {
+			dwc->current_dr_role = 0;
+			dwc3_core_exit(dwc);
+		}
+
+		if (desired_dr_role) {
+			ret = dwc3_core_init_for_resume(dwc);
+			if (ret) {
+				dev_err(dwc->dev,
+				    "failed to reinitialize core\n");
+				goto out;
+			}
+		} else {
+			goto out;
+		}
+	}
+
 	/*
 	 * When current_dr_role is not set, there's no role switching.
 	 * Only perform GCTL.CoreSoftReset when there's DRD role switching.
 	 */
-	if (dwc->current_dr_role && ((DWC3_IP_IS(DWC3) ||
+	if (dwc->role_switch_reset_quirk ||
+		(dwc->current_dr_role && ((DWC3_IP_IS(DWC3) ||
 			DWC3_VER_IS_PRIOR(DWC31, 190A)) &&
-			desired_dr_role != DWC3_GCTL_PRTCAP_OTG)) {
+			desired_dr_role != DWC3_GCTL_PRTCAP_OTG))) {
 		reg = dwc3_readl(dwc->regs, DWC3_GCTL);
 		reg |= DWC3_GCTL_CORESOFTRESET;
 		dwc3_writel(dwc->regs, DWC3_GCTL, reg);
@@ -1372,6 +1394,9 @@ static int dwc3_core_init(struct dwc3 *dwc)
 	if (ret)
 		goto err_exit_phy;
 
+	if (dwc->role_switch_reset_quirk)
+		dwc3_enable_susphy(dwc, true);
+
 	dwc3_core_setup_global_control(dwc);
 	dwc3_core_num_eps(dwc);
 
@@ -1635,6 +1660,18 @@ static int dwc3_core_init_mode(struct dwc3 *dwc)
 		ret = dwc3_drd_init(dwc);
 		if (ret)
 			return dev_err_probe(dev, ret, "failed to initialize dual-role\n");
+
+		/*
+		 * If the role switch reset quirk is required the first role
+		 * switch notification will initialize the core such that we
+		 * have to shut it down here. Make sure that the __dwc3_set_mode
+		 * queued by dwc3_drd_init has completed before since it
+		 * may still try to access MMIO.
+		 */
+		if (dwc->role_switch_reset_quirk) {
+			flush_work(&dwc->drd_work);
+			dwc3_core_exit(dwc);
+		}
 		break;
 	default:
 		dev_err(dev, "Unsupported mode of operation %d\n", dwc->dr_mode);
@@ -2223,6 +2260,22 @@ int dwc3_core_probe(const struct dwc3_probe_data *data)
 			goto err_put_psy;
 	}
 
+	if (dev->of_node) {
+		if (of_device_is_compatible(dev->of_node, "apple,t8103-dwc3")) {
+			if (!IS_ENABLED(CONFIG_USB_ROLE_SWITCH) ||
+			    !IS_ENABLED(CONFIG_USB_DWC3_DUAL_ROLE)) {
+				dev_err(dev,
+				    "Apple DWC3 requires role switch support.\n"
+				    );
+				ret = -EINVAL;
+				goto err_put_psy;
+			}
+
+			dwc->dr_mode = USB_DR_MODE_OTG;
+			dwc->role_switch_reset_quirk = true;
+		}
+	}
+
 	ret = reset_control_deassert(dwc->reset);
 	if (ret)
 		goto err_put_psy;
@@ -2391,7 +2444,6 @@ static void dwc3_remove(struct platform_device *pdev)
 	dwc3_core_remove(platform_get_drvdata(pdev));
 }
 
-#ifdef CONFIG_PM
 static int dwc3_core_init_for_resume(struct dwc3 *dwc)
 {
 	int ret;
@@ -2418,6 +2470,7 @@ static int dwc3_core_init_for_resume(struct dwc3 *dwc)
 	return ret;
 }
 
+#ifdef CONFIG_PM
 static int dwc3_suspend_common(struct dwc3 *dwc, pm_message_t msg)
 {
 	u32 reg;
diff --git a/drivers/usb/dwc3/core.h b/drivers/usb/dwc3/core.h
index d5b985fa12f4d9ee3f318ea5cce7c1b225cd3623..38f32f2a6193c1b2662ab4f38f4d20cf4b0e198d 100644
--- a/drivers/usb/dwc3/core.h
+++ b/drivers/usb/dwc3/core.h
@@ -1154,6 +1154,7 @@ struct dwc3_scratchpad_array {
  * @suspended: set to track suspend event due to U3/L2.
  * @susphy_state: state of DWC3_GUSB2PHYCFG_SUSPHY + DWC3_GUSB3PIPECTL_SUSPHY
  *		  before PM suspend.
+ * @role_switch_reset_quirk: set to force reinitialization after any role switch
  * @imod_interval: set the interrupt moderation interval in 250ns
  *			increments or 0 to disable.
  * @max_cfg_eps: current max number of IN eps used across all USB configs.
@@ -1392,6 +1393,8 @@ struct dwc3 {
 	unsigned		suspended:1;
 	unsigned		susphy_state:1;
 
+	unsigned		role_switch_reset_quirk:1;
+
 	u16			imod_interval;
 
 	int			max_cfg_eps;
diff --git a/drivers/usb/dwc3/drd.c b/drivers/usb/dwc3/drd.c
index 7977860932b142924edd19f859f7c4041d11eda6..65450db91bdea00bb30bfb368f5195ad2fd58da4 100644
--- a/drivers/usb/dwc3/drd.c
+++ b/drivers/usb/dwc3/drd.c
@@ -464,6 +464,9 @@ static int dwc3_usb_role_switch_set(struct usb_role_switch *sw,
 		break;
 	}
 
+	if (dwc->role_switch_reset_quirk && role == USB_ROLE_NONE)
+		mode = 0;
+
 	dwc3_set_mode(dwc, mode);
 	return 0;
 }
@@ -492,6 +495,10 @@ static enum usb_role dwc3_usb_role_switch_get(struct usb_role_switch *sw)
 			role = USB_ROLE_DEVICE;
 		break;
 	}
+
+	if (dwc->role_switch_reset_quirk && !dwc->current_dr_role)
+		role = USB_ROLE_NONE;
+
 	spin_unlock_irqrestore(&dwc->lock, flags);
 	return role;
 }
@@ -502,7 +509,9 @@ static int dwc3_setup_role_switch(struct dwc3 *dwc)
 	u32 mode;
 
 	dwc->role_switch_default_mode = usb_get_role_switch_default_mode(dwc->dev);
-	if (dwc->role_switch_default_mode == USB_DR_MODE_HOST) {
+	if (dwc->role_switch_reset_quirk) {
+		mode = 0;
+	} else if (dwc->role_switch_default_mode == USB_DR_MODE_HOST) {
 		mode = DWC3_GCTL_PRTCAP_HOST;
 	} else {
 		dwc->role_switch_default_mode = USB_DR_MODE_PERIPHERAL;
diff --git a/drivers/usb/dwc3/host.c b/drivers/usb/dwc3/host.c
index 1c513bf8002ec9ec91b41bfd096cbd0da1dd2d2e..f7a71e6f9d80aca632f1f970d900a3de8a76f0a7 100644
--- a/drivers/usb/dwc3/host.c
+++ b/drivers/usb/dwc3/host.c
@@ -223,7 +223,8 @@ void dwc3_host_exit(struct dwc3 *dwc)
 	if (dwc->sys_wakeup)
 		device_init_wakeup(&dwc->xhci->dev, false);
 
-	dwc3_enable_susphy(dwc, false);
+	if (!dwc->role_switch_reset_quirk)
+		dwc3_enable_susphy(dwc, false);
 	platform_device_unregister(dwc->xhci);
 	dwc->xhci = NULL;
 }

-- 
2.34.1

