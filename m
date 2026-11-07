From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 07 Nov 2026 17:26:08 -0300
Subject: [PATCH v3 2/4] drm/msm/a5xx: Reset the GPU when resuming it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-a5xx-gpu-pm-v3-2-e2480408abea@gmail.com>
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
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794083169; l=3443;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=swuB5qHfUrNVomwySv4f22B0nyHsJGRFcNLJX68gYv0=;
 b=XX5HFn28yfKDmvaz2ANFIekhZVEN3ZUH3GamTeBzF5FnVQiNCJq+DoxFv54PGVP/GwWgjFZCB
 u2ceCRfNmvhAk3uYL0E6m5kfPeHlk3+1dQHiGSg0bGnNC0jbkiJvD6a
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SDM630, SDM660 and MSM8998 the device tree attaches the GPU's GX
power domain to its SMMU, whose own domain is CX, so GX switches off
only once the SMMU suspends as well. A GPU resumed with GX still on
keeps its state, and the CP keeps its ringbuffer read pointer.
a5xx_hw_init() then rewinds the ringbuffer and writes CP_ME_INIT at its
start, while the CP goes on from its old position, executes stale
ringbuffer contents and hangs:

  timeout waiting to drain ringbuffer 0 rptr/wptr = 23/C

Soft reset the GPU in a5xx_pm_resume() once it is powered, so that
every resume starts from the reset state. The downstream driver resets
only when it finds the GPU's power left on; resetting a GPU that was
powered off changes nothing, and on A508 the reset takes about 2 us of
a resume of about 1.5 ms, so do it every time.

The reset also clears the busy counter devfreq samples as the baseline
of its next poll, so resume devfreq after it.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Changes in v3:
- Say that the device tree attaches GX to the SMMU, whose own domain
  is CX (Konrad, Akhil)
- Resume devfreq after the reset instead of taking its baseline again,
  on the previous patch (Akhil)
- Dropped Dmitry's Tested-by: devfreq now resumes after the reset
  instead of resampling the busy counter

Changes in v2:
- Take devfreq's busy-cycle baseline again after the reset, which
  clears the busy counter (Sashiko)

Downstream resets when it finds a GPU regulator left on, and resumes
its frequency scaling only after that:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/adreno.c#L1336-L1351
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/kgsl_pwrctrl.c#L2596-L2606

A stall with the same signature, the CP's read pointer past the write
pointer just after CP_ME_INIT, was reported on an A509:
https://lore.kernel.org/linux-arm-msm/20260308-adreno-ringbuffer-drain-timeout-recovery-v1-1-985a33faf108@postmarketos.org/

Tested on A508 only; the reset runs on every A5xx.
---
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
index c81f67c639c8..5b5429033986 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
@@ -1367,6 +1367,19 @@ static int a5xx_pm_resume(struct msm_gpu *gpu)
 	if (ret)
 		return ret;
 
+	/*
+	 * The GX power domain is not necessarily switched off while we are
+	 * suspended: on SDM630, SDM660 and MSM8998 the device tree attaches it
+	 * to the GPU's SMMU rather than the GPU. If it stayed on, the CP still
+	 * holds its old ringbuffer read pointer and would execute stale
+	 * ringbuffer contents once hw_init restarts it. Soft reset the GPU so
+	 * that it always resumes from its reset state.
+	 */
+	gpu_write(gpu, REG_A5XX_RBBM_SW_RESET_CMD, 1);
+	gpu_read(gpu, REG_A5XX_RBBM_SW_RESET_CMD);
+	gpu_write(gpu, REG_A5XX_RBBM_SW_RESET_CMD, 0);
+
+	/* devfreq samples the busy counter, which the reset clears */
 	msm_devfreq_resume(gpu);
 
 	/* Adreno 505, 506, 508, 509, 510, 512 needs manual RBBM sus/res control */

-- 
2.56.0

