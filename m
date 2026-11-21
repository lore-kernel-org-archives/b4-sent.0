From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Sat, 21 Nov 2026 21:51:29 +0300
Subject: [PATCH v9] watchdog: Add ARM TWD (MPCore private) watchdog driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261121-arm-twd-wdt-v9-1-8118d048cfde@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33OQW7DIBAF0KtErEvFGAZIV71H1QXgIaGq4wpcp
 1XkuxeSjZ1KWX5p3v9zYYVyosJedheWaU4ljaca9k87Fo7udCCe+ppZJzoNApC7PPDp3PNzP3E
 DMWKgKBE9q+IrU0w/17a391su3/6DwtQq2sUxlWnMv9e5WbW7WzOA2jTPigNHJ0EoL7WU8HoYX
 Pp8DuPAWvOMa2u3Fqu1VncahbBk7L3VD6yuNhAGi15h0PLempXtYGtNtcagAaX6ENW/XfvA2vY
 z2b3z5EMUem2XZfkD8wFHSagBAAA=
X-Change-ID: 20261015-arm-twd-wdt-71ff5cef355b
To: linux@roeck-us.net, wim@linux-watchdog.org
Cc: linux-arm-kernel@lists.infradead.org, linux-watchdog@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux@armlinux.org.uk, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795287103; l=35699;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=9U/rNR/MhO5JdMmQrO3M8hRiUnU13xPtSc5hkjyi1GU=;
 b=Xu9xC15cBjlLA4wAWsvSZLhkqkpIG7qwNX8OJe2fXwvMypff0vpg0swpRbw6eRo1GCeN5Qx3a
 a/UCFbJqw47A0JPbz8gjHxMLt5OvjI41Qc1b2hqfW8h0NkbFNWcfNir
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ARM11 MPCore, Cortex-A5 and Cortex-A9 MPCore systems have a watchdog
next to the local timer of every CPU, banked at the same address. The
binding "arm,cortex-a9-twd-wdt" exists, but there has been no driver
since mpcore_wdt was removed in v3.11, among other reasons because it
only ever programmed the CPU that ran the ioctl.

Use the watchdog of CPU0 as the system watchdog: start, stop, ping and
get_timeleft run there through smp_call_function_single(). CPU0 cannot
be taken offline on 32-bit ARM unless the platform allows it, the driver
does not probe then. The watchdogs of the other CPUs are left alone. The
watchdog interrupt is not needed.

Bootloaders such as the one of the Securifi Almond+ start the watchdog
before booting the kernel. A running watchdog is marked WDOG_HW_RUNNING
and taken over with the driver's timeout without being stopped, unless
it runs with a different prescaler: the prescaler cannot be changed in
watchdog mode. Once the watchdog mode is set it can only be left through
the disable register sequence, which is what stop does.

The TWD clock follows the CPU clock on many systems, so rate changes are
followed through a clock notifier, or a CPU frequency transition
notifier when no clock is supplied. If CPU0 lost its watchdog in a deep
idle state it is set up again on CPU PM exit. An atomic expiration time
keeps clock rate changes and CPU idle exit from extending the timeout.
Timeout changes are serialized with the frequency notifiers, and the
expiration time is published before the CPU PM notifier can see the
watchdog as armed.

For system sleep, stop the hardware and save the remaining timeout.
Restore the expiration time from that interval at device resume:
monotonic time can advance during suspend-to-idle and device PM, so
reusing the old absolute deadline could cause an immediate reset before
the core post-resume keepalive. An already expired timeout is not
revived. The core still stops its ping worker and refreshes the deadline
normally with its explicit PM keepalives.

When no clock is supplied, calibrate PERIPHCLK against monotonic time on
CPU0 and use cpufreq to track subsequent rate changes. Use a fixed
calibration reference so repeated transitions do not accumulate rounding
error, and invalidate measurements if a transition races with
calibration. Wait for any transition that began before notifier
registration, whose PRE notification could not have been observed. The
fallback assumes a constant PERIPHCLK-to-CPU clock ratio; platforms with
independently changing dividers need a clock provider. Calibration only
observes an enabled counter and does not stop or reload a running
watchdog. Bound the maximum timeout at the hardware maximum CPU
frequency. Preserve actual clock provider errors, including deferred
probe.

The watchdog is also registered as a restart handler with the default
priority, for systems that have no other way to restart: the CPU that
restarts the system, the only one left running, lets its own watchdog
expire right away.

AI assistance: Codex implemented the cpufreq fallback, this PM fix and
the host regression tests.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
ARM11 MPCore, Cortex-A5 and Cortex-A9 MPCore systems have a watchdog
next to the local timer of every CPU. The binding
"arm,cortex-a9-twd-wdt" (watchdog/arm,twd-wdt.yaml) exists and 15
dts/dtsi files describe the device, but there has been no driver since
mpcore_wdt was removed in v3.11 ("watchdog: delete mpcore_wdt driver").

As discussed on v4, this version uses the watchdog of CPU0 only, as the
system watchdog. CPU0 cannot be taken offline on 32-bit ARM unless the
platform allows it, and the driver does not probe then. The watchdogs of
the other CPUs are not touched.

The driver was written for the Cortina Systems CS75xx / Securifi
Almond+, whose boot loader arms the watchdog of CPU0: the board resets
~300 s after boot unless it is serviced. The driver also registers a
restart handler with the default (last resort) priority, since the
CS75xx platform has no other way to restart.

