From: Igor Velkov <iav@iav.lv>
Date: Sat, 10 Oct 2026 18:20:30 +0000
Subject: [PATCH v2] irqchip/meson-gpio: Allow the GPIO interrupts to wake
 the system
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-meson-gpio-wake-v2-1-790ecc6df792@iav.lv>
X-B4-Tracking: v=1; b=H4sIAO6BymoC/3WNQQ6CMBBFr0Jm7Zi2CAFX3MOwaGUKE7Ulraka0
 rtb2bt8L/nvbxApMEU4VxsEShzZuwLqUMF10W4m5KkwKKFaKUSHD4re4byyx5e+EdraWF0bo6j
 RUFZrIMvvvXgZCy8cnz589oMkf/Z/K0mUaIS2sum76dT2A+t0vCcYc85fCTMS8qsAAAA=
To: Thomas Gleixner <tglx@kernel.org>
Cc: Radu Rendec <radu@rendec.net>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2264; i=iav@iav.lv;
 h=from:subject:message-id; bh=fZVoG9f36dKIjewDv5ebdz4lu+bdjQGttrwUIvjhrKc=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmnGj9LxAQuU8/rZlmZEzdbce2SpXrqKytf31krzLY7o
 +5E+ZGbHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAisYIMfzhKL3ycwCTj22+V
 VCtte5Ff6a3srUyu9s9MEYWPLFpOv2ZkOL523iR5c9aHx5TXntruJMCs863WyzaJRS1NqoGFoy2
 fBQA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

meson_gpio_irq_chip has neither .irq_set_wake nor IRQCHIP_SKIP_SET_WAKE,
so enable_irq_wake() fails with -ENXIO for every interrupt routed through
it, and such an interrupt never gets IRQD_WAKEUP_STATE.

That matters for suspend-to-idle. suspend_device_irqs() keeps only the
wakeup interrupts enabled; the rest are suspended and masked by the flow
handler when they first fire. A GPIO interrupt that fires during s2idle
therefore brings a CPU out of idle once, gets masked, and the system
sleeps on. For mem the firmware chooses the wakeup sources, and this
flag changes nothing there.

Set IRQCHIP_SKIP_SET_WAKE, like the other hierarchical irqchips with a
GIC parent. The GIC sets the same flag, so irq_chip_set_wake_parent()
would end there anyway.

Tested on ODROID-HC4 with the PCF8563 alarm interrupt routed through this
controller: with the flag the alarm wakes the board from s2idle 4/4, and
/sys/power/pm_wakeup_irq names it; without the flag the board stayed in
s2idle past the alarm until a power cycle (0/5).

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Changes in v2:
- Reworded, as Neil asked: say that the test and the effect are for
  suspend-to-idle, describe how genirq handles the interrupt there, and
  note that for mem the firmware picks the wakeup sources.
- Repeated the run without the flag: 0/5 (v1 said 0/1).
- Link to v1: https://lore.kernel.org/r/20261008-meson-gpio-wake-v1-1-b0af1598d469@iav.lv
---
 drivers/irqchip/irq-meson-gpio.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/irqchip/irq-meson-gpio.c b/drivers/irqchip/irq-meson-gpio.c
index 91a9c337fe6d..e0329ef5e4a2 100644
--- a/drivers/irqchip/irq-meson-gpio.c
+++ b/drivers/irqchip/irq-meson-gpio.c
@@ -538,7 +538,7 @@ static struct irq_chip meson_gpio_irq_chip = {
 #ifdef CONFIG_SMP
 	.irq_set_affinity	= irq_chip_set_affinity_parent,
 #endif
-	.flags			= IRQCHIP_SET_TYPE_MASKED,
+	.flags			= IRQCHIP_SET_TYPE_MASKED | IRQCHIP_SKIP_SET_WAKE,
 };
 
 static int meson_gpio_irq_domain_translate(struct irq_domain *domain,

---
base-commit: a90ee4305c4a5df72c11b31dacfdc76e00fcf78a
change-id: 20261008-meson-gpio-wake-f3bfa3bb2e5a

Best regards,
-- 
Igor Velkov <iav@iav.lv>

