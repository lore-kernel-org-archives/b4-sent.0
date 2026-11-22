From: Anthony Ruhier <aruhier@mailbox.org>
Date: Sun, 22 Nov 2026 12:34:25 +0100
Subject: [PATCH RFC] clocksource/arm_arch_timer: park stopped timers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-x1e-arch-timer-park-v1-1-c26dc527c71f@mailbox.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQuCQBBG/4p85wacDWTrGvQDukqHbR1zikxmV
 QTxv7fV8T14b0USU0k4FitMZk367jPwrkDsQn8X0iYzXOkqZudoYaFgsaNRX2I0BHtSU7Z+f5D
 AlffI5WDS6vK71ricT7j+ZZpuD4nj94dt+wCadHu1fAAAAA==
X-Change-ID: 20261122-x1e-arch-timer-park-d0f839ea1688
To: Mark Rutland <mark.rutland@arm.com>, Marc Zyngier <maz@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>
Cc: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Anthony Ruhier <aruhier@mailbox.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3127; i=aruhier@mailbox.org;
 s=2026; h=from:subject:message-id;
 bh=OlttGN71nDchITfUTGgkO4dnaqxjbFjLuTe80BMQ2p4=;
 b=owGbwMvMwCV2okp4cvOBsLOMp9WSGLKZLmd9S585bWfZ9Pjg3JqyLVI/9reU9lx79yV1b4mPo
 aaPYemTjoksDGJcDJZiiiwXLAseP74VPbm7zqYLZg4rE8gQaZEGBiBgYeDLTcwrNdIx0jPVNtQz
 BDJ0jBi4OAVgqtffYPif3fXF7J/z2fe3OT5fa9BZNl3gh2uk4Hz1jBf2pn/nXd3xiZFhX9B9t9k
 9kW3r2/9J8XQt/Drvo/QF92lT4u76TJ1f1ujLDQA=
X-Developer-Key: i=aruhier@mailbox.org; a=openpgp;
 fpr=F4A378DD8D494AE48EBA554CB00FBC7D08D231D9
X-Endpoint-Received: by B4 Relay for aruhier@mailbox.org/2026 with auth_id=1292
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a clockevent is shut down, the timer is disabled and its CVAL is
left at the last programmed deadline, which is in the past.

On Qualcomm X1E (Hamoa), when Linux runs at EL2 and uses the physical
timer (CNTP_*_EL0, i.e. CNTHP_*_EL2 under VHE), the firmware seems to
expect a non disabled timer and uses its CVAL to compute the wake-up
deadline for system power collapse. In s2idle the stale CVAL makes PSCI
CPU_SUSPEND return immediately, so the SoC never reaches DDR LPM or CX
collapse.

Instead of disabling the timer on shutdown, leave it enabled but masked,
with CVAL set to BIT(width - 1) - 1. The firmware seems to treat CVAL as
a signed value, so this is the largest value it accepts. Anything higher
is rejected and ends up in the same immediate wake-up loop.

Tested on a Lenovo Yoga Slim 7x (X1E80100): s2idle now reaches DDR LPM,
CXSD and AOSD for 99.9% of the suspend.

Initially found by
https://github.com/justririll/x1e-sleep/blob/main/modules/el1tmr/el1tmr.c.

Signed-off-by: Anthony Ruhier <aruhier@mailbox.org>
---
Hi,

This patch is needed on Qualcomm X1E laptops (Hamoa) when Linux runs at
EL2 to reach the lower states in s2idle. I am aware that changing the
shutdown behavior of the physical timer unconditionally on every
platforms would not be acceptable.
Marc (maz@) recommended me to send an email here to discuss how this
should be handled upstream.

On my Yoga Slim 7x laptop, PSCI CPU_SUSPEND for the system state
returned within ~5 us, thousands of times per second, and the SoC never
reached DDR LPM or CX collapse. With this patch (added to an ADSP fix,
unreleated to this bug), it reaches DDR LPM, CXSD and AOSD for 99.9% of
the suspend. This makes s2idle using 0.7W before, to 0.18W now.

I guess this should be implemented as a quirk for Hamoa.

For the Qualcomm folks: is this firmware behaviour known, and does it
also apply to other Qualcomm WoA laptops (X1P, Glymor, etc.)?

Thanks,
Anthony
---
 drivers/clocksource/arm_arch_timer.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/drivers/clocksource/arm_arch_timer.c b/drivers/clocksource/arm_arch_timer.c
index cc9a8b399004..6f03670119f6 100644
--- a/drivers/clocksource/arm_arch_timer.c
+++ b/drivers/clocksource/arm_arch_timer.c
@@ -590,11 +590,10 @@ static irqreturn_t arch_timer_handler_phys(int irq, void *dev_id)
 static __always_inline int arch_timer_shutdown(const int access,
 					       struct clock_event_device *clk)
 {
-	unsigned long ctrl;
-
-	ctrl = arch_timer_reg_read_cp15(access, ARCH_TIMER_REG_CTRL);
-	ctrl &= ~ARCH_TIMER_CTRL_ENABLE;
-	arch_timer_reg_write_cp15(access, ARCH_TIMER_REG_CTRL, ctrl);
+	arch_timer_reg_write_cp15(access, ARCH_TIMER_REG_CTRL,
+				  ARCH_TIMER_CTRL_ENABLE | ARCH_TIMER_CTRL_IT_MASK);
+	arch_timer_reg_write_cp15(access, ARCH_TIMER_REG_CVAL,
+				  BIT(arch_counter_get_width() - 1) - 1);
 
 	return 0;
 }

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261122-x1e-arch-timer-park-d0f839ea1688

Best regards,
--  
Anthony Ruhier <aruhier@mailbox.org>