Before this PM change, the v7 driver was tested on a Securifi Almond+
(Cortex-A9, two CPUs) using its DT-supplied clock with PROVE_LOCKING:
takeover of the running watchdog; watchdog ioctls issued from CPU1;
reducing the timeout from 60 to 30 seconds after 35 seconds without a
ping; keepalives for 60 seconds followed by expiration and a reset;
reboot(2) issued from CPU1 through the restart handler. Both runs
returned to OpenWrt without lockdep warnings. GCC and Clang W=1 builds
and host regression tests of deadline handling also pass. CPU hotplug,
CPU PM and suspend were not tested: the platform has no support for
them. The deadline regression tests simulate time and CPU PM
interleaving; they do not replace testing on hardware with CPU PM.

The v6 changes address the five issues in the review confirmed by
Guenter:
https://lore.kernel.org/all/71aafc99-b3c4-4d4c-b468-086dde709b71@roeck-us.net/

For system sleep, stop the hardware and save the remaining timeout.
Restore the expiration time from that remaining interval at device
resume, before CPU PM can rearm the watchdog. Monotonic time can advance
while the counter is stopped, so retaining the old absolute deadline
could restart it with just one tick before the core post-resume
keepalive. Core PM keepalives still refresh the timeout normally.

When no clock is supplied, calibrate the counter against monotonic time
on CPU0 and use cpufreq transition notifications to track subsequent
rate changes. The fallback requires a cpufreq policy; without CPU_FREQ a
clock is required, and without an available policy probe is deferred.
The fallback assumes PERIPHCLK maintains its calibrated ratio to the CPU
clock; platforms with an independently changing divider need a clock
provider. Calibration does not stop or reload an active watchdog. The
maximum timeout is bounded using the maximum hardware CPU frequency.
Actual clock provider errors, including deferred probe, are preserved.

The fallback is implemented following Guenter's suggestion:
https://lore.kernel.org/all/377b89b7-90a3-41c9-88c4-fd3393055f91@roeck-us.net/
The separate MAINTAINERS entry is retained as preferred in that reply.

For v8's PM change, full ARM GCC vmlinux checks with CPU_FREQ=n and the
driver built in, and Clang vmlinux/module/modpost checks with CPU_FREQ=y
pass. Seventeen deadline/PM regressions and nineteen calibration/cpufreq
regressions exercise actual driver helpers with mocked time, CPU0 calls
and MMIO. The long-suspend regression fails on v7 and passes with the
fix. Hardware system sleep is not available on Almond+, so the changed
suspend/resume path has not been tested on hardware.

For the scoped_guard conversion, the ARM GCC W=1 driver object and Clang
vmlinux/module/modpost checks pass with CPU_FREQ=y. The 23 calibration and
cpufreq host checks use the actual scoped_guard macro from this kernel
with modeled mutex cleanup; the v8 and v9 helpers pass the same cases.

AI assistance: Codex implemented the cpufreq fallback and this PM fix,
and created the host regression tests.
---
Changes in v9:
- use scoped_guard() for the two mutex-protected blocks in cpufreq setup
  (Guenter); keep the first retry check outside the scoped guard and break
  out of the final guard to retry the outer calibration loop
- exercise the actual scoped_guard macro and mutex cleanup in the host
  regression tests, including both validation retry paths
- Review: https://lore.kernel.org/all/5843b48e-0028-4358-bc20-a72742e49591@roeck-us.net/
- Link to v8: https://patch.msgid.link/20261121-arm-twd-wdt-v8-1-8e89abebcf06@gmail.com

Changes in v8:
- save the remaining timeout at device suspend and restore the deadline at
  device resume, avoiding a one-tick reset before the core PM keepalive
  if monotonic time advanced while the hardware counter was stopped
  (sashiko-bot)
- retain core PM keepalive behavior and update the system sleep description
- cover long suspend, frozen timekeeping, expired deadlines, inactive
  watchdogs, repeated resume, subsecond precision and delayed stop completion
  with host regressions
- Report: https://lore.kernel.org/all/sashiko-outbox-226965@kernel.org/
- Link to v7: https://patch.msgid.link/20261121-arm-twd-wdt-v7-1-7757144dcf48@gmail.com

Changes in v7:
- use counter calibration plus cpufreq transition notifications when no
  clock is supplied; retain provider errors and deferred probe
- keep a fixed calibration reference to avoid rounding drift; retry
  calibration if frequency changes while the reference is being measured;
  wait for transitions that began before notifier registration
- bound the fallback maximum timeout at the maximum hardware CPU frequency
- clarify that watchdog core PM keepalives refresh the deadline before
  system suspend and after resume; only the device callbacks retain it
- extend the host regression test to cover these core PM keepalives
- Link to v6: https://patch.msgid.link/20261118-arm-twd-wdt-v6-1-ce5c85b45c63@gmail.com

Changes in v6:
- keep an atomic expiration time so CPU PM cannot combine an old
  keepalive with a new timeout; serialize timeout changes with the clock
  notifier and let the watchdog core perform the timeout-change ping
- publish the expiration time before the armed state for CPU PM
- register cleanup and the CPU PM notifier before watchdog takeover
- preserve the expiration time across suspend/resume, stop the core ping
  worker for suspend and ignore pings while the hardware is suspended
- replace obsolete __MODULE_STRING() with __stringify()
- Link to v5: https://patch.msgid.link/20261118-arm-twd-wdt-v5-1-886265008e78@gmail.com

Changes in v5:
- use the watchdog of CPU0 only instead of the watchdogs of all CPUs,
  which overlapped with the lockup detector (Guenter): no CPU hotplug
  state, start, stop, ping and get_timeleft run on CPU0 through
  smp_call_function_single(); do not probe if CPU0 is hotpluggable
