From: Mayank Rungta <mrungta@google.com>
Date: Thu, 30 Jul 2026 14:32:49 -0700
Subject: [PATCH 3/3] watchdog: qcom: Register pretimeout interrupt as NMI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-qcom-wdt-nmi-series-v1-3-3aa86d162914@google.com>
References: <20260730-qcom-wdt-nmi-series-v1-0-3aa86d162914@google.com>
In-Reply-To: <20260730-qcom-wdt-nmi-series-v1-0-3aa86d162914@google.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Thomas Gleixner <tglx@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, "Kirill A. Shutemov" <kas@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Mayank Rungta <mrungta@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785447181; l=4433;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=8nEYT2TKwUSRpXG+qjzVIpCk/TBIokJuhVt154QVce0=;
 b=+Y7kOBwCqMcBFbFx1gkqaiMxNA6UH74UIohXvN01vimtuhgjTuFeGElt3HEeg1kasVEDnMFwu
 mAn8nUMHFQ0CmSp9RTdMz7upsDYL6cHfdGNWB0o6n6AjmcVPwgvHsmS
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a system is completely unresponsive due to an interrupt storm or
deadlocked CPU cores with standard interrupts disabled, a standard watchdog
pretimeout bark interrupt will fail to execute, preventing the pretimeout
governor from capturing CPU backtraces before the hardware reset bite.

Attempt to register the pretimeout interrupt as an NMI (or pseudo-NMI)
using request_nmi(). If NMI registration fails due to lack of platform
GIC pseudo-NMI support, fall back to devm_request_irq().

Explicitly arm and disarm the NMI during watchdog start and stop operations
using enable_nmi() and disable_nmi_nosync().

NMI Execution Call Trace (lkdtm HARDLOCKUP freeze break):
 Kernel panic - not syncing: watchdog pretimeout event
 CPU: 0 UID: 0 PID: 5419 Comm: bash Not tainted 6.19.0-rc5-00022
 Hardware name: Google CoachZ (rev3+) (DT)
 Call trace:
  show_stack+0x24/0x34 (C)
  dump_stack_lvl+0x84/0xac
  dump_stack+0x1c/0x34
  vpanic+0xfc/0x2d0
  panic+0x6c/0x74
  watchdog_notify_pretimeout+0x34/0x48
  qcom_wdt_isr+0x20/0x34
  handle_fasteoi_nmi+0x50/0x88
  handle_irq_desc+0x4c/0x68
  generic_handle_domain_nmi+0x38/0x48
  __gic_handle_nmi.isra.0+0x40/0x90
  gic_handle_irq+0x64/0x234
  call_on_irq_stack+0x48/0x88
  do_interrupt_handler+0x74/0xc4
  el1_interrupt+0x5c/0xb0
  lkdtm_HARDLOCKUP+0x18/0x28 (P)

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
 drivers/watchdog/qcom-wdt.c | 55 +++++++++++++++++++++++++++++++++++++++++----
 1 file changed, 51 insertions(+), 4 deletions(-)

diff --git a/drivers/watchdog/qcom-wdt.c b/drivers/watchdog/qcom-wdt.c
index 49bd04841f0c..19d8e91cff40 100644
--- a/drivers/watchdog/qcom-wdt.c
+++ b/drivers/watchdog/qcom-wdt.c
@@ -51,6 +51,9 @@ struct qcom_wdt {
 	unsigned long		rate;
 	void __iomem		*base;
 	const u32		*layout;
+	int			irq;
+	bool			is_nmi;
+	bool			irq_enabled;
 };
 
 static void __iomem *wdt_addr(struct qcom_wdt *wdt, enum wdt_reg reg)
@@ -73,6 +76,30 @@ static irqreturn_t qcom_wdt_isr(int irq, void *arg)
 	return IRQ_HANDLED;
 }
 
+static void qcom_wdt_enable_irq(struct qcom_wdt *wdt)
+{
+	if (wdt->is_nmi && wdt->irq > 0 && !wdt->irq_enabled) {
+		enable_nmi(wdt->irq);
+		wdt->irq_enabled = true;
+	}
+}
+
+static void qcom_wdt_disable_irq(struct qcom_wdt *wdt)
+{
+	if (wdt->is_nmi && wdt->irq > 0 && wdt->irq_enabled) {
+		disable_nmi_nosync(wdt->irq);
+		wdt->irq_enabled = false;
+	}
+}
+
+static void qcom_wdt_free_nmi(void *arg)
+{
+	struct qcom_wdt *wdt = arg;
+
+	qcom_wdt_disable_irq(wdt);
+	free_nmi(wdt->irq, &wdt->wdd);
+}
+
 static int qcom_wdt_start(struct watchdog_device *wdd)
 {
 	struct qcom_wdt *wdt = to_qcom_wdt(wdd);
@@ -83,6 +110,8 @@ static int qcom_wdt_start(struct watchdog_device *wdd)
 	writel(bark * wdt->rate, wdt_addr(wdt, WDT_BARK_TIME));
 	writel(wdd->timeout * wdt->rate, wdt_addr(wdt, WDT_BITE_TIME));
 	writel(QCOM_WDT_ENABLE, wdt_addr(wdt, WDT_EN));
+
+	qcom_wdt_enable_irq(wdt);
 	return 0;
 }
 
@@ -90,6 +119,8 @@ static int qcom_wdt_stop(struct watchdog_device *wdd)
 {
 	struct qcom_wdt *wdt = to_qcom_wdt(wdd);
 
+	qcom_wdt_disable_irq(wdt);
+
 	writel(0, wdt_addr(wdt, WDT_EN));
 	return 0;
 }
@@ -240,6 +271,7 @@ static int qcom_wdt_probe(struct platform_device *pdev)
 	u32 percpu_offset;
 	int irq, ret;
 	struct clk *clk;
+	unsigned long irq_flags;
 
 	data = of_device_get_match_data(dev);
 	if (!data) {
@@ -290,10 +322,25 @@ static int qcom_wdt_probe(struct platform_device *pdev)
 	/* check if there is pretimeout support */
 	irq = platform_get_irq_optional(pdev, 0);
 	if (data->pretimeout && irq > 0) {
-		ret = devm_request_irq(dev, irq, qcom_wdt_isr, 0,
-				       "wdt_bark", &wdt->wdd);
-		if (ret)
-			return ret;
+		wdt->irq = irq;
+		irq_flags = IRQF_PERCPU | IRQF_NOBALANCING |
+			    IRQF_NO_AUTOEN | IRQF_NO_THREAD;
+
+		ret = request_nmi(irq, qcom_wdt_isr, irq_flags,
+				  "wdt_bark", &wdt->wdd);
+		if (ret) {
+			/* Fallback to normal interrupt if NMI not supported */
+			ret = devm_request_irq(dev, irq, qcom_wdt_isr, 0,
+					       "wdt_bark", &wdt->wdd);
+			if (ret)
+				return ret;
+		} else {
+			wdt->is_nmi = true;
+			ret = devm_add_action_or_reset(dev, qcom_wdt_free_nmi,
+						       wdt);
+			if (ret)
+				return ret;
+		}
 
 		wdt->wdd.info = &qcom_wdt_pt_info;
 		wdt->wdd.pretimeout = 1;

-- 
2.55.0.508.g3f0d502094-goog

