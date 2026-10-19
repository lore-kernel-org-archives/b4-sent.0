From: Fabricio Akio <fabricioakio@gmail.com>
Date: Mon, 19 Oct 2026 19:58:31 -0300
Subject: [PATCH 2/3] drm/msm/a5xx: Hold a CPU latency request while the GPU
 is powered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-a5xx-gpu-pm-v1-2-1d0c313a1412@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792450714; l=6502;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=vmAWCs0jc6biGnTgE0/+DF6RCludk5C4eAXduAuWwV0=;
 b=QnrsuM4J/6cIzmsVszWA3f7J6XP9OBF1jbJipXpMXZowfaMopE9RUICY9nKM1TSpaCYO9iovR
 SeiUeNWRLVlDv6iSAOGxxF2DDXB2theqPc10ncRE4qQ1Rd4CBH6ToB0
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SDM630 the GPU was observed to stop executing while the SoC is in
system-level power collapse, and to continue once the SoC wakes. Its
interrupts have no wakeup route through the MPM, so it cannot wake the
SoC itself. A submission overlapping such a state would stall until a
CPU wakes, and a stall longer than the hang detector's threshold makes
the driver recover the GPU, which can lose a frame.

Qualcomm's downstream driver holds a CPU latency request while the GPU
is active, qcom,pm-qos-active-latency, which keeps the CPU idle
governors out of cluster and system-level power collapse. Do the same:
take the request when the GPU resumes and drop it when it suspends, so
those states remain available once the GPU has gone idle, and on
destroy, which unbind reaches even when suspending the GPU failed. The
limit is a per-GPU catalog value, downstream's for each SoC: 424 us
for the A508 in SDM630, and 518 us for the A509 in SDM636 and the A512
in SDM660.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
The values are downstream's CPU latency while the GPU is active, per
SoC:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm630-gpu.dtsi#L117
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm660-gpu.dtsi#L126
SDM636 takes SDM660's by including sdm660.dtsi:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm636.dtsi#L13
Downstream reads it at probe, applies it when the GPU starts and drops
it when the GPU slumbers:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/adreno.c#L887
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/adreno.c#L1451
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/kgsl_pwrctrl.c#L2753

The A509 and A512 values are downstream's for SDM636 and SDM660;
tested on an A508 only.
---
 drivers/gpu/drm/msm/adreno/a5xx_catalog.c |  3 +++
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c     | 13 +++++++++++++
 drivers/gpu/drm/msm/adreno/a5xx_gpu.h     |  4 ++++
 drivers/gpu/drm/msm/adreno/adreno_gpu.h   |  5 +++++
 4 files changed, 25 insertions(+)

