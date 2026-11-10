From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:13:47 +0000
Subject: [PATCH] rtc: Don't lose a minute-resolution alarm that rounds down
 into the past
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rtc-minute-alarm-v1-1-be9d7c5227a1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB1wUhD1KsVFTEY7RdMyiVIQ7
 26qy7f4f4fIKhyhK3ZQ3iTKJ2RQWYB72TAxis8GU5maiCrU5HCRsCZGO1tdkHxjx7ZuWm8ekLO
 v8ii/a/nsb8d1eLNL/w8cxwmebj5FdAAAAA==
X-Change-ID: 20261110-rtc-minute-alarm-1d8af9689d23
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: linux-rtc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294826; l=3842;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=hx7EEY3IfQIk7dUR86H3++IsY8ALA3UcN3TSCzhHjd0=;
 b=jsAqaqf+rioQFbEmgC1MQTpbqOEw0nvDj0vKgQlAUhFxbXy8FVL42jE+0/0dIMuRh6fr1HkQO
 am01n5PFKwOBB5dwYkgDj/243VL/DH6EvsecEk05+o3OeEOoJZMcA9t
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For an RTC with RTC_FEATURE_ALARM_RES_MINUTE, rtc_set_alarm() rounds the
alarm down to the start of its minute, so that it never fires late. When
the alarm is less than a minute away and in the same minute as the
current time, the rounded time is already in the past.
rtc_timer_enqueue() then gets -ETIME from __rtc_set_alarm() and expires
the timer from the irq work right away, and the hardware alarm is never
armed.

That loses every short wake alarm. With a HYM8563, which has minute
resolution, "rtcwake -m freeze -s 15" sets an alarm that expires in
software before the system suspends, so nothing wakes it: with the
alarm set at 17:55:00 for 17:55:17, /proc/driver/rtc reads back
"alrm_time: 17:55:00, alarm_IRQ: no", and the system stays in
suspend-to-idle until something else wakes it.

Round the alarm up to the next minute when rounding down would put an
alarm that is still in the future into the past. It then fires at most
59 seconds late instead of never. Alarms that are already in the past,
or that round down to a time still in the future, are handled as before.

Fixes: d87f741dddab ("rtc: handle alarms with a minute resolution")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S) with a HYM8563: "rtcwake -m no -s 15"
now reads back the alarm at the next full minute with "alarm_IRQ: yes",
and 47 consecutive "rtcwake -m freeze -s 15" cycles all woke from the
RTC interrupt. Before the fix the alarm was lost whenever the 15 s
stayed inside the current minute, and the system never woke.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed and tested it
as described above.
---
 drivers/rtc/interface.c | 33 +++++++++++++++++++++++++++------
 1 file changed, 27 insertions(+), 6 deletions(-)

diff --git a/drivers/rtc/interface.c b/drivers/rtc/interface.c
index 96626f8068f9..004819c9a846 100644
--- a/drivers/rtc/interface.c
+++ b/drivers/rtc/interface.c
@@ -535,18 +535,39 @@ int rtc_set_alarm(struct rtc_device *rtc, struct rtc_wkalrm *alarm)
 		rtc_timer_remove(rtc, &rtc->aie_timer);
 
 	alarm_time = rtc_tm_to_ktime(alarm->time);
-	/*
-	 * Round down so we never miss a deadline, checking for past deadline is
-	 * done in __rtc_set_alarm
-	 */
-	if (test_bit(RTC_FEATURE_ALARM_RES_MINUTE, rtc->features))
-		alarm_time = ktime_sub_ns(alarm_time, (u64)alarm->time.tm_sec * NSEC_PER_SEC);
+	if (test_bit(RTC_FEATURE_ALARM_RES_MINUTE, rtc->features) &&
+	    alarm->time.tm_sec) {
+		ktime_t down = ktime_sub_ns(alarm_time,
+					    (u64)alarm->time.tm_sec * NSEC_PER_SEC);
+		struct rtc_time tm;
+		ktime_t now;
+
+		err = __rtc_read_time(rtc, &tm);
+		if (err)
+			goto unlock;
+		now = rtc_tm_to_ktime(tm);
+
+		/*
+		 * Round down so we never miss a deadline. If that puts an alarm
+		 * that is still in the future into the past, the timer would
+		 * expire right away and the hardware alarm would never be
+		 * armed: whoever relies on it, e.g. to wake the system from
+		 * suspend, would wait forever. Round up to the next minute
+		 * instead. An alarm already in the past is left alone, it is
+		 * handled by __rtc_set_alarm.
+		 */
+		if (ktime_after(down, now) || !ktime_after(alarm_time, now))
+			alarm_time = down;
+		else
+			alarm_time = ktime_add_ns(down, 60 * NSEC_PER_SEC);
+	}
 
 	rtc->aie_timer.node.expires = alarm_time;
 	rtc->aie_timer.period = 0;
 	if (alarm->enabled)
 		err = rtc_timer_enqueue(rtc, &rtc->aie_timer);
 
+unlock:
 	mutex_unlock(&rtc->ops_lock);
 
 	return err;

---
base-commit: 7485659ecb81d5fce3a3edf2cae9fcb29c17b1cd
change-id: 20261110-rtc-minute-alarm-1d8af9689d23

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

