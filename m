From: George Moussalem <george.moussalem@outlook.com>
Date: Sun, 06 Sep 2026 07:52:40 +0400
Subject: [PATCH v2 01/10] usb: dwc3: core: Allow glue layer to pass
 reference clock rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-ipq-flatten-usb-v2-1-dab83120b10a@outlook.com>
References: <20260906-ipq-flatten-usb-v2-0-dab83120b10a@outlook.com>
In-Reply-To: <20260906-ipq-flatten-usb-v2-0-dab83120b10a@outlook.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788666763; l=3846;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=XS2lUluyNIQ284w/BNk2sQpv86j1/GqdSRhm4g7gG/k=;
 b=u1hsW82CJUk1uNXi7suuLsLUiBqRvTSbqX7awyaNXZPWzJQHI2mWGXmISXw+e4VXd3F3dWkDe
 f2rg3Qghv21COEIn/prywPMDcesQWQ4Q3JTyTd8g4REzI0krTczYuhO
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ability to pass the reference clock rate from the glue layer to the
DWC3 core driver. The core calculates the reference clock period and
frame length adjustment based on the reference clock rate.

In the flattened snsp-dwc3 model, it is currently not possible to pass a
reference clock that differs from the default since:
commit 613a2e655d4d ("usb: dwc3: core: Expose core driver as library")

The new glue layers (incl. Qualcomm's) set the ignore_clocks_and_resets
flag in dwc3_probe_data to true, which disables the core driver's clock
management, thus it also doesn't acquire the reference clock from the
devicetree needed in dwc3_ref_clk_period.

There's an existing DT property 'snps,ref-clock-period-ns', but that's
been deprecated. In addition, basing the rate from the period is often
not accurate enough to derive the frame length adjustment value.

This prevents moving chipsets such as IPQ5018, IPQ6018, IPQ5332, IPQ5424
and IPQ9574 with a reference clock rate that computes values for the
period and frame length adjustment different from the hardware default
from moving to the flattened model.

So, add ability to set the reference clock rate in dwc3_probe_data, then
have the core obtain the clock rate and use that to calculate the
required period and frame length adjustment.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/usb/dwc3/core.c | 6 ++++++
 drivers/usb/dwc3/core.h | 2 ++
 drivers/usb/dwc3/glue.h | 4 ++++
 3 files changed, 12 insertions(+)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index fd5c2cd36c59..6ff0e4822b49 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -420,6 +420,9 @@ static void dwc3_ref_clk_period(struct dwc3 *dwc)
 	} else if (dwc->ref_clk_per) {
 		period = dwc->ref_clk_per;
 		rate = NSEC_PER_SEC / period;
+	} else if (dwc->ref_clk_rate) {
+		rate = dwc->ref_clk_rate;
+		period = NSEC_PER_SEC / rate;
 	} else {
 		return;
 	}
@@ -2334,6 +2337,9 @@ int dwc3_core_probe(const struct dwc3_probe_data *data)
 			goto err_put_psy;
 	}
 
+	if (data->ref_clk_rate > 0)
+		dwc->ref_clk_rate = data->ref_clk_rate;
+
 	ret = reset_control_deassert(dwc->reset);
 	if (ret)
 		goto err_put_psy;
diff --git a/drivers/usb/dwc3/core.h b/drivers/usb/dwc3/core.h
index 608daeb7ef10..4181d57a6cd3 100644
--- a/drivers/usb/dwc3/core.h
+++ b/drivers/usb/dwc3/core.h
@@ -1032,6 +1032,7 @@ struct dwc3_glue_ops {
  * @regs_size: address space size
  * @fladj: frame length adjustment
  * @ref_clk_per: reference clock period configuration
+ * @ref_clk_rate: reference clock rate provided by glue layer
  * @irq_gadget: peripheral controller's IRQ number
  * @otg_irq: IRQ number for OTG IRQs
  * @current_otg_role: current role of operation while using the OTG block
@@ -1261,6 +1262,7 @@ struct dwc3 {
 
 	u32			fladj;
 	u32			ref_clk_per;
+	unsigned long		ref_clk_rate;
 	u32			irq_gadget;
 	u32			otg_irq;
 	u32			current_otg_role;
diff --git a/drivers/usb/dwc3/glue.h b/drivers/usb/dwc3/glue.h
index d738e1739ae0..ed96b10d8cd8 100644
--- a/drivers/usb/dwc3/glue.h
+++ b/drivers/usb/dwc3/glue.h
@@ -33,6 +33,9 @@ struct dwc3_properties {
  * @skip_core_init_mode: Skip the finial initialization of the target mode, as
  *		it must be managed by the glue
  * @properties: dwc3 software manage properties
+ * @ref_clk_rate: optional reference clock rate for the DWC3 core to compute the
+ *		period and frame length adjustment required if these values
+ *		differ from the hardware default.
  */
 struct dwc3_probe_data {
 	struct dwc3 *dwc;
@@ -40,6 +43,7 @@ struct dwc3_probe_data {
 	bool ignore_clocks_and_resets;
 	bool skip_core_init_mode;
 	struct dwc3_properties properties;
+	unsigned long ref_clk_rate;
 };
 
 /**

-- 
2.53.0

