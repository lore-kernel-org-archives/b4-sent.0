From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:26:43 +0000
Subject: [PATCH v5 12/17] drm/panfrost: Don't take a job that was never
 started for done
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-panfrost-long-jobs-v5-12-e7d62045a676@gmail.com>
References: <20261128-panfrost-long-jobs-v5-0-e7d62045a676@gmail.com>
In-Reply-To: <20261128-panfrost-long-jobs-v5-0-e7d62045a676@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795886791; l=3202;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=KmxdBC9lkjEmZW2MQMtPWghJrhcIC8sdhTBhHqMQcUM=;
 b=5hdppDfTgvc8IRPqrmlKkMpNO5kTrAtNWE2jY9XCMaAFhkiSqquA47xRjJlHR7SYmQwaIulFy
 omcwe3KlKbvDc+OjA6wetJD+Z3ipPH/j9aTQ79rKKPjMf2Gja4wwLdO
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

reset.pending is set before panfrost_reset() masks the job interrupt.
A job queued but not started in that window, behind a running job that
completes, is taken for done: its fence is signalled and it never runs.

Mark a job started when JS_COMMAND_START is written, and leave the
others to the reset. Found by Sashiko. Not reproduced.

Fixes: 030761e097b4 ("drm/panfrost: Queue jobs on the hardware")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-210891@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 8 ++++++--
 drivers/gpu/drm/panfrost/panfrost_job.h | 2 ++
 2 files changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index fcddc13bf..0946da3af 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -261,6 +261,7 @@ static int panfrost_job_hw_submit(struct panfrost_job *job, int js)
 
 	spin_lock(&pfdev->js->job_lock);
 	subslot = panfrost_enqueue_job(pfdev, js, job);
+	job->started = false;
 	/* Don't queue the job if a reset is in progress */
 	if (!atomic_read(&pfdev->reset.pending)) {
 		job->is_profiled = pfdev->profile_mode;
@@ -276,6 +277,7 @@ static int panfrost_job_hw_submit(struct panfrost_job *job, int js)
 			job->start_cycles = panfrost_cycle_counter_read(pfdev);
 		}
 
+		job->started = true;
 		job_write(pfdev, JS_COMMAND_NEXT(js), JS_COMMAND_START);
 		dev_dbg(pfdev->base.dev,
 			"JS: Submitting atom %p to js[%d][%d] with head=0x%llx AS %d",
@@ -584,7 +586,8 @@ static void panfrost_jm_handle_irq(struct panfrost_device *pfdev, u32 status)
 
 		if (failed[j]) {
 			panfrost_job_handle_err(pfdev, failed[j], j);
-		} else if (pfdev->jobs[j][0] && !(js_state & MK_JS_MASK(j))) {
+		} else if (pfdev->jobs[j][0] && pfdev->jobs[j][0]->started &&
+			   !(js_state & MK_JS_MASK(j))) {
 			/* When the current job doesn't fail, the JM dequeues
 			 * the next job without waiting for an ACK, this means
 			 * we can have 2 jobs dequeued and only catch the
@@ -592,7 +595,8 @@ static void panfrost_jm_handle_irq(struct panfrost_device *pfdev, u32 status)
 			 * are inactive, but one job remains in pfdev->jobs[j],
 			 * consider it done. Of course that doesn't apply if a
 			 * failure happened since we cancelled execution of the
-			 * job in _NEXT (see above).
+			 * job in _NEXT (see above), or if the job was queued
+			 * while a reset was pending and never started.
 			 */
 			if (WARN_ON(!done[j][0]))
 				done[j][0] = panfrost_dequeue_job(pfdev, j);
diff --git a/drivers/gpu/drm/panfrost/panfrost_job.h b/drivers/gpu/drm/panfrost/panfrost_job.h
index 7f71e4c38..0ed45e28b 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.h
+++ b/drivers/gpu/drm/panfrost/panfrost_job.h
@@ -37,6 +37,8 @@ struct panfrost_job {
 	struct panfrost_engine_usage *engine_usage;
 	bool is_profiled;
 	bool cycle_counter_ref;
+	/* JS_COMMAND_START written */
+	bool started;
 	ktime_t start_time;
 	u64 start_cycles;
 };

-- 
2.55.0

