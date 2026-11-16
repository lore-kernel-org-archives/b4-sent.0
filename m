From: Igor Velkov <iav@iav.lv>
Date: Mon, 16 Nov 2026 00:25:04 +0000
Subject: [PATCH v2 5/8] alarmtimer: Keep an RTC per suspend state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-b4-alarmtimer-rtc-priority-v2-5-b2c69721e489@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=7184; i=iav@iav.lv;
 h=from:subject:message-id; bh=ZWo/vxs5kO/dXhhsgIzXckOCUVT7Q8k18pF2QbKzZsc=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fBPjMlbcLQz16A60Nu1h2+PHu0Y2QLp1mors8aLdU
 wJO+E7qKGVhEONikBVTZJlwSONWxpKrf/09zB/AzGFlAhnCwMUpABPJ4mdkmMP6cIHDbe2ditN0
 9wWfnj8tS3ifYod0U35yquzVwL0mJxj+mZjOfrBg923LXebrX12ubuj+K8O/7ofhDg7tHTwf8lb
 XcAMA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

alarmtimer takes the first RTC that has an alarm and a wakeup capable
parent and programs it whatever the suspend state. Which RTC wakes the
system can depend on the state: on ODROID-HC4, meson-vrtc is a register
the firmware reads when the application processors suspend, with no
interrupt in Linux, so it wakes the board from deep sleep only, while the
pcf8563 wakes it from s2idle.

Keep an RTC per suspend state instead. An RTC takes the states from which
its alarm wakes the system, minus those an earlier RTC took, and is
refused when none is left. For now every RTC is taken to wake the system
from all states, so the first RTC takes all of them, as before.

Link the platform device to each RTC taken, so it suspends before all of
them. alarmtimer_suspend() programs the RTC of the target state; once an
RTC can be limited to some states, it rejects the suspend when an alarm
is pending and no RTC wakes the system from that state.
alarmtimer_resume() cancels the timer on the RTC it was started on, so
alarmtimer_suspend() no longer cancels it before starting it.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 kernel/time/alarmtimer.c | 84 +++++++++++++++++++++++++++++++-----------------
 1 file changed, 55 insertions(+), 29 deletions(-)

