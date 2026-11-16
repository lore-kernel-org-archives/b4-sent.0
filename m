From: Igor Velkov <iav@iav.lv>
Date: Mon, 16 Nov 2026 00:25:00 +0000
Subject: [PATCH v2 1/8] alarmtimer: Replace alarmtimer_get_rtcdev() with
 alarmtimer_has_rtcdev()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-b4-alarmtimer-rtc-priority-v2-1-b2c69721e489@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4917; i=iav@iav.lv;
 h=from:subject:message-id; bh=f68xLwZpTjZGNfu+rVHvQZiRfGedR9updFcLDrGikhA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fONvcPx+xR396dn2Hta1Fl8k/SyWs6f/maqinT5ls
 sue1WoFHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAin/cz/DNVqtTRt52s+l7p
 6UPWRkdh5sztfyI2p5+wjp+28wPTfS1Ghq699v9k7011MdlwQbFzvtl75nccKlU6wsGandckpSR
 3MwAA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

alarmtimer_get_rtcdev() returns the wakeup RTC without taking a reference.
Apart from alarmtimer_suspend() and alarmtimer_resume(), its callers only
test the result for NULL: the alarm clock functions to tell whether alarm
clocks are supported, and charger-manager to decide whether to set up its
alarm.

A later patch lets a different RTC wake the system from each suspend
state, so there is no single RTC to return.

Provide alarmtimer_has_rtcdev() for these tests and read rtcdev directly
in alarmtimer_suspend() and alarmtimer_resume().

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/power/supply/charger-manager.c |  2 +-
 include/linux/alarmtimer.h             |  7 ++-----
 kernel/time/alarmtimer.c               | 24 ++++++++++++------------
 3 files changed, 15 insertions(+), 18 deletions(-)

diff --git a/drivers/power/supply/charger-manager.c b/drivers/power/supply/charger-manager.c
index 8e8c5109401a..754ff4b3de1a 100644
--- a/drivers/power/supply/charger-manager.c
+++ b/drivers/power/supply/charger-manager.c
@@ -1456,7 +1456,7 @@ static int charger_manager_probe(struct platform_device *pdev)
 	psy_cfg.drv_data = cm;
 
 	/* Initialize alarm timer */
-	if (alarmtimer_get_rtcdev()) {
+	if (alarmtimer_has_rtcdev()) {
 		cm_timer = devm_kzalloc(cm->dev, sizeof(*cm_timer), GFP_KERNEL);
 		if (!cm_timer)
 			return -ENOMEM;
diff --git a/include/linux/alarmtimer.h b/include/linux/alarmtimer.h
index 2014288ca2f4..3dd6d8762a73 100644
--- a/include/linux/alarmtimer.h
+++ b/include/linux/alarmtimer.h
@@ -6,8 +6,6 @@
 #include <linux/hrtimer.h>
 #include <linux/timerqueue.h>
 
-struct rtc_device;
-
 enum alarmtimer_type {
 	ALARM_REALTIME,
 	ALARM_BOOTTIME,
@@ -58,10 +56,9 @@ u64 alarm_forward_now(struct alarm *alarm, ktime_t interval);
 ktime_t alarm_expires_remaining(const struct alarm *alarm);
 
 #ifdef CONFIG_RTC_CLASS
-/* Provide way to access the rtc device being used by alarmtimers */
-struct rtc_device *alarmtimer_get_rtcdev(void);
+bool alarmtimer_has_rtcdev(void);
 #else
-static inline struct rtc_device *alarmtimer_get_rtcdev(void) { return NULL; }
+static inline bool alarmtimer_has_rtcdev(void) { return false; }
 #endif
 
 #endif
diff --git a/kernel/time/alarmtimer.c b/kernel/time/alarmtimer.c
index ecf8c89f7eaf..6c663f7d93c2 100644
--- a/kernel/time/alarmtimer.c
+++ b/kernel/time/alarmtimer.c
@@ -63,15 +63,15 @@ static struct rtc_timer		rtctimer;
 static struct rtc_device	*rtcdev;
 
 /**
- * alarmtimer_get_rtcdev - Return selected rtcdevice
+ * alarmtimer_has_rtcdev - Check whether an RTC can wake the system for alarms
  *
- * This function returns the rtc device to use for wakealarms.
+ * Return: True when alarmtimer has an RTC to program on suspend
  */
-struct rtc_device *alarmtimer_get_rtcdev(void)
+bool alarmtimer_has_rtcdev(void)
 {
-	return READ_ONCE(rtcdev);
+	return !!READ_ONCE(rtcdev);
 }
-EXPORT_SYMBOL_GPL(alarmtimer_get_rtcdev);
+EXPORT_SYMBOL_GPL(alarmtimer_has_rtcdev);
 
 static int alarmtimer_rtc_add_device(struct device *dev)
 {
@@ -221,7 +221,7 @@ static int alarmtimer_suspend(struct device *dev)
 		freezer_delta = 0;
 	}
 
-	rtc = alarmtimer_get_rtcdev();
+	rtc = READ_ONCE(rtcdev);
 	/* If we have no rtcdev, just return */
 	if (!rtc)
 		return 0;
@@ -285,7 +285,7 @@ static int alarmtimer_resume(struct device *dev)
 {
 	struct rtc_device *rtc;
 
-	rtc = alarmtimer_get_rtcdev();
+	rtc = READ_ONCE(rtcdev);
 	if (rtc)
 		rtc_timer_cancel(rtc, &rtctimer);
 	return 0;
@@ -591,7 +591,7 @@ static bool alarm_timer_arm(struct k_itimer *timr, ktime_t expires,
  */
 static int alarm_clock_getres(const clockid_t which_clock, struct timespec64 *tp)
 {
-	if (!alarmtimer_get_rtcdev())
+	if (!alarmtimer_has_rtcdev())
 		return -EINVAL;
 
 	tp->tv_sec = 0;
@@ -610,7 +610,7 @@ static int alarm_clock_get_timespec(clockid_t which_clock, struct timespec64 *tp
 {
 	struct alarm_base *base = &alarm_bases[clock2alarm(which_clock)];
 
-	if (!alarmtimer_get_rtcdev())
+	if (!alarmtimer_has_rtcdev())
 		return -EINVAL;
 
 	base->get_timespec(tp);
@@ -628,7 +628,7 @@ static ktime_t alarm_clock_get_ktime(clockid_t which_clock)
 {
 	struct alarm_base *base = &alarm_bases[clock2alarm(which_clock)];
 
-	if (!alarmtimer_get_rtcdev())
+	if (!alarmtimer_has_rtcdev())
 		return -EINVAL;
 
 	return base->get_ktime();
@@ -644,7 +644,7 @@ static int alarm_timer_create(struct k_itimer *new_timer)
 {
 	enum  alarmtimer_type type;
 
-	if (!alarmtimer_get_rtcdev())
+	if (!alarmtimer_has_rtcdev())
 		return -EOPNOTSUPP;
 
 	if (!capable(CAP_WAKE_ALARM))
@@ -763,7 +763,7 @@ static int alarm_timer_nsleep(const clockid_t which_clock, int flags,
 	ktime_t exp;
 	int ret;
 
-	if (!alarmtimer_get_rtcdev())
+	if (!alarmtimer_has_rtcdev())
 		return -EOPNOTSUPP;
 
 	if (flags & ~TIMER_ABSTIME)

-- 
2.43.0

