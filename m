From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:26:42 +0000
Subject: [PATCH v5 11/17] drm/panfrost: Drop the cycle counter only for a
 job that holds it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-panfrost-long-jobs-v5-11-e7d62045a676@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795886791; l=3305;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=vMKaKZ5mQLiJl35MCdiCDsift3wdtfGyvhrgb9GdKPA=;
 b=wGClFl69gTnnqx7hqrHLFvlp6BlLGGumTSWO3Jq0DcLBQ2UOxkwpToqu8uAaV7iMUZ9yzapg9
 uwH9FV7F3rhDHYtDgiXQpdA2JsZ2fYL+/R0RwvIA+2qTie6wyQa6Qxg
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While a reset is pending, panfrost_job_hw_submit() queues a job without
starting it or taking a cycle counter reference, and a stopped job is
resubmitted with is_profiled still set. panfrost_reset() drops a
reference for each, so use_count goes negative. The reset hides this
today; without one (patch 16) the counter is no longer started.

Record whether a job holds a reference. Found by Sashiko. Not
reproduced.

Fixes: f11b0417eec2 ("drm/panfrost: Add fdinfo support GPU load metrics")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-210891@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 19 +++++++++++++------
 drivers/gpu/drm/panfrost/panfrost_job.h |  1 +
 2 files changed, 14 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index a64c33047..fcddc13bf 100644
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
@@ -734,9 +743,7 @@ panfrost_reset(struct panfrost_device *pfdev,
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
index 3e3b97178..7f71e4c38 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.h
+++ b/drivers/gpu/drm/panfrost/panfrost_job.h
@@ -36,6 +36,7 @@ struct panfrost_job {
 
 	struct panfrost_engine_usage *engine_usage;
 	bool is_profiled;
+	bool cycle_counter_ref;
 	ktime_t start_time;
 	u64 start_cycles;
 };

-- 
2.55.0

