From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:24:42 -0400
Subject: [PATCH 1/2] PM: sleep: publish pm_transition with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-pm-main-v1-1-1d4cbd9d2b2c@vt.edu>
References: <20260921-mb-pm-main-v1-0-1d4cbd9d2b2c@vt.edu>
In-Reply-To: <20260921-mb-pm-main-v1-0-1d4cbd9d2b2c@vt.edu>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: linux-pm@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040284; l=3715;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=azdyUjMWNlvyw0fWXxRiaZkcMY5OCgItug2q1XG165w=;
 b=6VABRbjIMJcJxQBTxhBhk1XqpoAWb0JsYa9rkb5VV9NS+MSMw8qAdiMDgVPVMixaoOUY3aFkj
 sJY7Uv6cz0PBDbNMU9Ze44+p8qhRScze0mGb1kxLuSnpc3nHbSVoX1l
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each dpm_*() phase function stores the current transition to
pm_transition with a plain store before it schedules the asynchronous
device callbacks. dev_pm_skip_resume() and pm_hibernate_is_recovering()
read pm_transition.event from those callbacks, on other CPUs, with plain
loads.

Store the event with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/base/power/main.c | 28 +++++++++++++++++++---------
 1 file changed, 19 insertions(+), 9 deletions(-)

diff --git a/drivers/base/power/main.c b/drivers/base/power/main.c
index e130da428..bf4b4fd1b 100644
--- a/drivers/base/power/main.c
+++ b/drivers/base/power/main.c
@@ -78,7 +78,8 @@ static int async_error;
  */
 bool pm_hibernate_is_recovering(void)
 {
-	return pm_transition.event == PM_EVENT_RECOVER;
+	/* Pairs with the smp_store_release() in the dpm_*() phase functions. */
+	return smp_load_acquire(&pm_transition.event) == PM_EVENT_RECOVER;
 }
 EXPORT_SYMBOL_GPL(pm_hibernate_is_recovering);
 
@@ -682,10 +683,13 @@ static void dpm_watchdog_clear(struct dpm_watchdog *wd)
  */
 bool dev_pm_skip_resume(struct device *dev)
 {
-	if (pm_transition.event == PM_EVENT_RESTORE)
+	/* Pairs with the smp_store_release() in the dpm_*() phase functions. */
+	int event = smp_load_acquire(&pm_transition.event);
+
+	if (event == PM_EVENT_RESTORE)
 		return false;
 
-	if (pm_transition.event == PM_EVENT_THAW)
+	if (event == PM_EVENT_THAW)
 		return dev_pm_skip_suspend(dev);
 
 	return !dev->power.must_resume;
@@ -902,7 +906,8 @@ static void dpm_noirq_resume_devices(pm_message_t state)
 	trace_suspend_resume(TPS("dpm_resume_noirq"), state.event, true);
 
 	async_error = 0;
-	pm_transition = state;
+	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
+	smp_store_release(&pm_transition.event, state.event);
 
 	mutex_lock(&dpm_list_mtx);
 
@@ -1052,7 +1057,8 @@ void dpm_resume_early(pm_message_t state)
 	trace_suspend_resume(TPS("dpm_resume_early"), state.event, true);
 
 	async_error = 0;
-	pm_transition = state;
+	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
+	smp_store_release(&pm_transition.event, state.event);
 
 	mutex_lock(&dpm_list_mtx);
 
@@ -1230,7 +1236,8 @@ void dpm_resume(pm_message_t state)
 
 	trace_suspend_resume(TPS("dpm_resume"), state.event, true);
 
-	pm_transition = state;
+	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
+	smp_store_release(&pm_transition.event, state.event);
 	async_error = 0;
 
 	mutex_lock(&dpm_list_mtx);
@@ -1595,7 +1602,8 @@ static int dpm_noirq_suspend_devices(pm_message_t state)
 
 	trace_suspend_resume(TPS("dpm_suspend_noirq"), state.event, true);
 
-	pm_transition = state;
+	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
+	smp_store_release(&pm_transition.event, state.event);
 	async_error = 0;
 
 	mutex_lock(&dpm_list_mtx);
@@ -1798,7 +1806,8 @@ int dpm_suspend_late(pm_message_t state)
 
 	trace_suspend_resume(TPS("dpm_suspend_late"), state.event, true);
 
-	pm_transition = state;
+	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
+	smp_store_release(&pm_transition.event, state.event);
 	async_error = 0;
 
 	wake_up_all_idle_cpus();
@@ -2091,7 +2100,8 @@ int dpm_suspend(pm_message_t state)
 	devfreq_suspend();
 	cpufreq_suspend();
 
-	pm_transition = state;
+	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
+	smp_store_release(&pm_transition.event, state.event);
 	async_error = 0;
 
 	mutex_lock(&dpm_list_mtx);

-- 
2.43.0