- keep the time of the last keepalive and load the watchdog with the time
  left from it, so a clock rate change or CPU PM exit no longer extends
  the timeout (sashiko-bot)
- serialize the watchdog operations and the clock notifier with a mutex
- stop the watchdog when the driver is removed (sashiko-bot)
- fix the comment on suspend (sashiko-bot)
- ignore clock notifications that do not change the rate
- Link to v4: https://patch.msgid.link/20261114-arm-twd-wdt-v4-1-5a3104b36331@gmail.com

Changes in v4:
- rebase on v7.4-rc1
- sent on its own, split out of "Cortina Systems CS75xx: interrupt
  controller, GPIO, I2C and TWD watchdog"
- do not take cpus_read_lock() in the clock notifier, which can be
  called from CPU hotplug through cpufreq: publish the armed state and
  the rate with WRITE_ONCE() and a full barrier first, then apply them
  with on_each_cpu(), so that a rate change racing with start is never
  missed (sashiko-bot)
- restore the watchdog of a CPU on CPU PM exit when its power domain
  went down in idle (sashiko-bot)
- register the restart handler with the default priority instead of
  128, so that it only runs when nothing else can restart the system
- print the timeout and the clock rate only as debug messages
- Link to v3: https://patch.msgid.link/20261013-b4-cs75xx-s2-v3-0-181bb0d23f4c@gmail.com

Changes in v3:
- follow rate changes of the clock, which on many MPCore systems scales
  with the CPU clock, and restore the watchdog of the boot CPU on resume
  (sashiko-bot)
- Link to v2: https://patch.msgid.link/20261013-b4-cs75xx-s2-v2-0-94f8c0a90cda@gmail.com

Changes in v2:
- do not include <linux/mod_devicetable.h> (Uwe)
- the prescaler cannot be changed in watchdog mode (verified on the
  board), so a watchdog left running by the boot loader with a different
  prescaler is stopped before it is reprogrammed (sashiko-bot)
- Link to v1: https://patch.msgid.link/20261012-b4-cs75xx-s2-v1-0-8a7641b7b79c@gmail.com

To: Wim Van Sebroeck <wim@linux-watchdog.org>
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-kernel@vger.kernel.org
Cc: linux-watchdog@vger.kernel.org
Cc: Russell King <linux@armlinux.org.uk>
Cc: linux-arm-kernel@lists.infradead.org
---
 MAINTAINERS                    |   6 +
 drivers/watchdog/Kconfig       |  15 +
 drivers/watchdog/Makefile      |   1 +
 drivers/watchdog/arm_twd_wdt.c | 684 +++++++++++++++++++++++++++++++++++++++++
 4 files changed, 706 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 93abbb315..245d80c13 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2544,6 +2544,12 @@ T:	git git://git.kernel.org/pub/scm/linux/kernel/git/soc/soc.git
 F:	arch/arm/mach-*/
 F:	arch/arm/plat-*/
 
+ARM TWD WATCHDOG DRIVER
+M:	Fil Dunsky <filipp.dunsky@gmail.com>
+L:	linux-watchdog@vger.kernel.org
+S:	Maintained
+F:	drivers/watchdog/arm_twd_wdt.c
+
 ARM/ACTIONS SEMI ARCHITECTURE
 M:	Andreas Färber <afaerber@suse.de>
 M:	Manivannan Sadhasivam <mani@kernel.org>
diff --git a/drivers/watchdog/Kconfig b/drivers/watchdog/Kconfig
index f7d0a0c2c..326546e24 100644
--- a/drivers/watchdog/Kconfig
+++ b/drivers/watchdog/Kconfig
@@ -465,6 +465,21 @@ config ARM_SP805_WATCHDOG
 	  ARM Primecell SP805 Watchdog timer. This will reboot your system when
 	  the timeout is reached.
 
+config ARM_TWD_WATCHDOG
+	tristate "ARM TWD (MPCore private) Watchdog"
+	depends on HAVE_ARM_TWD || COMPILE_TEST
+	depends on HAS_IOMEM
+	select WATCHDOG_CORE
+	help
+	  Say Y here to include support for the private watchdog found next
+	  to the local (TWD) timer of every CPU in ARM11 MPCore, Cortex-A5
+	  and Cortex-A9 MPCore systems. The watchdog of CPU0 is used as the
+	  system watchdog. A watchdog left running by the bootloader is
+	  taken over.
+
+	  To compile this driver as a module, choose M here: the
+	  module will be called arm_twd_wdt.
+
 config ARM_SBSA_WATCHDOG
 	tristate "ARM SBSA Generic Watchdog"
 	depends on ARM64
diff --git a/drivers/watchdog/Makefile b/drivers/watchdog/Makefile
index 9ac406677..4ff0bced5 100644
--- a/drivers/watchdog/Makefile
+++ b/drivers/watchdog/Makefile
@@ -40,6 +40,7 @@ obj-$(CONFIG_USBPCWATCHDOG) += pcwd_usb.o
 # ARM Architecture
 obj-$(CONFIG_ARM_SP805_WATCHDOG) += sp805_wdt.o
 obj-$(CONFIG_ARM_SBSA_WATCHDOG) += sbsa_gwdt.o
+obj-$(CONFIG_ARM_TWD_WATCHDOG) += arm_twd_wdt.o
 obj-$(CONFIG_ARMADA_37XX_WATCHDOG) += armada_37xx_wdt.o
 obj-$(CONFIG_AIROHA_WATCHDOG) += airoha_wdt.o
 obj-$(CONFIG_ASM9260_WATCHDOG) += asm9260_wdt.o
