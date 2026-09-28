From: Fabricio Akio <fabricioakio@gmail.com>
Date: Mon, 28 Sep 2026 15:16:28 -0300
Subject: [PATCH] usb: dwc3: qcom: Check for L2 only when suspending a host
 with wakeup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-dwc3-qcom-l2-check-v1-1-43c5c6e97922@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxG4auQrm2CJRDwKsYFU36kqCAzCiaEu
 zvK8lu8t1KANwQ6JSt5zBZsHCKOh4S0q4cr2JpoklSKtJKSm0UznnR88F1YO+iNkbk8rxWtK4R
 i+PRo7fOfni+7w9v10NfvRNv2BTbuNNt2AAAA
X-Change-ID: 20260928-dwc3-qcom-l2-check-e3b55acefb62
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790619393; l=3338;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=kTgm6rFNJ51HgyF1+bhK1uBxwLypDtFEi7P/iVrPY/M=;
 b=s+l+3PPixIi2c5hVLy8Fdn/OQHPA87hXlNkWFP0pgQolbC7E5p2g+Kt68KYFBMgt9IqJpmlH3
 Ou5vl5s1IsSDCuH50PYMVjRUI7s9SY7WkF05DvqQxnc6O13anbq5/Uq
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In peripheral mode the core disconnects and powers the PHY off before
the glue suspends, so the link never enters L2 and every system
suspend logs "HS-PHY not in L2". Check only for a host with wakeup,
the one case that parks the PHY in L2.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Tested on a Motorola Moto X4 (XT1900-6, SDM630) with the sdm660-mainline
7.2.3 tree, in peripheral mode with the cable attached: the "HS-PHY not
in L2" message appears on every system suspend without this patch, and
not over three consecutive cycles with it. Host mode is untested, since
this board runs the controller in peripheral mode. The board binds
dwc3-qcom-legacy, so the same change in dwc3-qcom.c is build-tested
only. Applies unchanged to next-20260928.
---
 drivers/usb/dwc3/dwc3-qcom-legacy.c | 16 ++++++++++++----
 drivers/usb/dwc3/dwc3-qcom.c        | 16 ++++++++++++----
 2 files changed, 24 insertions(+), 8 deletions(-)

diff --git a/drivers/usb/dwc3/dwc3-qcom-legacy.c b/drivers/usb/dwc3/dwc3-qcom-legacy.c
index d3fad0fcfdac..ba3f70dea4ab 100644
--- a/drivers/usb/dwc3/dwc3-qcom-legacy.c
+++ b/drivers/usb/dwc3/dwc3-qcom-legacy.c
@@ -431,10 +431,18 @@ static int dwc3_qcom_suspend(struct dwc3_qcom *qcom, bool wakeup)
 	if (qcom->is_suspended)
 		return 0;
 
-	for (i = 0; i < qcom->num_ports; i++) {
-		val = readl(qcom->qscratch_base + pwr_evnt_irq_stat_reg[i]);
-		if (!(val & PWR_EVNT_LPM_IN_L2_MASK))
-			dev_err(qcom->dev, "port-%d HS-PHY not in L2\n", i + 1);
+	/*
+	 * Only a host with wakeup enabled keeps the HS PHY powered and parks
+	 * it in L2 across suspend. A peripheral disconnects from the bus and
+	 * powers the PHY off first, so its link never enters L2.
+	 */
+	if (dwc3_qcom_is_host(qcom) && wakeup) {
+		for (i = 0; i < qcom->num_ports; i++) {
+			val = readl(qcom->qscratch_base + pwr_evnt_irq_stat_reg[i]);
+			if (!(val & PWR_EVNT_LPM_IN_L2_MASK))
+				dev_err(qcom->dev, "port-%d HS-PHY not in L2\n",
+					i + 1);
+		}
 	}
 
 	for (i = qcom->num_clocks - 1; i >= 0; i--)
diff --git a/drivers/usb/dwc3/dwc3-qcom.c b/drivers/usb/dwc3/dwc3-qcom.c
index ac68b4218b56..e0920da280ce 100644
--- a/drivers/usb/dwc3/dwc3-qcom.c
+++ b/drivers/usb/dwc3/dwc3-qcom.c
@@ -343,10 +343,18 @@ static int dwc3_qcom_suspend(struct dwc3_qcom *qcom, bool wakeup)
 	if (qcom->is_suspended)
 		return 0;
 
-	for (i = 0; i < qcom->num_ports; i++) {
-		val = readl(qcom->qscratch_base + pwr_evnt_irq_stat_reg[i]);
-		if (!(val & PWR_EVNT_LPM_IN_L2_MASK))
-			dev_err(qcom->dev, "port-%d HS-PHY not in L2\n", i + 1);
+	/*
+	 * Only a host with wakeup enabled keeps the HS PHY powered and parks
+	 * it in L2 across suspend. A peripheral disconnects from the bus and
+	 * powers the PHY off first, so its link never enters L2.
+	 */
+	if (dwc3_qcom_is_host(qcom) && wakeup) {
+		for (i = 0; i < qcom->num_ports; i++) {
+			val = readl(qcom->qscratch_base + pwr_evnt_irq_stat_reg[i]);
+			if (!(val & PWR_EVNT_LPM_IN_L2_MASK))
+				dev_err(qcom->dev, "port-%d HS-PHY not in L2\n",
+					i + 1);
+		}
 	}
 	clk_bulk_disable_unprepare(qcom->num_clocks, qcom->clks);
 

---
base-commit: 6375e61c01e93e35ee7acd336a689ac1fae4b509
change-id: 20260928-dwc3-qcom-l2-check-e3b55acefb62

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

