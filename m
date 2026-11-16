From: Igor Velkov <iav@iav.lv>
Date: Mon, 16 Nov 2026 00:25:03 +0000
Subject: [PATCH v2 4/8] alarmtimer: Register the platform device without a
 parent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-b4-alarmtimer-rtc-priority-v2-4-b2c69721e489@iav.lv>
References: <20261116-b4-alarmtimer-rtc-priority-v2-0-b2c69721e489@iav.lv>
In-Reply-To: <20261116-b4-alarmtimer-rtc-priority-v2-0-b2c69721e489@iav.lv>
To: John Stultz <jstultz@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>
Cc: Stephen Boyd <sboyd@kernel.org>, Miroslav Lichvar <mlichvar@redhat.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4346; i=iav@iav.lv;
 h=from:subject:message-id; bh=tvo0ZSOLDAdXZO/UMf1yW8+MZjzf7553zgNk+6kP7fs=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fBPDJh+4ujz7xBu1Sx3rbbj/Pv9rNcF0cmabp/jr7
 38Zlmxe0lHKwiDGxSArpsgy4ZDGrYwlV//6e5g/gJnDygQyhIGLUwAmUrOakeEbq8eqS3HN0npz
 tfztg3rbpgXHM75vWOZ4mX1DW0PVhPsMv9l5JgWEiPxWWv452OBax6d0e7MCOz/9r79ltGoZvC3
 W8QAA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

alarmtimer registers its platform device as a child of the wakeup RTC, so
the driver core suspends it before the RTC and alarmtimer_suspend() can
program the RTC. A device with one parent cannot be ordered against a
second RTC.

Register the device without a parent once the RTC is taken and add a
device link to the RTC, which keeps the device after the RTC in dpm_list
also when the RTC is moved there later, so it still suspends first.

Add links named after the suspend states, which point to the RTC that
wakes the system from that state. The names are those of
/sys/power/mem_sleep: in /sys/power/state "mem" stands for whichever
state mem_sleep selects, which can be s2idle.

The device moves from under the RTC to /sys/devices/platform, its name
stays alarmtimer.N.auto.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 kernel/time/alarmtimer.c | 45 ++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 38 insertions(+), 7 deletions(-)

diff --git a/kernel/time/alarmtimer.c b/kernel/time/alarmtimer.c
index 066d980fa6d5..4f87df95edcd 100644
--- a/kernel/time/alarmtimer.c
+++ b/kernel/time/alarmtimer.c
@@ -26,6 +26,7 @@
 #include <linux/freezer.h>
 #include <linux/compat.h>
 #include <linux/module.h>
+#include <linux/suspend.h>
 #include <linux/time_namespace.h>
 
 #include "posix-timers.h"
@@ -53,12 +54,14 @@ static struct alarm_base {
 /**
  * struct rtc_wakeup - State for waking the system from suspend on alarms
  * @rtc:		RTC programmed on suspend, NULL if none
+ * @pdev:		Device whose suspend and resume callbacks program the RTC
  * @timer:		RTC timer started on suspend
  * @freezer_expires:	Earliest expiry per alarm type of the clock_nanosleep()
  *			calls which the freezer interrupted, KTIME_MAX if none
  */
 struct rtc_wakeup {
 	struct rtc_device	*rtc;
+	struct platform_device	*pdev;
 	struct rtc_timer	timer;
 	ktime_t			freezer_expires[ALARM_NUMTYPE];
 };
@@ -71,6 +74,16 @@ static DEFINE_SPINLOCK(freezer_lock);
 #endif
 
 #ifdef CONFIG_RTC_CLASS
+/* Suspend state names as in /sys/power/mem_sleep */
+static const char * const alarmtimer_state_names[PM_SUSPEND_MAX] = {
+	[PM_SUSPEND_TO_IDLE]	= "s2idle",
+	[PM_SUSPEND_STANDBY]	= "shallow",
+	[PM_SUSPEND_MEM]	= "deep",
+};
+
+/* Bounds of suspend_state_t as integers for loops, bit masks and indices */
+#define ALARMTIMER_STATE_MIN	((__force int)PM_SUSPEND_MIN)
+#define ALARMTIMER_STATE_MAX	((__force int)PM_SUSPEND_MAX)
 
 /**
  * alarmtimer_has_rtcdev - Check whether an RTC can wake the system for alarms
@@ -83,10 +96,20 @@ bool alarmtimer_has_rtcdev(void)
 }
 EXPORT_SYMBOL_GPL(alarmtimer_has_rtcdev);
 
+/* Show in sysfs which RTC wakes the system from @state */
+static void alarmtimer_link_state(int state, struct device *dev)
+{
+	const char *name = alarmtimer_state_names[state];
+
+	if (sysfs_create_link(&wakeup_ctl.pdev->dev.kobj, &dev->kobj, name))
+		dev_warn(&wakeup_ctl.pdev->dev, "Cannot link %s to %s\n", name, dev_name(dev));
+}
+
 static int alarmtimer_rtc_add_device(struct device *dev)
 {
 	struct rtc_device *rtc = to_rtc_device(dev);
 	struct platform_device *pdev;
+	int state;
 
 	if (wakeup_ctl.rtc)
 		return -EBUSY;
@@ -96,22 +119,30 @@ static int alarmtimer_rtc_add_device(struct device *dev)
 	if (!device_may_wakeup(rtc->dev.parent))
 		return -1;
 
-	pdev = platform_device_register_data(dev, "alarmtimer",
+	if (!try_module_get(rtc->owner))
+		return -1;
+
+	pdev = platform_device_register_data(NULL, "alarmtimer",
 					     PLATFORM_DEVID_AUTO, NULL, 0);
-	if (IS_ERR(pdev))
+	if (IS_ERR(pdev)) {
+		module_put(rtc->owner);
 		return PTR_ERR(pdev);
-
-	device_init_wakeup(&pdev->dev, true);
-
-	if (!try_module_get(rtc->owner)) {
+	}
+	/* Keep the device after the RTC in dpm_list, so it suspends first */
+	if (!device_link_add(&pdev->dev, dev, DL_FLAG_STATELESS)) {
 		platform_device_unregister(pdev);
-		return -1;
+		module_put(rtc->owner);
+		return -ENODEV;
 	}
+	device_init_wakeup(&pdev->dev, true);
+	wakeup_ctl.pdev = pdev;
 
 	WRITE_ONCE(wakeup_ctl.rtc, rtc);
 	/* Hold a reference so it doesn't go away */
 	get_device(dev);
 
+	for (state = ALARMTIMER_STATE_MIN; state < ALARMTIMER_STATE_MAX; state++)
+		alarmtimer_link_state(state, dev);
 	return 0;
 }
 

-- 
2.43.0

