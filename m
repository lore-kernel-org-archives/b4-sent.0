From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:22:53 -0400
Subject: [PATCH] clocksource: publish finished_booting with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-clocksource-v1-1-3e1d1b43e90d@vt.edu>
X-B4-Tracking: v=1; b=H4sIAGzYsWoC/yXMzQ7CIBAE4Fdp9uwaiqSKr2I8wHa1+APNYhuTp
 u8u1OM3mZkFMkvgDOdmAeE55JBiQbtrgAYX74yhLwatdKesbvHtkV6JnjlNQozGUq+8Np07WSi
 jUfgWvtvh5fp3nvyD6VNfasO7zOjFRRpqtHE+7g8oZGBdfwVdrTySAAAA
X-Change-ID: 20260921-mb-clocksource-49cd0b246a89
To: John Stultz <jstultz@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Miroslav Lichvar <mlichvar@redhat.com>
Cc: linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040174; l=1624;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=IAl0WbtKNjLjhpFUlA0q6EePMhVi1mc72PuB7KQ2WK4=;
 b=KNo/OoqiMXNeaiOdEXN5kppi9PH+zt3BA68jLeg85EjayHobskzow7978IsWzKW4M/OG66uA/
 dfpQkzE9RJPAhPNLn1W4tHEr9Kyw1O7JQ7vV8VVKg4NECG+kHf/i6+m
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

clocksource_done_booting() sets curr_clocksource and then
finished_booting, both with plain stores under clocksource_mutex.
clocksource_find_best() tests finished_booting with a plain load before
it walks clocksource_list.

Set the flag with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 kernel/time/clocksource.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/kernel/time/clocksource.c b/kernel/time/clocksource.c
index f1253f579..f683a787c 100644
--- a/kernel/time/clocksource.c
+++ b/kernel/time/clocksource.c
@@ -1086,7 +1086,8 @@ static struct clocksource *clocksource_find_best(bool oneshot, bool skipcur)
 {
 	struct clocksource *cs;
 
-	if (!finished_booting || list_empty(&clocksource_list))
+	/* Pairs with the smp_store_release() in clocksource_done_booting(). */
+	if (!smp_load_acquire(&finished_booting) || list_empty(&clocksource_list))
 		return NULL;
 
 	/*
@@ -1188,7 +1189,8 @@ static int __init clocksource_done_booting(void)
 {
 	mutex_lock(&clocksource_mutex);
 	curr_clocksource = clocksource_default_clock();
-	finished_booting = 1;
+	/* Pairs with the smp_load_acquire() in clocksource_find_best(). */
+	smp_store_release(&finished_booting, 1);
 	/*
 	 * Run the watchdog first to eliminate unstable clock sources
 	 */

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-clocksource-49cd0b246a89

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

