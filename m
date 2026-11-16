From: Igor Velkov <iav@iav.lv>
Date: Mon, 16 Nov 2026 00:25:01 +0000
Subject: [PATCH v2 2/8] alarmtimer: Move the wakeup state into struct
 rtc_wakeup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-b4-alarmtimer-rtc-priority-v2-2-b2c69721e489@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4962; i=iav@iav.lv;
 h=from:subject:message-id; bh=R5at3LK7fTK6K4LRahVDuBX7FkZ6ca0VBOT54AfqeeQ=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fBPEOnTfLOquEeKTYs67HFBV7zTvVWrJtoPnHBhvn
 jW5u2hmRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZgI+0pGhj8p03O2vw/+93NG
 +pXfK6ZEK+QGiz/o6li77dekmZ18U2oZGVoSz94IVDOTlN+tVrBsvcVqtl/T/t06YhG98KPdJZv
 THxkA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RTC and the RTC timer which alarmtimer programs on suspend and the
record of the clock_nanosleep() call the freezer interrupted are separate
static variables.

Collect them in one struct to prepare for an RTC per suspend state. No
functional change.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 kernel/time/alarmtimer.c | 60 +++++++++++++++++++++++++++++-------------------
 1 file changed, 36 insertions(+), 24 deletions(-)

diff --git a/kernel/time/alarmtimer.c b/kernel/time/alarmtimer.c
index 6c663f7d93c2..35630f0ff566 100644
--- a/kernel/time/alarmtimer.c
+++ b/kernel/time/alarmtimer.c
@@ -50,17 +50,29 @@ static struct alarm_base {
 } alarm_bases[ALARM_NUMTYPE];
 
 #if defined(CONFIG_POSIX_TIMERS) || defined(CONFIG_RTC_CLASS)
-/* freezer information to handle clock_nanosleep triggered wakeups */
-static enum alarmtimer_type freezer_alarmtype;
-static ktime_t freezer_expires;
-static ktime_t freezer_delta;
+/**
+ * struct rtc_wakeup - State for waking the system from suspend on alarms
+ * @rtc:		RTC programmed on suspend, NULL if none
+ * @timer:		RTC timer started on suspend
+ * @freezer_delta:	Least remaining time of the clock_nanosleep() calls
+ *			which the freezer interrupted, 0 if none
+ * @freezer_expires:	Expiry of that call
+ * @freezer_type:	Alarm type of that call
+ */
+struct rtc_wakeup {
+	struct rtc_device	*rtc;
+	struct rtc_timer	timer;
+	ktime_t			freezer_delta;
+	ktime_t			freezer_expires;
+	enum alarmtimer_type	freezer_type;
+};
+
+static struct rtc_wakeup wakeup_ctl;
+
 static DEFINE_SPINLOCK(freezer_delta_lock);
 #endif
 
 #ifdef CONFIG_RTC_CLASS
-/* rtc timer and device for setting alarm wakeups at suspend */
-static struct rtc_timer		rtctimer;
-static struct rtc_device	*rtcdev;
 
 /**
  * alarmtimer_has_rtcdev - Check whether an RTC can wake the system for alarms
@@ -69,7 +81,7 @@ static struct rtc_device	*rtcdev;
  */
 bool alarmtimer_has_rtcdev(void)
 {
-	return !!READ_ONCE(rtcdev);
+	return !!READ_ONCE(wakeup_ctl.rtc);
 }
 EXPORT_SYMBOL_GPL(alarmtimer_has_rtcdev);
 
@@ -78,7 +90,7 @@ static int alarmtimer_rtc_add_device(struct device *dev)
 	struct rtc_device *rtc = to_rtc_device(dev);
 	struct platform_device *pdev;
 
-	if (rtcdev)
+	if (wakeup_ctl.rtc)
 		return -EBUSY;
 
 	if (!test_bit(RTC_FEATURE_ALARM, rtc->features))
@@ -98,7 +110,7 @@ static int alarmtimer_rtc_add_device(struct device *dev)
 		return -1;
 	}
 
-	WRITE_ONCE(rtcdev, rtc);
+	WRITE_ONCE(wakeup_ctl.rtc, rtc);
 	/* Hold a reference so it doesn't go away */
 	get_device(dev);
 
@@ -107,7 +119,7 @@ static int alarmtimer_rtc_add_device(struct device *dev)
 
 static inline void alarmtimer_rtc_timer_init(void)
 {
-	rtc_timer_init(&rtctimer, NULL, NULL);
+	rtc_timer_init(&wakeup_ctl.timer, NULL, NULL);
 }
 
 static struct class_interface alarmtimer_rtc_interface = {
@@ -215,13 +227,13 @@ static int alarmtimer_suspend(struct device *dev)
 	int i, ret, type;
 
 	scoped_guard(spinlock_irqsave, &freezer_delta_lock) {
-		min = freezer_delta;
-		expires = freezer_expires;
-		type = freezer_alarmtype;
-		freezer_delta = 0;
+		min = wakeup_ctl.freezer_delta;
+		expires = wakeup_ctl.freezer_expires;
+		type = wakeup_ctl.freezer_type;
+		wakeup_ctl.freezer_delta = 0;
 	}
 
-	rtc = READ_ONCE(rtcdev);
+	rtc = READ_ONCE(wakeup_ctl.rtc);
 	/* If we have no rtcdev, just return */
 	if (!rtc)
 		return 0;
@@ -258,7 +270,7 @@ static int alarmtimer_suspend(struct device *dev)
 	trace_alarmtimer_suspend(expires, type);
 
 	/* Setup an rtc timer to fire that far in the future */
-	rtc_timer_cancel(rtc, &rtctimer);
+	rtc_timer_cancel(rtc, &wakeup_ctl.timer);
 	rtc_read_time(rtc, &tm);
 	now = rtc_tm_to_ktime(tm);
 
@@ -275,7 +287,7 @@ static int alarmtimer_suspend(struct device *dev)
 	now = ktime_add(now, min);
 
 	/* Set alarm, if in the past reject suspend briefly to handle */
-	ret = rtc_timer_start(rtc, &rtctimer, now, 0);
+	ret = rtc_timer_start(rtc, &wakeup_ctl.timer, now, 0);
 	if (ret < 0)
 		pm_wakeup_event(dev, MSEC_PER_SEC);
 	return ret;
@@ -285,9 +297,9 @@ static int alarmtimer_resume(struct device *dev)
 {
 	struct rtc_device *rtc;
 
-	rtc = READ_ONCE(rtcdev);
+	rtc = READ_ONCE(wakeup_ctl.rtc);
 	if (rtc)
-		rtc_timer_cancel(rtc, &rtctimer);
+		rtc_timer_cancel(rtc, &wakeup_ctl.timer);
 	return 0;
 }
 
@@ -462,10 +474,10 @@ static void alarmtimer_freezerset(ktime_t absexp, enum alarmtimer_type type)
 	delta = ktime_sub(absexp, base->get_ktime());
 
 	guard(spinlock_irqsave)(&freezer_delta_lock);
-	if (!freezer_delta || (delta < freezer_delta)) {
-		freezer_delta = delta;
-		freezer_expires = absexp;
-		freezer_alarmtype = type;
+	if (!wakeup_ctl.freezer_delta || (delta < wakeup_ctl.freezer_delta)) {
+		wakeup_ctl.freezer_delta = delta;
+		wakeup_ctl.freezer_expires = absexp;
+		wakeup_ctl.freezer_type = type;
 	}
 }
 

-- 
2.43.0