diff --git a/kernel/time/alarmtimer.c b/kernel/time/alarmtimer.c
index 4f87df95edcd..4153cce182a4 100644
--- a/kernel/time/alarmtimer.c
+++ b/kernel/time/alarmtimer.c
@@ -53,16 +53,20 @@ static struct alarm_base {
 #if defined(CONFIG_POSIX_TIMERS) || defined(CONFIG_RTC_CLASS)
 /**
  * struct rtc_wakeup - State for waking the system from suspend on alarms
- * @rtc:		RTC programmed on suspend, NULL if none
+ * @rtc:		RTC per suspend state, NULL if none wakes the system from it
+ * @active_rtc:		RTC on which @timer is started, NULL if none
  * @pdev:		Device whose suspend and resume callbacks program the RTC
  * @timer:		RTC timer started on suspend
+ * @assigned:		Mask of the suspend states which have an RTC
  * @freezer_expires:	Earliest expiry per alarm type of the clock_nanosleep()
  *			calls which the freezer interrupted, KTIME_MAX if none
  */
 struct rtc_wakeup {
-	struct rtc_device	*rtc;
+	struct rtc_device	*rtc[PM_SUSPEND_MAX];
+	struct rtc_device	*active_rtc;
 	struct platform_device	*pdev;
 	struct rtc_timer	timer;
+	unsigned long		assigned;
 	ktime_t			freezer_expires[ALARM_NUMTYPE];
 };
 
@@ -85,6 +89,8 @@ static const char * const alarmtimer_state_names[PM_SUSPEND_MAX] = {
 #define ALARMTIMER_STATE_MIN	((__force int)PM_SUSPEND_MIN)
 #define ALARMTIMER_STATE_MAX	((__force int)PM_SUSPEND_MAX)
 
+#define ALARMTIMER_STATES_ALL	GENMASK(ALARMTIMER_STATE_MAX - 1, ALARMTIMER_STATE_MIN)
+
 /**
  * alarmtimer_has_rtcdev - Check whether an RTC can wake the system for alarms
  *
@@ -92,7 +98,7 @@ static const char * const alarmtimer_state_names[PM_SUSPEND_MAX] = {
  */
 bool alarmtimer_has_rtcdev(void)
 {
-	return !!READ_ONCE(wakeup_ctl.rtc);
+	return !!READ_ONCE(wakeup_ctl.assigned);
 }
 EXPORT_SYMBOL_GPL(alarmtimer_has_rtcdev);
 
@@ -105,44 +111,61 @@ static void alarmtimer_link_state(int state, struct device *dev)
 		dev_warn(&wakeup_ctl.pdev->dev, "Cannot link %s to %s\n", name, dev_name(dev));
 }
 
+/* Suspend states from which an alarm of the RTC on @dev wakes the system */
+static unsigned long alarmtimer_wakeup_states(struct device *dev)
+{
+	return ALARMTIMER_STATES_ALL;
+}
+
 static int alarmtimer_rtc_add_device(struct device *dev)
 {
 	struct rtc_device *rtc = to_rtc_device(dev);
 	struct platform_device *pdev;
+	unsigned long states;
 	int state;
 
-	if (wakeup_ctl.rtc)
-		return -EBUSY;
-
 	if (!test_bit(RTC_FEATURE_ALARM, rtc->features))
 		return -1;
 	if (!device_may_wakeup(rtc->dev.parent))
 		return -1;
 
+	/* The first RTC for a suspend state wakes the system from it */
+	states = alarmtimer_wakeup_states(rtc->dev.parent) & ~wakeup_ctl.assigned;
+	if (!states)
+		return -EBUSY;
+
 	if (!try_module_get(rtc->owner))
 		return -1;
 
-	pdev = platform_device_register_data(NULL, "alarmtimer",
-					     PLATFORM_DEVID_AUTO, NULL, 0);
-	if (IS_ERR(pdev)) {
-		module_put(rtc->owner);
-		return PTR_ERR(pdev);
+	pdev = wakeup_ctl.pdev;
+	if (!pdev) {
+		pdev = platform_device_register_data(NULL, "alarmtimer",
+						     PLATFORM_DEVID_AUTO, NULL, 0);
+		if (IS_ERR(pdev)) {
+			module_put(rtc->owner);
+			return PTR_ERR(pdev);
+		}
 	}
 	/* Keep the device after the RTC in dpm_list, so it suspends first */
 	if (!device_link_add(&pdev->dev, dev, DL_FLAG_STATELESS)) {
-		platform_device_unregister(pdev);
+		if (pdev != wakeup_ctl.pdev)
+			platform_device_unregister(pdev);
 		module_put(rtc->owner);
 		return -ENODEV;
 	}
-	device_init_wakeup(&pdev->dev, true);
-	wakeup_ctl.pdev = pdev;
+	if (!wakeup_ctl.pdev) {
+		device_init_wakeup(&pdev->dev, true);
+		wakeup_ctl.pdev = pdev;
+	}
 
-	WRITE_ONCE(wakeup_ctl.rtc, rtc);
 	/* Hold a reference so it doesn't go away */
 	get_device(dev);
 
-	for (state = ALARMTIMER_STATE_MIN; state < ALARMTIMER_STATE_MAX; state++)
+	for_each_set_bit(state, &states, ALARMTIMER_STATE_MAX) {
+		wakeup_ctl.rtc[state] = rtc;
 		alarmtimer_link_state(state, dev);
+	}
+	WRITE_ONCE(wakeup_ctl.assigned, wakeup_ctl.assigned | states);
 	return 0;
 }
 
@@ -255,11 +278,6 @@ static int alarmtimer_suspend(struct device *dev)
 	int i, ret, type = 0;
 	struct rtc_time tm;
 
-	rtc = READ_ONCE(wakeup_ctl.rtc);
-	/* If we have no rtcdev, just return */
-	if (!rtc)
-		return 0;
-
 	/* Find the soonest timer to expire, frozen clock_nanosleep() included */
 	for (i = 0; i < ALARM_NUMTYPE; i++) {
 		struct alarm_base *base = &alarm_bases[i];
@@ -293,6 +311,13 @@ static int alarmtimer_suspend(struct device *dev)
 	if (min == KTIME_MAX)
 		return 0;
 
+	/* No RTC wakes the system from this state for the pending alarm */
+	rtc = wakeup_ctl.rtc[(__force int)pm_suspend_target_state];
+	if (!rtc) {
+		pm_wakeup_event(dev, MSEC_PER_SEC);
+		return -EOPNOTSUPP;
+	}
+
 	if (ktime_to_ns(min) < 2 * NSEC_PER_SEC) {
 		pm_wakeup_event(dev, 2 * MSEC_PER_SEC);
 		return -EBUSY;
@@ -301,7 +326,6 @@ static int alarmtimer_suspend(struct device *dev)
 	trace_alarmtimer_suspend(expires, type);
 
 	/* Setup an rtc timer to fire that far in the future */
-	rtc_timer_cancel(rtc, &wakeup_ctl.timer);
 	rtc_read_time(rtc, &tm);
 	now = rtc_tm_to_ktime(tm);
 
@@ -319,18 +343,20 @@ static int alarmtimer_suspend(struct device *dev)
 
 	/* Set alarm, if in the past reject suspend briefly to handle */
 	ret = rtc_timer_start(rtc, &wakeup_ctl.timer, now, 0);
-	if (ret < 0)
+	if (ret < 0) {
 		pm_wakeup_event(dev, MSEC_PER_SEC);
-	return ret;
+		return ret;
+	}
+	wakeup_ctl.active_rtc = rtc;
+	return 0;
 }
 
 static int alarmtimer_resume(struct device *dev)
 {
-	struct rtc_device *rtc;
-
-	rtc = READ_ONCE(wakeup_ctl.rtc);
-	if (rtc)
-		rtc_timer_cancel(rtc, &wakeup_ctl.timer);
+	if (wakeup_ctl.active_rtc) {
+		rtc_timer_cancel(wakeup_ctl.active_rtc, &wakeup_ctl.timer);
+		wakeup_ctl.active_rtc = NULL;
+	}
 	return 0;
 }
 

-- 
2.43.0

