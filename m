From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:22:08 -0500
Subject: [PATCH 3/3] usb: dwc2: Handle OTG interrupts that GINTSTS does not
 flag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-dwc2-v1-3-d959375e26ab@telaak.dev>
References: <20261104-sf19a2890-dwc2-v1-0-d959375e26ab@telaak.dev>
In-Reply-To: <20261104-sf19a2890-dwc2-v1-0-d959375e26ab@telaak.dev>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Minas Harutyunyan <hminas@synopsys.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776930; l=3164;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=+gnzh383ADRzly7Ief5zkWrWw3Pc47lfMuoWe2KoTVw=;
 b=1yVicNsr/efnZEvvp94GLSifXj9AyCXXPcTOUGEKdU2lZ9aNrNouQYqdzn/dvoE3770lk5VEi
 7rp+Fl7JCq0A/Y2wCu2UchGJRbWOze6EqUcUiHTKA//MwZjQaVwmei2
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuanhong Guo <gch981213@gmail.com>

The DWC OTG 3.30a found on Siflower SF19A2890 has battery charger
support enabled. It triggers MultVallpChng interrupt (bit 20 of
GOTGINT) but doesn't set OTGInt in GINTSTS. As a result, this
interrupt is never handled, and Linux disables USB interrupt
because "nobody cares".

Handle OTG interrupt in IRQ handler regardless of whether the
OTGInt bit in GINTSTS is set or not.

On a GL.iNet GL-SFT1200 it shows differently: after a few replugs of a
USB stick the system stops making progress, the console repeating its
last message with the same timestamp, until a power cycle.

Signed-off-by: Chuanhong Guo <gch981213@gmail.com>
[jt: only on cores with the new otg_int_unflagged parameter, which
 SF19A2890 sets, in the one place that already handles flagged OTG
 interrupts and with IRQ_HANDLED returned; the others still handle OTG
 interrupts only when GINTSTS flags them; what a GL-SFT1200 does without
 the patch, subject]
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/usb/dwc2/core.h      | 6 ++++++
 drivers/usb/dwc2/core_intr.c | 5 ++++-
 drivers/usb/dwc2/params.c    | 1 +
 3 files changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/dwc2/core.h b/drivers/usb/dwc2/core.h
index 015a5fb78..288baaaf4 100644
--- a/drivers/usb/dwc2/core.h
+++ b/drivers/usb/dwc2/core.h
@@ -367,6 +367,11 @@ enum dwc2_ep0_state {
  * @no_clock_gating:	Specifies whether to avoid clock gating feature.
  *			0 - No (use clock gating)
  *			1 - Yes (avoid it)
+ * @otg_int_unflagged:	Specifies whether the core raises OTG interrupts
+ *			without setting OTGINT in GINTSTS, so that GOTGINT
+ *			has to be checked on every interrupt.
+ *			0 - No
+ *			1 - Yes
  * @lpm:		Enable LPM support.
  *			0 - No
  *			1 - Yes
@@ -466,6 +471,7 @@ struct dwc2_core_params {
 #define DWC2_POWER_DOWN_PARAM_PARTIAL		1
 #define DWC2_POWER_DOWN_PARAM_HIBERNATION	2
 	bool no_clock_gating;
+	bool otg_int_unflagged;
 
 	bool lpm;
 	bool lpm_clock_gating;
diff --git a/drivers/usb/dwc2/core_intr.c b/drivers/usb/dwc2/core_intr.c
index 9565e6a52..e7bb9709c 100644
--- a/drivers/usb/dwc2/core_intr.c
+++ b/drivers/usb/dwc2/core_intr.c
@@ -874,8 +874,11 @@ irqreturn_t dwc2_handle_common_intr(int irq, void *dev)
 
 	if (gintsts & GINTSTS_MODEMIS)
 		dwc2_handle_mode_mismatch_intr(hsotg);
-	if (gintsts & GINTSTS_OTGINT)
+	if ((gintsts & GINTSTS_OTGINT) ||
+	    (hsotg->params.otg_int_unflagged && dwc2_readl(hsotg, GOTGINT))) {
 		dwc2_handle_otg_intr(hsotg);
+		retval = IRQ_HANDLED;
+	}
 	if (gintsts & GINTSTS_CONIDSTSCHNG)
 		dwc2_handle_conn_id_status_change_intr(hsotg);
 	if (gintsts & GINTSTS_DISCONNINT)
diff --git a/drivers/usb/dwc2/params.c b/drivers/usb/dwc2/params.c
index f6379e616..22ab9ce13 100644
--- a/drivers/usb/dwc2/params.c
+++ b/drivers/usb/dwc2/params.c
@@ -243,6 +243,7 @@ static void dwc2_set_sf19a2890_params(struct dwc2_hsotg *hsotg)
 
 	p->max_transfer_size = 65535;
 	p->ahbcfg = GAHBCFG_HBSTLEN_INCR4 << GAHBCFG_HBSTLEN_SHIFT;
+	p->otg_int_unflagged = true;
 }
 
 static void dwc2_set_stm32f4x9_fsotg_params(struct dwc2_hsotg *hsotg)

-- 
Git-155)

