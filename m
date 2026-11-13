From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 09:03:02 +0000
Subject: [PATCH v3 10/14] drm/panfrost: Drop the cycle counter only for a
 job that holds it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-panfrost-long-jobs-v3-10-80ae78d38f6e@gmail.com>
References: <20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com>
In-Reply-To: <20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794560572; l=3739;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=K4my8lr5ikGRu+Hfa7S/zTxL9cDYzAOG1ImzoduNMoE=;
 b=RknwTh4RMHguPcYmyD88FKi2AXukozuosAJO10LprQhctj4tmgoTJr812l1SFDFt1DjfFdG8n
 fBiyXP5bS3KBKe81u0PIvLQ1BKgzEWZqxg9A1jLmTZlF1q9StKJN5Zw
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_job_hw_submit() puts a job in pfdev->jobs[] but, while a reset
is pending, does not start it and takes no cycle counter reference.
panfrost_reset() drops one for every job in pfdev->jobs[] that wants the
counter, so use_count goes below zero. The same happens for a job that
was stopped (reference dropped at dequeue) and resubmitted while a reset
was pending: is_profiled is still set from its first run.

Today the GPU reset that follows WARNs in panfrost_gpu_soft_reset() and
sets use_count back to 0. Without a reset ("Soft-stop and resume a job
that outlives the timeout") the count stays wrong and
panfrost_cycle_counter_get() no longer starts the counter.

Record in the job whether it holds a reference, and drop it only then.

Found by code review (Sashiko). Not reproduced.

Fixes: f11b0417eec2 ("drm/panfrost: Add fdinfo support GPU load metrics")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-210891@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 19 +++++++++++++------
 drivers/gpu/drm/panfrost/panfrost_job.h |  2 ++
 2 files changed, 15 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 897743cb8..df7fcc436 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -160,6 +160,14 @@ panfrost_get_job_chain_flag(const struct panfrost_job *job)
 	return (f->seqno & 1) ? JS_CONFIG_JOB_CHAIN_FLAG : 0;
 }
 
+static void panfrost_job_put_cycle_counter(struct panfrost_job *job)
+{
+	if (job->cycle_counter_ref) {
+		panfrost_cycle_counter_put(job->pfdev);
+		job->cycle_counter_ref = false;
+	}
+}
+
 static struct panfrost_job *
 panfrost_dequeue_job(struct panfrost_device *pfdev, int slot)
 {
@@ -174,8 +182,7 @@ panfrost_dequeue_job(struct panfrost_device *pfdev, int slot)
 			panfrost_cycle_counter_read(pfdev) - job->start_cycles;
 	}
 
-	if (job->requirements & PANFROST_JD_REQ_CYCLE_COUNT || job->is_profiled)
-		panfrost_cycle_counter_put(pfdev);
+	panfrost_job_put_cycle_counter(job);
 
 	pfdev->jobs[slot][0] = pfdev->jobs[slot][1];
 	pfdev->jobs[slot][1] = NULL;
@@ -259,8 +266,10 @@ static int panfrost_job_hw_submit(struct panfrost_job *job, int js)
 		job->is_profiled = pfdev->profile_mode;
 
 		if (job->requirements & PANFROST_JD_REQ_CYCLE_COUNT ||
-		    job->is_profiled)
+		    job->is_profiled) {
 			panfrost_cycle_counter_get(pfdev);
+			job->cycle_counter_ref = true;
+		}
 
 		if (job->is_profiled) {
 			job->start_time = ktime_get();
@@ -740,9 +749,7 @@ panfrost_reset(struct panfrost_device *pfdev,
 			pfdev->jobs[i][pfdev->jobs[i][0] ? 1 : 0] = evicted[i];
 
 		for (j = 0; j < ARRAY_SIZE(pfdev->jobs[0]) && pfdev->jobs[i][j]; j++) {
-			if (pfdev->jobs[i][j]->requirements & PANFROST_JD_REQ_CYCLE_COUNT ||
-			    pfdev->jobs[i][j]->is_profiled)
-				panfrost_cycle_counter_put(pfdev->jobs[i][j]->pfdev);
+			panfrost_job_put_cycle_counter(pfdev->jobs[i][j]);
 			pm_runtime_put_noidle(pfdev->base.dev);
 			panfrost_devfreq_record_idle(&pfdev->pfdevfreq);
 		}
diff --git a/drivers/gpu/drm/panfrost/panfrost_job.h b/drivers/gpu/drm/panfrost/panfrost_job.h
index 3e3b97178..cd82d7930 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.h
+++ b/drivers/gpu/drm/panfrost/panfrost_job.h
@@ -36,6 +36,8 @@ struct panfrost_job {
 
 	struct panfrost_engine_usage *engine_usage;
 	bool is_profiled;
+	/* Holds a reference on the cycle counter */
+	bool cycle_counter_ref;
 	ktime_t start_time;
 	u64 start_cycles;
 };

-- 
2.55.0

