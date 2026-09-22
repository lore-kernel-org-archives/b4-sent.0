From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:24:43 -0400
Subject: [PATCH 2/2] PM: sleep: reset async_error with WRITE_ONCE()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-pm-main-v1-2-1d4cbd9d2b2c@vt.edu>
References: <20260921-mb-pm-main-v1-0-1d4cbd9d2b2c@vt.edu>
In-Reply-To: <20260921-mb-pm-main-v1-0-1d4cbd9d2b2c@vt.edu>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: linux-pm@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040284; l=2514;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=FjB7xS3+qARVsXk4Wq7dhtfdezLpl2Z4zIUoXhuVxW8=;
 b=wtO0ax58zemrWNGn4XyWf2ptQ0cjYdcW4tMj3UNAN6Wk39c7xqXTdq8E+ji3J/vVTuRdPFV7C
 BSVjGs3F5cKBTnT0BotNoYF1ImhC3ECem01CQtDCmfE95vaLpYjgBH9
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The device PM callbacks record failures with WRITE_ONCE(async_error, ...)
and every reader uses READ_ONCE(), but the six phase functions reset the
variable with a plain store before they schedule the asynchronous
callbacks.

Use WRITE_ONCE() for the reset so that every access to async_error
follows the same convention.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/base/power/main.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/base/power/main.c b/drivers/base/power/main.c
index bf4b4fd1b..24b56aaa3 100644
--- a/drivers/base/power/main.c
+++ b/drivers/base/power/main.c
@@ -905,7 +905,7 @@ static void dpm_noirq_resume_devices(pm_message_t state)
 
 	trace_suspend_resume(TPS("dpm_resume_noirq"), state.event, true);
 
-	async_error = 0;
+	WRITE_ONCE(async_error, 0);
 	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
 	smp_store_release(&pm_transition.event, state.event);
 
@@ -1056,7 +1056,7 @@ void dpm_resume_early(pm_message_t state)
 
 	trace_suspend_resume(TPS("dpm_resume_early"), state.event, true);
 
-	async_error = 0;
+	WRITE_ONCE(async_error, 0);
 	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
 	smp_store_release(&pm_transition.event, state.event);
 
@@ -1238,7 +1238,7 @@ void dpm_resume(pm_message_t state)
 
 	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
 	smp_store_release(&pm_transition.event, state.event);
-	async_error = 0;
+	WRITE_ONCE(async_error, 0);
 
 	mutex_lock(&dpm_list_mtx);
 
@@ -1604,7 +1604,7 @@ static int dpm_noirq_suspend_devices(pm_message_t state)
 
 	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
 	smp_store_release(&pm_transition.event, state.event);
-	async_error = 0;
+	WRITE_ONCE(async_error, 0);
 
 	mutex_lock(&dpm_list_mtx);
 
@@ -1808,7 +1808,7 @@ int dpm_suspend_late(pm_message_t state)
 
 	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
 	smp_store_release(&pm_transition.event, state.event);
-	async_error = 0;
+	WRITE_ONCE(async_error, 0);
 
 	wake_up_all_idle_cpus();
 
@@ -2102,7 +2102,7 @@ int dpm_suspend(pm_message_t state)
 
 	/* Pairs with the smp_load_acquire() in dev_pm_skip_resume(). */
 	smp_store_release(&pm_transition.event, state.event);
-	async_error = 0;
+	WRITE_ONCE(async_error, 0);
 
 	mutex_lock(&dpm_list_mtx);
 

-- 
2.43.0