diff --git a/drivers/gpu/drm/msm/adreno/a5xx_catalog.c b/drivers/gpu/drm/msm/adreno/a5xx_catalog.c
index babd320f3b73..7b261f045eae 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_catalog.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_catalog.c
@@ -55,6 +55,7 @@ static const struct adreno_info a5xx_gpus[] = {
 		 * the GDSC which appears to make it grumpy
 		 */
 		.inactive_period = 250,
+		.cpu_latency_us = 424,
 		.quirks = ADRENO_QUIRK_LMLOADKILL_DISABLE,
 		.funcs = &a5xx_gpu_funcs,
 		.zapfw = "a508_zap.mdt",
@@ -72,6 +73,7 @@ static const struct adreno_info a5xx_gpus[] = {
 		 * the GDSC which appears to make it grumpy
 		 */
 		.inactive_period = 250,
+		.cpu_latency_us = 518,
 		.quirks = ADRENO_QUIRK_LMLOADKILL_DISABLE,
 		.funcs = &a5xx_gpu_funcs,
 		/* Adreno 509 uses the same ZAP as 512 */
@@ -105,6 +107,7 @@ static const struct adreno_info a5xx_gpus[] = {
 		 * the GDSC which appears to make it grumpy
 		 */
 		.inactive_period = 250,
+		.cpu_latency_us = 518,
 		.quirks = ADRENO_QUIRK_LMLOADKILL_DISABLE,
 		.funcs = &a5xx_gpu_funcs,
 		.zapfw = "a512_zap.mdt",
diff --git a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
index dd0d731df138..055b2bc9df2f 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
@@ -1060,6 +1060,10 @@ static void a5xx_destroy(struct msm_gpu *gpu)
 		drm_gem_object_put(a5xx_gpu->shadow_bo);
 	}
 
+	/* Still held if suspending the GPU failed before it was destroyed */
+	if (cpu_latency_qos_request_active(&a5xx_gpu->pm_qos_req))
+		cpu_latency_qos_remove_request(&a5xx_gpu->pm_qos_req);
+
 	adreno_gpu_cleanup(adreno_gpu);
 	kfree(a5xx_gpu);
 }
@@ -1360,6 +1364,7 @@ static void a5xx_dump(struct msm_gpu *gpu)
 static int a5xx_pm_resume(struct msm_gpu *gpu)
 {
 	struct adreno_gpu *adreno_gpu = to_adreno_gpu(gpu);
+	struct a5xx_gpu *a5xx_gpu = to_a5xx_gpu(adreno_gpu);
 	int ret;
 
 	/* Turn on the core power */
@@ -1367,6 +1372,11 @@ static int a5xx_pm_resume(struct msm_gpu *gpu)
 	if (ret)
 		return ret;
 
+	if (adreno_gpu->info->cpu_latency_us &&
+	    !cpu_latency_qos_request_active(&a5xx_gpu->pm_qos_req))
+		cpu_latency_qos_add_request(&a5xx_gpu->pm_qos_req,
+					    adreno_gpu->info->cpu_latency_us);
+
 	/*
 	 * The GX power domain is not necessarily switched off while we are
 	 * suspended: on SDM630, SDM660 and MSM8998 it follows the GPU's SMMU
@@ -1447,6 +1457,9 @@ static int a5xx_pm_suspend(struct msm_gpu *gpu)
 	if (ret)
 		return ret;
 
+	if (cpu_latency_qos_request_active(&a5xx_gpu->pm_qos_req))
+		cpu_latency_qos_remove_request(&a5xx_gpu->pm_qos_req);
+
 	if (a5xx_gpu->has_whereami)
 		for (i = 0; i < gpu->nr_rings; i++)
 			a5xx_gpu->shadow[i] = 0;
diff --git a/drivers/gpu/drm/msm/adreno/a5xx_gpu.h b/drivers/gpu/drm/msm/adreno/a5xx_gpu.h
index fb05f1ca3e81..07a36c05be25 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_gpu.h
+++ b/drivers/gpu/drm/msm/adreno/a5xx_gpu.h
@@ -4,6 +4,8 @@
 #ifndef __A5XX_GPU_H__
 #define __A5XX_GPU_H__
 
+#include <linux/pm_qos.h>
+
 #include "adreno_gpu.h"
 
 /* Bringing over the hack from the previous targets */
@@ -48,6 +50,8 @@ struct a5xx_gpu {
 
 	/* True if the microcode supports the WHERE_AM_I opcode */
 	bool has_whereami;
+
+	struct pm_qos_request pm_qos_req;
 };
 
 #define to_a5xx_gpu(x) container_of(x, struct a5xx_gpu, base)
diff --git a/drivers/gpu/drm/msm/adreno/adreno_gpu.h b/drivers/gpu/drm/msm/adreno/adreno_gpu.h
index 4b2156825bdf..fcc382f4a9a1 100644
--- a/drivers/gpu/drm/msm/adreno/adreno_gpu.h
+++ b/drivers/gpu/drm/msm/adreno/adreno_gpu.h
@@ -118,6 +118,11 @@ struct adreno_info {
 	const struct adreno_gpu_funcs *funcs;
 	const char *zapfw;
 	u32 inactive_period;
+	/**
+	 * @cpu_latency_us: CPU latency limit to hold while the GPU is
+	 * powered, in microseconds, or 0 for none
+	 */
+	u32 cpu_latency_us;
 	union {
 		const struct a6xx_info *a6xx;
 	};

-- 
2.56.0

