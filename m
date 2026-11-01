From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 31 Oct 2026 23:32:50 -0300
Subject: [PATCH 1/2] drm/msm: Report no GPU time for a submit killed by
 hangcheck
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-a5xx-submit-stats-v1-1-16a67ac96edd@gmail.com>
References: <20261031-a5xx-submit-stats-v1-0-16a67ac96edd@gmail.com>
In-Reply-To: <20261031-a5xx-submit-stats-v1-0-16a67ac96edd@gmail.com>
To: Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jordan Crouse <jordan@cosmicpenguin.net>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793500370; l=2799;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=XiTCuVQ2SVXzVV9gUfwhSNVnytDNQZiKRQ8ZI2IW92k=;
 b=cPMkjXaKMy9W6RniiDq9tmz9FCrvwjT09MF7QD6Laqc6C/gY1veoNzfm5kP0HChlmkatlVxxw
 mlVCjpZb7uJBCmzscdggw8yOnjQVgLHgnJRdWjr2I8EP6hUtTw367QO
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

recover_worker() advances the fence over the submit it treats as hung
and retires it through retire_submit(), which computes its elapsed time
and cycles from the stats slot the CP writes after the submit's IBs.
That submit may not have written its end stamps, leaving an older
submit's or zero; the subtraction then wraps, and about 3 years of GPU
time is added to the context's fdinfo drm-engine-gpu and reported in
msm_gpu_submit_retired.

Set the end stamps of the submit the fence is advanced over to its
start stamps, so that it reports no time. Do it after the GPU is reset,
when the CP can no longer write the slot.

Fixes: 4241db42e474 ("drm/msm/gpu: Add trace events for tracking GPU submissions")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Charging the time until the failed submit was retired, as panfrost
does, would need the stamps' counter read at recovery, and that
differs by generation: a6xx stamps CP_ALWAYS_ON_CONTEXT while its
get_timestamp() reads another counter, and a2xx/a3xx have none. So
this reports zero.
---
 drivers/gpu/drm/msm/msm_gpu.c | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/msm/msm_gpu.c b/drivers/gpu/drm/msm/msm_gpu.c
index 0c2c35636251..40d658a63540 100644
--- a/drivers/gpu/drm/msm/msm_gpu.c
+++ b/drivers/gpu/drm/msm/msm_gpu.c
@@ -468,9 +468,11 @@ static void recover_worker(struct kthread_work *work)
 	struct msm_drm_private *priv = dev->dev_private;
 	struct msm_gem_submit *submit;
 	struct msm_ringbuffer *cur_ring = gpu->funcs->active_ring(gpu);
+	volatile struct msm_gpu_submit_stats *stats;
 	char *comm = NULL, *cmd = NULL;
 	unsigned int noreclaim_flag;
 	struct task_struct *task;
+	uint32_t hung_fence = 0;
 	int i;
 
 	mutex_lock(&gpu->lock);
@@ -548,8 +550,10 @@ static void recover_worker(struct kthread_work *work)
 		 * For the current (faulting?) ring/submit advance the fence by
 		 * one more to clear the faulting submit
 		 */
-		if (ring == cur_ring)
+		if (ring == cur_ring) {
 			ring->memptrs->fence = ++fence;
+			hung_fence = fence;
+		}
 
 		msm_update_fence(ring->fctx, fence);
 	}
@@ -558,6 +562,15 @@ static void recover_worker(struct kthread_work *work)
 
 	gpu->funcs->recover(gpu);
 
+	/*
+	 * The submit retired in place of completing may not have written its
+	 * end stamps, leaving an older submit's or zero.  Now that the GPU is
+	 * reset, set them to its start stamps, so that it reports no time.
+	 */
+	stats = &cur_ring->memptrs->stats[hung_fence % MSM_GPU_SUBMIT_STATS_COUNT];
+	stats->alwayson_end = stats->alwayson_start;
+	stats->cpcycles_end = stats->cpcycles_start;
+
 	/* retire completed submits, plus the one that hung: */
 	retire_submits(gpu);
 

-- 
2.56.0

