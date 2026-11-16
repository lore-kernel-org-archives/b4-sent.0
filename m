From: Igor Velkov <iav@iav.lv>
Date: Mon, 16 Nov 2026 00:25:02 +0000
Subject: [PATCH v2 3/8] alarmtimer: Replace the freezer delta with per type
 expiry times
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-b4-alarmtimer-rtc-priority-v2-3-b2c69721e489@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5429; i=iav@iav.lv;
 h=from:subject:message-id; bh=0OTcofvxPwIQxlh2z7uyMWINjUjoJiPHkccA7c5PNEw=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fBM6eAw9ljgnNAeaRp1Ktrl5/6jbmqBLfya7Mucvn
 R7//+HnjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjARLwOG//lv/Qx9lhx9orpP
 /cxRW9uaxUfs7Dcy2rVt+2TRHjxj+1WG/6E/X8zy9g03UVeITMvlUWQ8997ONOOewvU7Bfub7r3
 r5gcA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the freezer interrupts an alarm clock_nanosleep(),
alarmtimer_freezerset() records the remaining time, the expiry and the
alarm type and keeps the call with the least remaining time.
alarmtimer_suspend() starts its scan with that.

The remaining time is computed when the task is frozen, so it is stale
when the system suspends, and a clock_settime() in between is not taken
into account for REALTIME. A remaining time of exactly 0 counts as no
timer.

Record the earliest expiry per alarm type instead, KTIME_MAX for none, and
compare it with the queue head of its base in alarmtimer_suspend(), so the
remaining time is computed when it is used. The scan also takes KTIME_MAX
instead of 0 as no timer.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Unlike your sketch and what I wrote, this keeps the frozen expiry per
type and compares it with the queue head in the suspend scan instead of
queueing alarms: such an alarm would exist only to be read back, and if
it fires in between, alarmtimer_fired() drops it and suspend proceeds
without the wakeup. A version with alarms came out 44 lines longer.
---
 kernel/time/alarmtimer.c | 75 ++++++++++++++++++------------------------------
 1 file changed, 28 insertions(+), 47 deletions(-)

