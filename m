From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 07 Nov 2026 17:26:07 -0300
Subject: [PATCH v3 1/4] drm/msm: Resume devfreq from each GPU's resume
 callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-a5xx-gpu-pm-v3-1-e2480408abea@gmail.com>
References: <20261107-a5xx-gpu-pm-v3-0-e2480408abea@gmail.com>
In-Reply-To: <20261107-a5xx-gpu-pm-v3-0-e2480408abea@gmail.com>
To: Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Paul Sajna <sajattack@postmarketos.org>, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794083169; l=3502;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=WKx98tYEeskV/kIUiXfz3iSMFdKKmrq0cO+ilFuFsnE=;
 b=UD+hnPGkt24XPuPzx9SUtXtuTqDNI0/yrMudI7K1Cx/+2gSDCNxoj9bXknwMRUheOSU5sQnnE
 TTigYJlo942BNKsjkIX36R1eZABb808jP7i0jzUYtR8PcqNGzp/Oze1
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

msm_gpu_pm_resume() resumes devfreq, which samples the GPU's busy
counter as the baseline of its next poll. A resume callback that resets
the GPU after msm_gpu_pm_resume() clears that counter, and the next
poll then subtracts the old count from the new one and wraps.

Move the call out of msm_gpu_pm_resume() into the resume callbacks that
use it, as A6xx already does, so that each GPU can resume devfreq once
its hardware is ready. The A3xx, A4xx and A5xx callbacks call it right
after msm_gpu_pm_resume(), where it ran before, so nothing changes yet.
A2xx has no gpu_busy callback, so it has no devfreq.

Suggested-by: Akhil P Oommen <akhilpo@oss.qualcomm.com>
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
New in v3.

Tested on A508 only; the A3xx and A4xx callbacks call it where
msm_gpu_pm_resume() did.
---
 drivers/gpu/drm/msm/adreno/a3xx_gpu.c | 15 ++++++++++++++-
 drivers/gpu/drm/msm/adreno/a4xx_gpu.c |  2 ++
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c |  2 ++
 drivers/gpu/drm/msm/msm_gpu.c         |  2 --
 4 files changed, 18 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/msm/adreno/a3xx_gpu.c b/drivers/gpu/drm/msm/adreno/a3xx_gpu.c
index 160d302e16a3..a3aa4ae1fdb0 100644
--- a/drivers/gpu/drm/msm/adreno/a3xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a3xx_gpu.c
@@ -534,6 +534,19 @@ static int a3xx_pm_suspend(struct msm_gpu *gpu)
 	return msm_gpu_pm_suspend(gpu);
 }
 
+static int a3xx_pm_resume(struct msm_gpu *gpu)
+{
+	int ret;
+
+	ret = msm_gpu_pm_resume(gpu);
+	if (ret)
+		return ret;
+
+	msm_devfreq_resume(gpu);
+
+	return 0;
+}
+
 static u32 a3xx_get_rptr(struct msm_gpu *gpu, struct msm_ringbuffer *ring)
 {
 	ring->memptrs->rptr = gpu_read(gpu, REG_AXXX_CP_RB_RPTR);
@@ -637,7 +650,7 @@ const struct adreno_gpu_funcs a3xx_gpu_funcs = {
 		.set_param = adreno_set_param,
 		.hw_init = a3xx_hw_init,
 		.pm_suspend = a3xx_pm_suspend,
-		.pm_resume = msm_gpu_pm_resume,
+		.pm_resume = a3xx_pm_resume,
 		.recover = a3xx_recover,
 		.submit = a3xx_submit,
 		.active_ring = adreno_active_ring,
diff --git a/drivers/gpu/drm/msm/adreno/a4xx_gpu.c b/drivers/gpu/drm/msm/adreno/a4xx_gpu.c
index 6392126f48f2..289204d53311 100644
--- a/drivers/gpu/drm/msm/adreno/a4xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a4xx_gpu.c
@@ -577,6 +577,8 @@ static int a4xx_pm_resume(struct msm_gpu *gpu) {
 	if (ret)
 		return ret;
 
+	msm_devfreq_resume(gpu);
+
 	if (adreno_is_a430(adreno_gpu)) {
 		unsigned int reg;
 		/* Set the default register values; set SW_COLLAPSE to 0 */
diff --git a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
index 16c7335c4b1f..c81f67c639c8 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
@@ -1367,6 +1367,8 @@ static int a5xx_pm_resume(struct msm_gpu *gpu)
 	if (ret)
 		return ret;
 
+	msm_devfreq_resume(gpu);
+
 	/* Adreno 505, 506, 508, 509, 510, 512 needs manual RBBM sus/res control */
 	if (!(adreno_is_a530(adreno_gpu) || adreno_is_a540(adreno_gpu))) {
 		/* Halt the sp_input_clk at HM level */
diff --git a/drivers/gpu/drm/msm/msm_gpu.c b/drivers/gpu/drm/msm/msm_gpu.c
index 0c2c35636251..d33612fb3e53 100644
--- a/drivers/gpu/drm/msm/msm_gpu.c
+++ b/drivers/gpu/drm/msm/msm_gpu.c
@@ -116,8 +116,6 @@ int msm_gpu_pm_resume(struct msm_gpu *gpu)
 	if (ret)
 		return ret;
 
-	msm_devfreq_resume(gpu);
-
 	gpu->needs_hw_init = true;
 
 	return 0;

-- 
2.56.0

