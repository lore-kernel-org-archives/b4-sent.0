From: Fabricio Akio <fabricioakio@gmail.com>
Date: Mon, 19 Oct 2026 23:05:08 -0300
Subject: [PATCH v2 1/3] drm/msm/a5xx: Reset the GPU when resuming it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-a5xx-gpu-pm-v2-1-457aafbb28da@gmail.com>
References: <20261019-a5xx-gpu-pm-v2-0-457aafbb28da@gmail.com>
In-Reply-To: <20261019-a5xx-gpu-pm-v2-0-457aafbb28da@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792461909; l=4545;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=idG9UEOCHDY9HHinuKj/MRVsQ1JSiZd+zxX4FQSwrt4=;
 b=lMwkiCpQtm+UPs3qByl0tnTg6eemFpXL8Tgk6y4MrPXyboTSxaIBWoZP+tRdRvKGE9m5B2yX/
 1c+k49zDDlJDBYhwJqT/3FuuJ5M+zRAsXxXABNMey7eLvYih9CwsFkZ
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SDM630, SDM660 and MSM8998 the GPU's GX power domain belongs to its
SMMU, not to the GPU, so GX switches off only once the SMMU suspends as
well. A GPU resumed with GX still on keeps its state, and the CP keeps
its ringbuffer read pointer. a5xx_hw_init() then rewinds the ringbuffer
and writes CP_ME_INIT at its start, while the CP goes on from its old
position, executes stale ringbuffer contents and hangs:

  timeout waiting to drain ringbuffer 0 rptr/wptr = 23/C

Soft reset the GPU in a5xx_pm_resume() once it is powered, so that
every resume starts from the reset state. The downstream driver resets
only when it finds the GPU's power left on; resetting a GPU that was
powered off changes nothing, and on A508 the reset takes about 2 us of
a resume of about 1.5 ms, so do it every time.

The reset also clears the busy counter, which msm_gpu_pm_resume() has
just sampled as devfreq's baseline. Take the baseline again after the
reset, or the next devfreq poll subtracts the old count from the new
one, wraps, and sets the GPU to its top frequency.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Changes in v2:
- Take devfreq's busy-cycle baseline again after the reset, which
  clears the busy counter (Sashiko)

Tested on A508 only; the reset runs on every A5xx.

A stall with the same signature, the CP's read pointer past the write
pointer just after CP_ME_INIT, was reported on an A509:
https://lore.kernel.org/linux-arm-msm/20260308-adreno-ringbuffer-drain-timeout-recovery-v1-1-985a33faf108@postmarketos.org/
This may be the root cause of the A509 stall Paul Sajna reported there.
---
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c | 15 +++++++++++++++
 drivers/gpu/drm/msm/msm_gpu.h         |  1 +
 drivers/gpu/drm/msm/msm_gpu_devfreq.c | 17 +++++++++++++++++
 3 files changed, 33 insertions(+)

diff --git a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
index 16c7335c4b1f..0aff8252a00f 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
@@ -1367,6 +1367,21 @@ static int a5xx_pm_resume(struct msm_gpu *gpu)
 	if (ret)
 		return ret;
 
+	/*
+	 * The GX power domain is not necessarily switched off while we are
+	 * suspended: on SDM630, SDM660 and MSM8998 it follows the GPU's SMMU
+	 * rather than the GPU. If it stayed on, the CP still holds its old
+	 * ringbuffer read pointer and would execute stale ringbuffer contents
+	 * once hw_init restarts it. Soft reset the GPU so that it always
+	 * resumes from its reset state.
+	 */
+	gpu_write(gpu, REG_A5XX_RBBM_SW_RESET_CMD, 1);
+	gpu_read(gpu, REG_A5XX_RBBM_SW_RESET_CMD);
+	gpu_write(gpu, REG_A5XX_RBBM_SW_RESET_CMD, 0);
+
+	/* The reset cleared the busy counter devfreq has just sampled */
+	msm_devfreq_resample_busy(gpu);
+
 	/* Adreno 505, 506, 508, 509, 510, 512 needs manual RBBM sus/res control */
 	if (!(adreno_is_a530(adreno_gpu) || adreno_is_a540(adreno_gpu))) {
 		/* Halt the sp_input_clk at HM level */
diff --git a/drivers/gpu/drm/msm/msm_gpu.h b/drivers/gpu/drm/msm/msm_gpu.h
index d27d54bdb7a7..0e0768c15bcc 100644
--- a/drivers/gpu/drm/msm/msm_gpu.h
+++ b/drivers/gpu/drm/msm/msm_gpu.h
@@ -735,6 +735,7 @@ static inline struct msm_context *msm_context_get(
 void msm_devfreq_init(struct msm_gpu *gpu);
 void msm_devfreq_cleanup(struct msm_gpu *gpu);
 void msm_devfreq_resume(struct msm_gpu *gpu);
+void msm_devfreq_resample_busy(struct msm_gpu *gpu);
 void msm_devfreq_suspend(struct msm_gpu *gpu);
 void msm_devfreq_boost(struct msm_gpu *gpu, unsigned factor);
 void msm_devfreq_active(struct msm_gpu *gpu);
diff --git a/drivers/gpu/drm/msm/msm_gpu_devfreq.c b/drivers/gpu/drm/msm/msm_gpu_devfreq.c
index 2e1d5c343272..2e963bff3f61 100644
--- a/drivers/gpu/drm/msm/msm_gpu_devfreq.c
+++ b/drivers/gpu/drm/msm/msm_gpu_devfreq.c
@@ -242,6 +242,23 @@ void msm_devfreq_resume(struct msm_gpu *gpu)
 	devfreq_resume_device(df->devfreq);
 }
 
+/*
+ * Take a new busy cycles baseline, for a GPU that resets its busy counter
+ * after msm_devfreq_resume() has sampled it.
+ */
+void msm_devfreq_resample_busy(struct msm_gpu *gpu)
+{
+	struct msm_gpu_devfreq *df = &gpu->devfreq;
+	unsigned long sample_rate;
+
+	if (!has_devfreq(gpu))
+		return;
+
+	mutex_lock(&df->lock);
+	df->busy_cycles = gpu->funcs->gpu_busy(gpu, &sample_rate);
+	mutex_unlock(&df->lock);
+}
+
 void msm_devfreq_suspend(struct msm_gpu *gpu)
 {
 	struct msm_gpu_devfreq *df = &gpu->devfreq;

-- 
2.56.0