diff --git a/kernel/time/alarmtimer.c b/kernel/time/alarmtimer.c
index 35630f0ff566..066d980fa6d5 100644
--- a/kernel/time/alarmtimer.c
+++ b/kernel/time/alarmtimer.c
@@ -54,22 +54,20 @@ static struct alarm_base {
  * struct rtc_wakeup - State for waking the system from suspend on alarms
  * @rtc:		RTC programmed on suspend, NULL if none
  * @timer:		RTC timer started on suspend
- * @freezer_delta:	Least remaining time of the clock_nanosleep() calls
- *			which the freezer interrupted, 0 if none
- * @freezer_expires:	Expiry of that call
- * @freezer_type:	Alarm type of that call
+ * @freezer_expires:	Earliest expiry per alarm type of the clock_nanosleep()
+ *			calls which the freezer interrupted, KTIME_MAX if none
  */
 struct rtc_wakeup {
 	struct rtc_device	*rtc;
 	struct rtc_timer	timer;
-	ktime_t			freezer_delta;
-	ktime_t			freezer_expires;
-	enum alarmtimer_type	freezer_type;
+	ktime_t			freezer_expires[ALARM_NUMTYPE];
 };
 
-static struct rtc_wakeup wakeup_ctl;
+static struct rtc_wakeup wakeup_ctl = {
+	.freezer_expires = { [0 ... ALARM_NUMTYPE - 1] = KTIME_MAX },
+};
 
-static DEFINE_SPINLOCK(freezer_delta_lock);
+static DEFINE_SPINLOCK(freezer_lock);
 #endif
 
 #ifdef CONFIG_RTC_CLASS
@@ -221,28 +219,22 @@ EXPORT_SYMBOL_GPL(alarm_expires_remaining);
  */
 static int alarmtimer_suspend(struct device *dev)
 {
-	ktime_t min, now, expires;
+	ktime_t min = KTIME_MAX, expires = 0, now;
 	struct rtc_device *rtc;
+	int i, ret, type = 0;
 	struct rtc_time tm;
-	int i, ret, type;
-
-	scoped_guard(spinlock_irqsave, &freezer_delta_lock) {
-		min = wakeup_ctl.freezer_delta;
-		expires = wakeup_ctl.freezer_expires;
-		type = wakeup_ctl.freezer_type;
-		wakeup_ctl.freezer_delta = 0;
-	}
 
 	rtc = READ_ONCE(wakeup_ctl.rtc);
 	/* If we have no rtcdev, just return */
 	if (!rtc)
 		return 0;
 
-	/* Find the soonest timer to expire */
+	/* Find the soonest timer to expire, frozen clock_nanosleep() included */
 	for (i = 0; i < ALARM_NUMTYPE; i++) {
 		struct alarm_base *base = &alarm_bases[i];
+		ktime_t next_expires = KTIME_MAX;
 		struct timerqueue_node *next;
-		ktime_t next_expires;
+		int next_type = i;
 		ktime_t delta;
 
 		scoped_guard(spinlock_irqsave, &base->lock) {
@@ -250,16 +242,24 @@ static int alarmtimer_suspend(struct device *dev)
 			if (next)
 				next_expires = next->expires;
 		}
-		if (!next)
+		scoped_guard(spinlock_irqsave, &freezer_lock) {
+			if (wakeup_ctl.freezer_expires[i] < next_expires) {
+				next_expires = wakeup_ctl.freezer_expires[i];
+				next_type = i == ALARM_REALTIME ?
+					    ALARM_REALTIME_FREEZER : ALARM_BOOTTIME_FREEZER;
+			}
+			wakeup_ctl.freezer_expires[i] = KTIME_MAX;
+		}
+		if (next_expires == KTIME_MAX)
 			continue;
 		delta = ktime_sub(next_expires, base->get_ktime());
-		if (!min || (delta < min)) {
+		if (delta < min) {
 			expires = next_expires;
 			min = delta;
-			type = i;
+			type = next_type;
 		}
 	}
-	if (min == 0)
+	if (min == KTIME_MAX)
 		return 0;
 
 	if (ktime_to_ns(min) < 2 * NSEC_PER_SEC) {
@@ -454,31 +454,12 @@ EXPORT_SYMBOL_GPL(alarm_forward_now);
 
 static void alarmtimer_freezerset(ktime_t absexp, enum alarmtimer_type type)
 {
-	struct alarm_base *base;
-	ktime_t delta;
-
-	switch(type) {
-	case ALARM_REALTIME:
-		base = &alarm_bases[ALARM_REALTIME];
-		type = ALARM_REALTIME_FREEZER;
-		break;
-	case ALARM_BOOTTIME:
-		base = &alarm_bases[ALARM_BOOTTIME];
-		type = ALARM_BOOTTIME_FREEZER;
-		break;
-	default:
-		WARN_ONCE(1, "Invalid alarm type: %d\n", type);
+	if (WARN_ONCE(type >= ALARM_NUMTYPE, "Invalid alarm type: %d\n", type))
 		return;
-	}
 
-	delta = ktime_sub(absexp, base->get_ktime());
-
-	guard(spinlock_irqsave)(&freezer_delta_lock);
-	if (!wakeup_ctl.freezer_delta || (delta < wakeup_ctl.freezer_delta)) {
-		wakeup_ctl.freezer_delta = delta;
-		wakeup_ctl.freezer_expires = absexp;
-		wakeup_ctl.freezer_type = type;
-	}
+	guard(spinlock_irqsave)(&freezer_lock);
+	if (absexp < wakeup_ctl.freezer_expires[type])
+		wakeup_ctl.freezer_expires[type] = absexp;
 }
 
 /**

-- 
2.43.0

