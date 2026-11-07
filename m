From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 07 Nov 2026 17:26:09 -0300
Subject: [PATCH v3 3/4] drm/msm/a5xx: Hold a CPU latency request while the
 GPU is powered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-a5xx-gpu-pm-v3-3-e2480408abea@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794083169; l=7433;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=/JhjEL22ii7W3xtMdsbYk5EVd1ODpfhSOJcl87x/rEg=;
 b=hY+iT1s8tq99aKO8Zxfxj7ClVUZkSZGqc4dnMe6jcnFR1ZG1vo9ulRR7htIx2/3tL8+jhzZZY
 OTJafopTzkaBUVregT0wy4TEarLgGIIhb8KlPFOJRaovoXDGgmjC9+W
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
is active, qcom,pm-qos-active-latency. Do the same: take the request
when the GPU resumes and drop it when it suspends, so the state is
available again once the GPU has gone idle, and on destroy, which
unbind reaches even when suspending the GPU failed.

The limit is a per-GPU catalog value. Only the system-level state needs
blocking, so the A508 in SDM630, the A509 in SDM636 and the A512 in
SDM660 take 2336 us, the largest entry plus exit latency of the CPU and
cluster idle states these SoCs share: every one of those states stays
available while the GPU is powered. Mainline does not describe the
system-level state yet, so until it does the request blocks nothing.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Changes in v3:
- Take 2336 us instead of downstream's 424 and 518 us, which also
  kept every CPU out of power collapse (Dmitry)
- Drop the request on destroy after adreno_gpu_cleanup(), which stops
  runtime PM and the GPU worker, so nothing can take it again before
  it is freed (Sashiko)

The system-level state comes from a series not yet sent, which adds
SDM630's cluster and system power domains; its entry plus exit latency
is 14773 us, and any limit from 2336 us to just under that blocks the
same states. With it, on an A508, no request gave 205 and 272 hang
detections in 585 and 634 jobs, and 2336 us none in 416 and 479.

Downstream's MPM map lists the GPU's interrupt, SPI 300, as 332 with no
pin:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm630-gpu.dtsi#L62
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm630-pm.dtsi#L585

Downstream's 424 and 518 us:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm630-gpu.dtsi#L117
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm660-gpu.dtsi#L126
It reads the value at probe, applies it when the GPU starts and drops
it when the GPU slumbers:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/adreno.c#L887
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/adreno.c#L1451
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/kgsl_pwrctrl.c#L2753

Tested on an A508 only; the A509 and A512 share its CPU and cluster
idle states.
---
 drivers/gpu/drm/msm/adreno/a5xx_catalog.c |  3 +++
 drivers/gpu/drm/msm/adreno/a5xx_gpu.c     | 14 ++++++++++++++
 drivers/gpu/drm/msm/adreno/a5xx_gpu.h     |  4 ++++
 drivers/gpu/drm/msm/adreno/adreno_gpu.h   |  5 +++++
 4 files changed, 26 insertions(+)

diff --git a/drivers/gpu/drm/msm/adreno/a5xx_catalog.c b/drivers/gpu/drm/msm/adreno/a5xx_catalog.c
index babd320f3b73..ae9127940a22 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_catalog.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_catalog.c
@@ -55,6 +55,7 @@ static const struct adreno_info a5xx_gpus[] = {
 		 * the GDSC which appears to make it grumpy
 		 */
 		.inactive_period = 250,
+		.cpu_latency_us = 2336,
 		.quirks = ADRENO_QUIRK_LMLOADKILL_DISABLE,
 		.funcs = &a5xx_gpu_funcs,
 		.zapfw = "a508_zap.mdt",
@@ -72,6 +73,7 @@ static const struct adreno_info a5xx_gpus[] = {
 		 * the GDSC which appears to make it grumpy
 		 */
 		.inactive_period = 250,
+		.cpu_latency_us = 2336,
 		.quirks = ADRENO_QUIRK_LMLOADKILL_DISABLE,
 		.funcs = &a5xx_gpu_funcs,
 		/* Adreno 509 uses the same ZAP as 512 */
@@ -105,6 +107,7 @@ static const struct adreno_info a5xx_gpus[] = {
 		 * the GDSC which appears to make it grumpy
 		 */
 		.inactive_period = 250,
+		.cpu_latency_us = 2336,
 		.quirks = ADRENO_QUIRK_LMLOADKILL_DISABLE,
 		.funcs = &a5xx_gpu_funcs,
 		.zapfw = "a512_zap.mdt",
diff --git a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
index 5b5429033986..b3f9bbf997c9 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_gpu.c
@@ -1061,6 +1061,11 @@ static void a5xx_destroy(struct msm_gpu *gpu)
 	}
 
 	adreno_gpu_cleanup(adreno_gpu);
+
+	/* Still held if suspending the GPU failed before it was destroyed */
+	if (cpu_latency_qos_request_active(&a5xx_gpu->pm_qos_req))
+		cpu_latency_qos_remove_request(&a5xx_gpu->pm_qos_req);
+
 	kfree(a5xx_gpu);
 }
 
@@ -1360,6 +1365,7 @@ static void a5xx_dump(struct msm_gpu *gpu)
 static int a5xx_pm_resume(struct msm_gpu *gpu)
 {
 	struct adreno_gpu *adreno_gpu = to_adreno_gpu(gpu);
+	struct a5xx_gpu *a5xx_gpu = to_a5xx_gpu(adreno_gpu);
 	int ret;
 
 	/* Turn on the core power */
@@ -1367,6 +1373,11 @@ static int a5xx_pm_resume(struct msm_gpu *gpu)
 	if (ret)
 		return ret;
 
+	if (adreno_gpu->info->cpu_latency_us &&
+	    !cpu_latency_qos_request_active(&a5xx_gpu->pm_qos_req))
+		cpu_latency_qos_add_request(&a5xx_gpu->pm_qos_req,
+					    adreno_gpu->info->cpu_latency_us);
+
 	/*
 	 * The GX power domain is not necessarily switched off while we are
 	 * suspended: on SDM630, SDM660 and MSM8998 the device tree attaches it
@@ -1450,6 +1461,9 @@ static int a5xx_pm_suspend(struct msm_gpu *gpu)
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