diff --git a/drivers/watchdog/arm_twd_wdt.c b/drivers/watchdog/arm_twd_wdt.c
new file mode 100644
index 000000000..f83770109
--- /dev/null
+++ b/drivers/watchdog/arm_twd_wdt.c
@@ -0,0 +1,684 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Watchdog driver for the ARM Cortex-A9/A5 and ARM11 MPCore private
+ * (TWD) watchdog
+ *
+ * Every CPU has its own watchdog, banked at the same address, and any of
+ * them resets the system when it expires. The driver uses the watchdog of
+ * CPU0 as the system watchdog and leaves the others alone: CPU0 cannot be
+ * taken offline, so the registers are always reached through it. Once the
+ * watchdog mode bit is set it can only be cleared by writing the disable
+ * sequence to the disable register.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/cleanup.h>
+#include <linux/clk.h>
+#include <linux/cpu.h>
+#include <linux/cpu_pm.h>
+#include <linux/cpufreq.h>
+#include <linux/delay.h>
+#include <linux/io.h>
+#include <linux/ktime.h>
+#include <linux/math64.h>
+#include <linux/minmax.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/platform_device.h>
+#include <linux/pm.h>
+#include <linux/smp.h>
+#include <linux/stringify.h>
+#include <linux/wait.h>
+#include <linux/watchdog.h>
+
+#define TWD_WDT_LOAD		0x00
+#define TWD_WDT_COUNTER		0x04
+#define TWD_WDT_CONTROL		0x08
+#define TWD_WDT_RESET_STATUS	0x10
+#define TWD_WDT_DISABLE		0x14
+
+#define TWD_WDT_CTRL_ENABLE	BIT(0)
+#define TWD_WDT_CTRL_WD_MODE	BIT(3)
+#define TWD_WDT_CTRL_PRESCALER	GENMASK(15, 8)
+
+#define TWD_WDT_RESET_FLAG	BIT(0)
+
+#define TWD_WDT_DISABLE_KEY1	0x12345678
+#define TWD_WDT_DISABLE_KEY2	0x87654321
+
+/* Largest prescaler, the counter clock is the input clock divided by 256 */
+#define TWD_WDT_PRESCALE	255
+#define TWD_WDT_DEFAULT_TIMEOUT	30
+
+/* The CPU whose watchdog is used */
+#define TWD_WDT_CPU		0
+
+static bool nowayout = WATCHDOG_NOWAYOUT;
+module_param(nowayout, bool, 0);
+MODULE_PARM_DESC(nowayout, "Watchdog cannot be stopped once started (default="
+		 __stringify(WATCHDOG_NOWAYOUT) ")");
+
+static unsigned int timeout;
+module_param(timeout, uint, 0);
+MODULE_PARM_DESC(timeout, "Watchdog timeout in seconds");
+
+struct twd_wdt {
+	struct watchdog_device wdd;
+	void __iomem *base;
+	struct notifier_block clk_nb;
+	struct notifier_block cpufreq_nb;
+	/* Fixed calibration reference: avoid rounding drift across transitions. */
+	unsigned long reference_rate;
+	unsigned long max_rate;
+	unsigned int reference_freq;
+	atomic_t freq_changes;
+	bool freq_changing;
+	unsigned long sampled_rate;
+	struct notifier_block pm_nb;
+	/* Serializes the watchdog operations and the frequency notifiers */
+	struct mutex lock;
+	/* Also read by the CPU PM notifier, which cannot take the lock */
+	unsigned long rate;
+	bool armed;
+	/* Expiration time in monotonic ns, also read by the CPU PM notifier */
+	atomic64_t expires;
+	bool resume_armed;
+	/* Remaining monotonic ns while the hardware is stopped for system sleep. */
+	s64 suspend_left;
+	u32 counter;
+	bool running;
+	bool reset;
+};
+
+/*
+ * Counter value for the time left until the watchdog has to expire: the
+ * watchdog is always loaded with it, so neither a clock rate change nor
+ * setting it up again after a CPU power down extends the timeout.
+ */
+static u32 twd_wdt_ticks(struct twd_wdt *wdt)
+{
+	s64 left = atomic64_read(&wdt->expires) - ktime_get_ns();
+	u64 ticks;
+
+	if (left <= 0)
+		return 1;
+
+	ticks = mul_u64_u64_div_u64(READ_ONCE(wdt->rate), left,
+				    (u64)NSEC_PER_SEC * (TWD_WDT_PRESCALE + 1));
+
+	return clamp_t(u64, ticks, 1, U32_MAX);
+}
+
+/* The following run on TWD_WDT_CPU */
+static void twd_wdt_cpu_stop(void *data)
+{
+	struct twd_wdt *wdt = data;
+
+	writel(TWD_WDT_DISABLE_KEY1, wdt->base + TWD_WDT_DISABLE);
+	writel(TWD_WDT_DISABLE_KEY2, wdt->base + TWD_WDT_DISABLE);
+	writel(0, wdt->base + TWD_WDT_CONTROL);
+}
+
+static void twd_wdt_cpu_start(void *data)
+{
+	struct twd_wdt *wdt = data;
+	u32 ctrl = readl(wdt->base + TWD_WDT_CONTROL);
+
+	/*
+	 * In watchdog mode the prescaler cannot be changed, so a watchdog
+	 * started by the bootloader with a different one is stopped first.
+	 */
+	if ((ctrl & TWD_WDT_CTRL_WD_MODE) &&
+	    FIELD_GET(TWD_WDT_CTRL_PRESCALER, ctrl) != TWD_WDT_PRESCALE)
+		twd_wdt_cpu_stop(wdt);
+
+	/*
+	 * Load the counter before enabling, it may still be zero. A watchdog
+	 * that is already running is reloaded and keeps running.
+	 */
+	writel(twd_wdt_ticks(wdt), wdt->base + TWD_WDT_LOAD);
+	writel(FIELD_PREP(TWD_WDT_CTRL_PRESCALER, TWD_WDT_PRESCALE) |
+	       TWD_WDT_CTRL_WD_MODE | TWD_WDT_CTRL_ENABLE,
+	       wdt->base + TWD_WDT_CONTROL);
+}
+
+static void twd_wdt_cpu_ping(void *data)
+{
+	struct twd_wdt *wdt = data;
+
+	/* In watchdog mode a write to the load register reloads the counter */
+	writel(twd_wdt_ticks(wdt), wdt->base + TWD_WDT_LOAD);
+}
+
+static void twd_wdt_cpu_counter(void *data)
+{
+	struct twd_wdt *wdt = data;
+
+	wdt->counter = readl(wdt->base + TWD_WDT_COUNTER);
+}
+
+static void twd_wdt_cpu_probe(void *data)
+{
+	struct twd_wdt *wdt = data;
+	u32 ctrl = readl(wdt->base + TWD_WDT_CONTROL);
+
+	wdt->running = (ctrl & (TWD_WDT_CTRL_WD_MODE | TWD_WDT_CTRL_ENABLE)) ==
+		       (TWD_WDT_CTRL_WD_MODE | TWD_WDT_CTRL_ENABLE);
+
+	if (readl(wdt->base + TWD_WDT_RESET_STATUS) & TWD_WDT_RESET_FLAG) {
+		wdt->reset = true;
+		/* The flag is cleared by writing one */
+		writel(TWD_WDT_RESET_FLAG, wdt->base + TWD_WDT_RESET_STATUS);
+	}
+}
+
+static void twd_wdt_call(struct twd_wdt *wdt, smp_call_func_t func)
+{
+	smp_call_function_single(TWD_WDT_CPU, func, wdt, 1);
+}
+
+/*
+ * Measure PERIPHCLK rather than assuming a particular CPU clock divider.
+ * An active watchdog is only observed, never stopped or reloaded here.
+ * Otherwise temporarily use timer mode without interrupts, restoring the
+ * original registers afterwards. This runs on CPU0 with interrupts disabled.
+ */
+static void twd_wdt_cpu_calibrate(void *data)
+{
+	struct twd_wdt *wdt = data;
+	u32 ctrl = readl(wdt->base + TWD_WDT_CONTROL);
+	u32 load = 0, counter = 0, first, last;
+	bool enabled = ctrl & TWD_WDT_CTRL_ENABLE;
+	u64 start, elapsed, rate;
+	unsigned int divisor = FIELD_GET(TWD_WDT_CTRL_PRESCALER, ctrl) + 1;
+
+	wdt->sampled_rate = 0;
+	if (!enabled) {
+		load = readl(wdt->base + TWD_WDT_LOAD);
+		counter = readl(wdt->base + TWD_WDT_COUNTER);
+		twd_wdt_cpu_stop(wdt);
+		writel(U32_MAX, wdt->base + TWD_WDT_COUNTER);
+		writel(TWD_WDT_CTRL_ENABLE, wdt->base + TWD_WDT_CONTROL);
+		divisor = 1;
+	}
+
+	start = ktime_get_ns();
+	first = readl(wdt->base + TWD_WDT_COUNTER);
+	mdelay(2);
+	last = readl(wdt->base + TWD_WDT_COUNTER);
+	elapsed = ktime_get_ns() - start;
+
+	if (!enabled) {
+		twd_wdt_cpu_stop(wdt);
+		writel(load, wdt->base + TWD_WDT_LOAD);
+		writel(counter, wdt->base + TWD_WDT_COUNTER);
+		writel(ctrl, wdt->base + TWD_WDT_CONTROL);
+	}
+
+	/* Reject a stopped counter, expiration or wrap during measurement. */
+	if (!elapsed || !last || last >= first)
+		return;
+
+	rate = mul_u64_u64_div_u64((u64)(first - last) * divisor,
+				   NSEC_PER_SEC, elapsed);
+	if (rate <= ULONG_MAX)
+		wdt->sampled_rate = rate;
+}
+
+static void twd_wdt_set_armed(struct twd_wdt *wdt, bool armed)
+{
+	guard(mutex)(&wdt->lock);
+
+	if (armed)
+		atomic64_set(&wdt->expires, ktime_get_ns() +
+			     (s64)wdt->wdd.timeout * NSEC_PER_SEC);
+	/* Publish the deadline before the CPU PM notifier can see armed. */
+	smp_store_release(&wdt->armed, armed);
+	twd_wdt_call(wdt, armed ? twd_wdt_cpu_start : twd_wdt_cpu_stop);
+}
+
+static int twd_wdt_start(struct watchdog_device *wdd)
+{
+	twd_wdt_set_armed(watchdog_get_drvdata(wdd), true);
+
+	return 0;
+}
+
+static int twd_wdt_stop(struct watchdog_device *wdd)
+{
+	twd_wdt_set_armed(watchdog_get_drvdata(wdd), false);
+
+	return 0;
+}
+
+static int twd_wdt_ping(struct watchdog_device *wdd)
+{
+	struct twd_wdt *wdt = watchdog_get_drvdata(wdd);
+
+	guard(mutex)(&wdt->lock);
+
+	if (!wdt->armed)
+		return 0;
+
+	atomic64_set(&wdt->expires, ktime_get_ns() +
+		     (s64)wdd->timeout * NSEC_PER_SEC);
+	twd_wdt_call(wdt, twd_wdt_cpu_ping);
+
+	return 0;
+}
+
+static int twd_wdt_set_timeout(struct watchdog_device *wdd, unsigned int t)
+{
+	struct twd_wdt *wdt = watchdog_get_drvdata(wdd);
+
+	guard(mutex)(&wdt->lock);
+
+	wdd->timeout = t;
+	if (wdt->armed)
+		atomic64_set(&wdt->expires, ktime_get_ns() +
+			     (s64)t * NSEC_PER_SEC);
+
+	return 0;
+}
+
+static unsigned int twd_wdt_get_timeleft(struct watchdog_device *wdd)
+{
+	struct twd_wdt *wdt = watchdog_get_drvdata(wdd);
+	u64 ticks;
+
+	guard(mutex)(&wdt->lock);
+
+	twd_wdt_call(wdt, twd_wdt_cpu_counter);
+	ticks = (u64)wdt->counter * (TWD_WDT_PRESCALE + 1);
+
+	return div_u64(ticks, wdt->rate);
+}
+
+/*
+ * The TWD runs from the peripheral clock, which follows the CPU clock. While
+ * the rate goes up, count with the new rate already: the watchdog then just
+ * fires later than asked until the change is done.
+ */
+static int twd_wdt_clk_notify(struct notifier_block *nb, unsigned long event,
+			      void *data)
+{
+	struct twd_wdt *wdt = container_of(nb, struct twd_wdt, clk_nb);
+	struct clk_notifier_data *cnd = data;
+	unsigned long rate;
+
+	switch (event) {
+	case PRE_RATE_CHANGE:
+		if (cnd->new_rate <= cnd->old_rate)
+			return NOTIFY_OK;
+		rate = cnd->new_rate;
+		break;
+	case POST_RATE_CHANGE:
+		rate = cnd->new_rate;
+		break;
+	case ABORT_RATE_CHANGE:
+		rate = cnd->old_rate;
+		break;
+	default:
+		return NOTIFY_DONE;
+	}
+
+	guard(mutex)(&wdt->lock);
+
+	if (!rate || rate == wdt->rate)
+		return NOTIFY_OK;
+
+	WRITE_ONCE(wdt->rate, rate);
+	if (wdt->armed)
+		twd_wdt_call(wdt, twd_wdt_cpu_ping);
+
+	return NOTIFY_OK;
+}
+
+/*
+ * With no clock provider, assume PERIPHCLK keeps the calibrated CPU clock
+ * ratio. Platforms with an independently changing divider need a clock.
+ */
+static int twd_wdt_cpufreq_notify(struct notifier_block *nb,
+				  unsigned long event, void *data)
+{
+	struct twd_wdt *wdt = container_of(nb, struct twd_wdt, cpufreq_nb);
+	struct cpufreq_freqs *freqs = data;
+	unsigned long rate;
+
+	if (!cpumask_test_cpu(TWD_WDT_CPU, freqs->policy->cpus) ||
+	    (event != CPUFREQ_PRECHANGE && event != CPUFREQ_POSTCHANGE))
+		return NOTIFY_DONE;
+
+	/* Also invalidate calibration when this callback is waiting for lock. */
+	atomic_inc(&wdt->freq_changes);
+	guard(mutex)(&wdt->lock);
+
+	wdt->freq_changing = event == CPUFREQ_PRECHANGE;
+	if (!wdt->reference_freq || !freqs->new ||
+	    (event == CPUFREQ_PRECHANGE && freqs->new <= freqs->old))
+		return NOTIFY_OK;
+
+	/* Failed transitions are reported as a second, reverse transition. */
+	rate = mul_u64_u64_div_u64(wdt->reference_rate, freqs->new,
+				   wdt->reference_freq);
+	if (!rate || rate == wdt->rate)
+		return NOTIFY_OK;
+
+	WRITE_ONCE(wdt->rate, rate);
+	if (wdt->armed)
+		twd_wdt_call(wdt, twd_wdt_cpu_ping);
+
+	return NOTIFY_OK;
+}
+
+static void twd_wdt_remove_cpufreq_notifier(void *data)
+{
+	struct twd_wdt *wdt = data;
+
+	cpufreq_unregister_notifier(&wdt->cpufreq_nb,
+				    CPUFREQ_TRANSITION_NOTIFIER);
+}
+
+static int twd_wdt_init_cpufreq(struct device *dev, struct twd_wdt *wdt)
+{
+	struct cpufreq_policy *policy;
+	u64 max_rate;
+	unsigned long rate;
+	unsigned int freq, max_freq;
+	int ret, seq, attempt;
+	bool retry;
+
+	if (!IS_ENABLED(CONFIG_CPU_FREQ))
+		return dev_err_probe(dev, -EOPNOTSUPP,
+				     "no clock and CPU frequency support is disabled\n");
+
+	wdt->cpufreq_nb.notifier_call = twd_wdt_cpufreq_notify;
+	ret = cpufreq_register_notifier(&wdt->cpufreq_nb,
+					CPUFREQ_TRANSITION_NOTIFIER);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to register CPU frequency notifier\n");
+
+	ret = devm_add_action_or_reset(dev, twd_wdt_remove_cpufreq_notifier, wdt);
+	if (ret)
+		return ret;
+
+	/* A transition may have begun before we registered and missed PRE. */
+	policy = cpufreq_cpu_get(TWD_WDT_CPU);
+	if (!policy)
+		return dev_err_probe(dev, -EPROBE_DEFER,
+				     "CPU frequency policy is unavailable\n");
+	wait_event(policy->transition_wait, !READ_ONCE(policy->transition_ongoing));
+	cpufreq_cpu_put(policy);
+
+	max_freq = cpufreq_get_hw_max_freq(TWD_WDT_CPU);
+	if (!max_freq)
+		return dev_err_probe(dev, -EPROBE_DEFER,
+				     "maximum CPU frequency is unavailable\n");
+
+	for (attempt = 0; attempt < 3; attempt++) {
+		seq = atomic_read(&wdt->freq_changes);
+		/* May notify transitions itself: never call with lock held. */
+		freq = cpufreq_get(TWD_WDT_CPU);
+		if (!freq)
+			return dev_err_probe(dev, -EPROBE_DEFER,
+					     "CPU frequency is unavailable\n");
+		scoped_guard(mutex, &wdt->lock) {
+			retry = wdt->freq_changing || seq != atomic_read(&wdt->freq_changes);
+			if (retry)
+				break;
+			twd_wdt_call(wdt, twd_wdt_cpu_calibrate);
+			rate = wdt->sampled_rate;
+		}
+		if (retry)
+			continue;
+		if (!rate)
+			return dev_err_probe(dev, -EINVAL, "failed to calibrate watchdog clock\n");
+		if (cpufreq_get(TWD_WDT_CPU) != freq)
+			continue;
+		scoped_guard(mutex, &wdt->lock) {
+			if (wdt->freq_changing || seq != atomic_read(&wdt->freq_changes))
+				break;
+			/* Bound the advertised timeout at the highest CPU rate. */
+			max_rate = mul_u64_u64_div_u64(rate, max(max_freq, freq), freq);
+			if (max_rate >= ULONG_MAX)
+				return dev_err_probe(dev, -EINVAL,
+						     "watchdog clock rate is too high\n");
+			wdt->max_rate = max_rate + 1;
+			wdt->reference_freq = freq;
+			wdt->reference_rate = rate;
+			WRITE_ONCE(wdt->rate, rate);
+			return 0;
+		}
+	}
+
+	return dev_err_probe(dev, -EPROBE_DEFER,
+			     "CPU frequency changed during calibration\n");
+}
+
+/*
+ * A CPU whose power domain was turned off in idle comes back with its
+ * watchdog stopped. Only then set it up again: reloading a watchdog that
+ * kept running would ping it on every idle exit.
+ */
+static int twd_wdt_cpu_pm_notify(struct notifier_block *nb,
+				 unsigned long action, void *data)
+{
+	struct twd_wdt *wdt = container_of(nb, struct twd_wdt, pm_nb);
+
+	if (action != CPU_PM_EXIT && action != CPU_PM_ENTER_FAILED)
+		return NOTIFY_DONE;
+
+	/* Pairs with the release stores that publish the expiration time. */
+	if (smp_processor_id() == TWD_WDT_CPU && smp_load_acquire(&wdt->armed) &&
+	    !(readl(wdt->base + TWD_WDT_CONTROL) & TWD_WDT_CTRL_WD_MODE))
+		twd_wdt_cpu_start(wdt);
+
+	return NOTIFY_OK;
+}
+
+static int twd_wdt_restart(struct watchdog_device *wdd, unsigned long action,
+			   void *data)
+{
+	struct twd_wdt *wdt = watchdog_get_drvdata(wdd);
+
+	/*
+	 * Only this CPU is still running, and it may not be TWD_WDT_CPU. The
+	 * watchdog of any CPU resets the system: let its own expire right away.
+	 */
+	writel(1, wdt->base + TWD_WDT_LOAD);
+	writel(TWD_WDT_CTRL_WD_MODE | TWD_WDT_CTRL_ENABLE,
+	       wdt->base + TWD_WDT_CONTROL);
+	mdelay(500);
+
+	return 0;
+}
+
+static const struct watchdog_ops twd_wdt_ops = {
+	.owner		= THIS_MODULE,
+	.start		= twd_wdt_start,
+	.stop		= twd_wdt_stop,
+	.ping		= twd_wdt_ping,
+	.set_timeout	= twd_wdt_set_timeout,
+	.get_timeleft	= twd_wdt_get_timeleft,
+	.restart	= twd_wdt_restart,
+};
+
+static const struct watchdog_info twd_wdt_info = {
+	.options	= WDIOF_SETTIMEOUT | WDIOF_KEEPALIVEPING |
+			  WDIOF_MAGICCLOSE | WDIOF_CARDRESET,
+	.identity	= "ARM TWD watchdog",
+};
+
+/* A watchdog left running would not be pinged any more */
+static void twd_wdt_disable(void *data)
+{
+	struct twd_wdt *wdt = data;
+
+	twd_wdt_set_armed(wdt, false);
+}
+
+static void twd_wdt_remove_pm_notifier(void *data)
+{
+	struct twd_wdt *wdt = data;
+
+	cpu_pm_unregister_notifier(&wdt->pm_nb);
+}
+
+static int twd_wdt_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct twd_wdt *wdt;
+	struct clk *clk;
+	int ret;
+
+	if (cpu_is_hotpluggable(TWD_WDT_CPU))
+		return dev_err_probe(dev, -EOPNOTSUPP,
+				     "CPU%d can be taken offline\n", TWD_WDT_CPU);
+
+	wdt = devm_kzalloc(dev, sizeof(*wdt), GFP_KERNEL);
+	if (!wdt)
+		return -ENOMEM;
+
+	ret = devm_mutex_init(dev, &wdt->lock);
+	if (ret)
+		return ret;
+
+	wdt->base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(wdt->base))
+		return PTR_ERR(wdt->base);
+
+	clk = devm_clk_get_optional_enabled(dev, NULL);
+	if (IS_ERR(clk))
+		return dev_err_probe(dev, PTR_ERR(clk), "failed to get clock\n");
+
+	if (clk) {
+		wdt->rate = clk_get_rate(clk);
+		if (!wdt->rate)
+			return dev_err_probe(dev, -EINVAL, "clock rate is zero\n");
+
+		wdt->max_rate = wdt->rate;
+		wdt->clk_nb.notifier_call = twd_wdt_clk_notify;
+		ret = devm_clk_notifier_register(dev, clk, &wdt->clk_nb);
+		if (ret)
+			return dev_err_probe(dev, ret, "failed to register clock notifier\n");
+	} else {
+		ret = twd_wdt_init_cpufreq(dev, wdt);
+		if (ret)
+			return ret;
+	}
+	platform_set_drvdata(pdev, wdt);
+
+	wdt->wdd.info = &twd_wdt_info;
+	wdt->wdd.ops = &twd_wdt_ops;
+	wdt->wdd.parent = dev;
+	wdt->wdd.min_timeout = 1;
+	wdt->wdd.max_timeout = div_u64((u64)U32_MAX * (TWD_WDT_PRESCALE + 1),
+				       wdt->max_rate);
+	wdt->wdd.timeout = min_t(unsigned int, TWD_WDT_DEFAULT_TIMEOUT,
+				 wdt->wdd.max_timeout);
+	watchdog_init_timeout(&wdt->wdd, timeout, dev);
+	watchdog_set_nowayout(&wdt->wdd, nowayout);
+	watchdog_stop_on_reboot(&wdt->wdd);
+	watchdog_stop_on_unregister(&wdt->wdd);
+	watchdog_stop_ping_on_suspend(&wdt->wdd);
+	watchdog_set_drvdata(&wdt->wdd, wdt);
+
+	twd_wdt_call(wdt, twd_wdt_cpu_probe);
+	if (wdt->reset) {
+		wdt->wdd.bootstatus = WDIOF_CARDRESET;
+		dev_info(dev, "last reset caused by the watchdog\n");
+	}
+
+	wdt->pm_nb.notifier_call = twd_wdt_cpu_pm_notify;
+	ret = cpu_pm_register_notifier(&wdt->pm_nb);
+	if (ret)
+		return ret;
+
+	ret = devm_add_action_or_reset(dev, twd_wdt_remove_pm_notifier, wdt);
+	if (ret)
+		return ret;
+
+	ret = devm_add_action_or_reset(dev, twd_wdt_disable, wdt);
+	if (ret)
+		return ret;
+
+	if (wdt->running) {
+		/* Left running by the bootloader: take it over without a stop */
+		dev_info(dev, "running, taking over\n");
+		twd_wdt_start(&wdt->wdd);
+		set_bit(WDOG_HW_RUNNING, &wdt->wdd.status);
+	}
+
+	ret = devm_watchdog_register_device(dev, &wdt->wdd);
+	if (ret)
+		return ret;
+
+	dev_dbg(dev, "timeout %u s (max %u s), clock %lu Hz\n",
+		wdt->wdd.timeout, wdt->wdd.max_timeout, wdt->rate);
+
+	return 0;
+}
+
+static const struct of_device_id twd_wdt_of_match[] = {
+	{ .compatible = "arm,arm11mp-twd-wdt" },
+	{ .compatible = "arm,cortex-a5-twd-wdt" },
+	{ .compatible = "arm,cortex-a9-twd-wdt" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, twd_wdt_of_match);
+
+/*
+ * Stop the hardware for system sleep while the core stops its ping worker.
+ * Pause the remaining timeout while the hardware is stopped: monotonic time
+ * can advance during system sleep and device PM. Core PM keepalives still
+ * refresh the timeout before suspend and after resume.
+ */
+static int twd_wdt_suspend(struct device *dev)
+{
+	struct twd_wdt *wdt = dev_get_drvdata(dev);
+
+	guard(mutex)(&wdt->lock);
+
+	wdt->resume_armed = wdt->armed;
+	/* Keep CPU PM from restoring the watchdog while it is suspended. */
+	smp_store_release(&wdt->armed, false);
+	if (wdt->resume_armed) {
+		wdt->suspend_left = atomic64_read(&wdt->expires) - ktime_get_ns();
+		twd_wdt_call(wdt, twd_wdt_cpu_stop);
+	}
+
+	return 0;
+}
+
+static int twd_wdt_resume(struct device *dev)
+{
+	struct twd_wdt *wdt = dev_get_drvdata(dev);
+
+	guard(mutex)(&wdt->lock);
+
+	if (wdt->resume_armed) {
+		atomic64_set(&wdt->expires, ktime_get_ns() + wdt->suspend_left);
+		/* Publish the restored deadline before CPU PM can rearm it. */
+		smp_store_release(&wdt->armed, true);
+		twd_wdt_call(wdt, twd_wdt_cpu_start);
+		wdt->resume_armed = false;
+	}
+
+	return 0;
+}
+
+static DEFINE_SIMPLE_DEV_PM_OPS(twd_wdt_pm_ops, twd_wdt_suspend, twd_wdt_resume);
+
+static struct platform_driver twd_wdt_driver = {
+	.probe = twd_wdt_probe,
+	.driver = {
+		.name = "arm-twd-wdt",
+		.of_match_table = twd_wdt_of_match,
+		.pm = pm_sleep_ptr(&twd_wdt_pm_ops),
+	},
+};
+module_platform_driver(twd_wdt_driver);
+
+MODULE_DESCRIPTION("ARM TWD (MPCore private) watchdog driver");
+MODULE_LICENSE("GPL");

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261015-arm-twd-wdt-71ff5cef355b

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

