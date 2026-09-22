From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:23:43 -0400
Subject: [PATCH] timekeeping: publish suspend_timing_needed with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-timekeeping-v1-1-282f1f4121ed@vt.edu>
X-B4-Tracking: v=1; b=H4sIAJ7YsWoC/yXMzQ6CMBAE4Fche3ZNW//QVzEe2jrAaiikRWJCe
 HdbPH6TmVkoIQoS3aqFImZJMoQMvavIdza0YHlmk1HmrK5Gc+94kh5vYJTQsnV1g5OptYKnPBo
 jGvluh/fH3+njXvBTeSkNZxPYRRt8V6KN82V/4OiPtK4/eyVLVJIAAAA=
X-Change-ID: 20260921-mb-timekeeping-ab8fe52810ec
To: John Stultz <jstultz@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Miroslav Lichvar <mlichvar@redhat.com>
Cc: linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040224; l=1568;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=cFvsdCri+WSttL45t1gLuvPcu/++U/qXQAilyA7gKyA=;
 b=XsfM9ZYumY0npb7drz9mhmdcbVQsWkgjIVxLDsQgPI6ECxkHMcIuF7OPgNWn8CvdOC7Iet4E7
 eKkWzMB1GQVCmuioJ9SQfOt/hqqSQMYRUzAM5PuyPGMc0nDTKRh6YSj
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

timekeeping_suspend() sets suspend_timing_needed with a plain store
after it has read the persistent clock. timekeeping_rtc_skipresume()
reads it with a plain load on behalf of the RTC class during resume.

Set it with smp_store_release() and read it with smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 kernel/time/timekeeping.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/kernel/time/timekeeping.c b/kernel/time/timekeeping.c
index ea2e6e55f..2b15268c3 100644
--- a/kernel/time/timekeeping.c
+++ b/kernel/time/timekeeping.c
@@ -2141,7 +2141,8 @@ static void __timekeeping_inject_sleeptime(struct timekeeper *tk,
  */
 bool timekeeping_rtc_skipresume(void)
 {
-	return !suspend_timing_needed;
+	/* Pairs with the smp_store_release() in timekeeping_suspend(). */
+	return !smp_load_acquire(&suspend_timing_needed);
 }
 
 /*
@@ -2272,7 +2273,8 @@ int timekeeping_suspend(void)
 	if (timekeeping_suspend_time.tv_sec || timekeeping_suspend_time.tv_nsec)
 		persistent_clock_exists = true;
 
-	suspend_timing_needed = true;
+	/* Pairs with the smp_load_acquire() in timekeeping_rtc_skipresume(). */
+	smp_store_release(&suspend_timing_needed, true);
 
 	raw_spin_lock_irqsave(&tk_core.lock, flags);
 	timekeeping_forward_now(tks);

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-timekeeping-ab8fe52810ec

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

