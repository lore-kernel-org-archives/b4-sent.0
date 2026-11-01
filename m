From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 31 Oct 2026 23:32:51 -0300
Subject: [PATCH 2/2] drm/msm/a5xx: Record per-submission GPU time and
 cycles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-a5xx-submit-stats-v1-2-16a67ac96edd@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793500370; l=2787;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=UZvYI2+JsvZ0udAefkfHBN4v1q+DPk+DHVfHhpLHJgo=;
 b=ZIg3OCm2GyExJMw7ykZd/y8UhQcHErpLRr8LQciymK8R+oOuwPyU4ZIvcZyWy6sFSf/s0bCxK
 WMgV6bvSMhSB/GNc8YrDZvVLRB5pobZwo+4rAgHKpaeLhZJ8ixYgzSw
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPU time and cycles msm records for each submission, reported in
the msm_gpu_submit_retired trace event and added to fdinfo's
drm-engine-gpu and drm-cycles-gpu, come from counters the CP copies to
memory around each submission. a6xx_submit() emits those copies;
a5xx_submit() does not, so on A5xx all of them read zero.

Copy the CP cycle counter and the always-on counter before and after
the submission's IBs, as a6xx does.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
The counters are copied outside the IBs, so a preemption inside a
submission, at a yield point in its IBs, would count the other ring's
time in it. Switches between submissions were tested.
---
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
index 16c7335c4b1f..7d4a9db0a3de 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
@@ -124,8 +124,20 @@ static void a5xx_submit_in_rb(struct msm_gpu *gpu, struct msm_gem_submit *submit
 	msm_gpu_retire(gpu);
 }
 
+static void get_stats_counter(struct msm_ringbuffer *ring, u32 counter,
+			      u64 iova)
+{
+	OUT_PKT7(ring, CP_REG_TO_MEM, 3);
+	OUT_RING(ring, CP_REG_TO_MEM_0_REG(counter) |
+		CP_REG_TO_MEM_0_CNT(2) |
+		CP_REG_TO_MEM_0_IS_64B);
+	OUT_RING(ring, lower_32_bits(iova));
+	OUT_RING(ring, upper_32_bits(iova));
+}
+
 static void a5xx_submit(struct msm_gpu *gpu, struct msm_gem_submit *submit)
 {
+	unsigned int index = submit->seqno % MSM_GPU_SUBMIT_STATS_COUNT;
 	struct adreno_gpu *adreno_gpu = to_adreno_gpu(gpu);
 	struct a5xx_gpu *a5xx_gpu = to_a5xx_gpu(adreno_gpu);
 	struct msm_ringbuffer *ring = submit->ring;
@@ -167,6 +179,11 @@ static void a5xx_submit(struct msm_gpu *gpu, struct msm_gem_submit *submit)
 	OUT_PKT7(ring, CP_YIELD_ENABLE, 1);
 	OUT_RING(ring, 0x02);
 
+	get_stats_counter(ring, REG_A5XX_RBBM_PERFCTR_CP_0_LO,
+			  rbmemptr_stats(ring, index, cpcycles_start));
+	get_stats_counter(ring, REG_A5XX_RBBM_ALWAYSON_COUNTER_LO,
+			  rbmemptr_stats(ring, index, alwayson_start));
+
 	/* Submit the commands */
 	for (i = 0; i < submit->nr_cmds; i++) {
 		switch (submit->cmd[i].type) {
@@ -208,6 +225,11 @@ static void a5xx_submit(struct msm_gpu *gpu, struct msm_gem_submit *submit)
 	OUT_RING(ring, 0);
 	OUT_RING(ring, 0);
 
+	get_stats_counter(ring, REG_A5XX_RBBM_PERFCTR_CP_0_LO,
+			  rbmemptr_stats(ring, index, cpcycles_end));
+	get_stats_counter(ring, REG_A5XX_RBBM_ALWAYSON_COUNTER_LO,
+			  rbmemptr_stats(ring, index, alwayson_end));
+
 	/* Turn off IB level preemptions */
 	OUT_PKT7(ring, CP_YIELD_ENABLE, 1);
 	OUT_RING(ring, 0x01);

-- 
2.56.0

