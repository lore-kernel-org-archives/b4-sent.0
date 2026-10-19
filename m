From: Fabricio Akio <fabricioakio@gmail.com>
Date: Mon, 19 Oct 2026 19:58:30 -0300
Subject: [PATCH 1/3] drm/msm/a5xx: Reset the GPU when resuming it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-a5xx-gpu-pm-v1-1-1d0c313a1412@gmail.com>
References: <20261019-a5xx-gpu-pm-v1-0-1d0c313a1412@gmail.com>
In-Reply-To: <20261019-a5xx-gpu-pm-v1-0-1d0c313a1412@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792450714; l=2441;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=pgmuJr74vl5DdcyIRaMFMXExHYM4RMyzyaatxZzA9fI=;
 b=Gv9+hl0G1oNlCSAMQZdDBTQPLlTR8N5rRKLdE6TIr3kf5oEw6KcNRUnIJ3AFXmW3Uz837tCrw
 Q4l+CQpQpJ2BiXcPolL0CUo0PGxBE6G5MuyEnA7VWLhkE1ekD8UlFzH
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

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Tested on A508 only; the reset runs on every A5xx.

A stall with the same signature, the CP's read pointer past the write
pointer just after CP_ME_INIT, was reported on an A509:
https://lore.kernel.org/linux-arm-msm/20260308-adreno-ringbuffer-drain-timeout-recovery-v1-1-985a33faf108@postmarketos.org/
This may be the root cause of the A509 stall Paul Sajna reported there.
---
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
index 16c7335c4b1f..dd0d731df138 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
@@ -1367,6 +1367,18 @@ static int a5xx_pm_resume(struct msm_gpu *gpu)
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
 	/* Adreno 505, 506, 508, 509, 510, 512 needs manual RBBM sus/res control */
 	if (!(adreno_is_a530(adreno_gpu) || adreno_is_a540(adreno_gpu))) {
 		/* Halt the sp_input_clk at HM level */

-- 
2.56.0

