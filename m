From: Igor Velkov <iav@iav.lv>
Date: Fri, 20 Nov 2026 05:47:56 +0200
Subject: [PATCH] pwm: meson: Restore the registers after hibernation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-pwm-meson-hib-v1-1-606e947b2c1f@iav.lv>
X-B4-Tracking: v=1; b=H4sIAOvC/2oC/x3MQQqAIBBA0avIrBvIgaK6SrTQnHIWmShUEN49a
 fkW/7+QOQlnmNQLiS/JcoYK3ShYvQk7o7hqoJZ6ranFeB94cD4DerFoBjey7cgxGahNTLzJ8//
 mpZQPMlWZmF8AAAA=
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3326; i=iav@iav.lv;
 h=from:subject:message-id; bh=JOoyPeCQ7AebKuZzzp2MRiGi9mXQP+9Qpistecz8jTo=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFn/D705s6n3fvJShpulGrb7l9lk+SrsyFnyslh6fd0x3
 S3p9xcVdpSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJCK5g+MOztfBx1UmLo0c3
 FB03X9HL0K4VyWBrlj/BRqLp6EIjZSaG/zX6vZzxqnxf/czXTmNL/BTPxvbw/pq/M27LuSV3NGk
 1MQAA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a hibernation image is restored after the system was powered off,
the PWM registers are reset. The channel clocks (mux, divider and gate)
are fields of REG_MISC_AB, and the clock framework still counts the gate
as enabled and the rate as set, so none of these fields is written
again. pwm-fan reconfigures its channel on resume, but that rewrites
only the counters and the enable bits, not the clock fields, and the
PWM core skips an unchanged state altogether. On ODROID-HC4 the fan
stays stopped after the restore.

Save REG_PWM_A, REG_PWM_B and REG_MISC_AB on suspend and write them back
on resume. pwm_AO_cd, which drives the VDDCPU regulator on this board,
is restored the same way.

Tested on ODROID-HC4: after two restores following a power cut, the fan
follows both manual pwm1 settings and the thermal control.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on a v7.3.5 based kernel, before the waveform API conversion, which did not change the clock handling relevant here; build-tested on pwm/for-next.
---
 drivers/pwm/pwm-meson.c | 43 +++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/drivers/pwm/pwm-meson.c b/drivers/pwm/pwm-meson.c
index 633b384358c0..c8fec42ae414 100644
--- a/drivers/pwm/pwm-meson.c
+++ b/drivers/pwm/pwm-meson.c
@@ -119,6 +119,8 @@ struct meson_pwm {
 	 * that is shared between the two PWMs.
 	 */
 	spinlock_t lock;
+	u32 saved_pwm[MESON_NUM_PWMS];
+	u32 saved_misc;
 };
 
 static inline struct meson_pwm *to_meson_pwm(struct pwm_chip *chip)
@@ -732,13 +734,54 @@ static int meson_pwm_probe(struct platform_device *pdev)
 		return dev_err_probe(&pdev->dev, err,
 				     "failed to register PWM chip\n");
 
+	platform_set_drvdata(pdev, chip);
+
+	return 0;
+}
+
+/*
+ * After a power loss the registers are reset, but the PWM core and the clock
+ * framework keep their state and skip unchanged writes.
+ */
+static int meson_pwm_suspend(struct device *dev)
+{
+	struct pwm_chip *chip = dev_get_drvdata(dev);
+	struct meson_pwm *meson = to_meson_pwm(chip);
+	unsigned int i;
+
+	for (i = 0; i < MESON_NUM_PWMS; i++)
+		meson->saved_pwm[i] = readl(meson->base +
+					    meson_pwm_per_channel_data[i].reg_offset);
+	meson->saved_misc = readl(meson->base + REG_MISC_AB);
+
 	return 0;
 }
 
+static int meson_pwm_resume(struct device *dev)
+{
+	struct pwm_chip *chip = dev_get_drvdata(dev);
+	struct meson_pwm *meson = to_meson_pwm(chip);
+	unsigned long flags;
+	unsigned int i;
+
+	spin_lock_irqsave(&meson->lock, flags);
+	for (i = 0; i < MESON_NUM_PWMS; i++)
+		writel(meson->saved_pwm[i], meson->base +
+		       meson_pwm_per_channel_data[i].reg_offset);
+	writel(meson->saved_misc, meson->base + REG_MISC_AB);
+	spin_unlock_irqrestore(&meson->lock, flags);
+
+	return 0;
+}
+
+static DEFINE_SIMPLE_DEV_PM_OPS(meson_pwm_pm_ops, meson_pwm_suspend,
+				meson_pwm_resume);
+
 static struct platform_driver meson_pwm_driver = {
 	.driver = {
 		.name = "meson-pwm",
 		.of_match_table = meson_pwm_matches,
+		.pm = pm_sleep_ptr(&meson_pwm_pm_ops),
 	},
 	.probe = meson_pwm_probe,
 };

---
base-commit: 3f9bd3ccc80af2684cfc0901757f85a78358cbab
change-id: 20261120-pwm-meson-hib-a8d9eb52de2a

Best regards,
-- 
Igor Velkov <iav@iav.lv>

