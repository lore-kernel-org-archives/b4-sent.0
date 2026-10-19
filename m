From: Fabricio Akio <fabricioakio@gmail.com>
Date: Mon, 19 Oct 2026 19:58:32 -0300
Subject: [PATCH 3/3] drm/msm/a5xx: Use the downstream GPU idle timeout on
 A508, A509 and A512
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-a5xx-gpu-pm-v1-3-1d0c313a1412@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792450714; l=3585;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=cXuE1dXmmOJbBZYxHq4v0R2d0f35xmFnvdicm6SOghk=;
 b=LzlQnGXBmj93JNo9quUesds4Cs0o5QRubK1pirscMXLh/RYexwsTwDfRCI5zxR4HVfRu9jfdC
 OgzQtwmDNnBCvaPUGPF9nG4UFQs60zmDMZxzzGZeF2cwCWMDt7o4uho
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The A508, A509 and A512 took the 250 ms runtime-PM autosuspend delay
of the A530, raised there because quickly cycling that GPU's power
hung the system. Qualcomm's downstream driver powers these GPUs down
after 80 ms idle, qcom,idle-timeout, on SDM630, SDM636 and SDM660
alike.

Use 80 ms for these three, so the GPU powers down, and releases its
CPU latency request, sooner after its last work.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
The value is downstream's idle timeout for these SoCs:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm630-gpu.dtsi#L71
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm660-gpu.dtsi#L73
SDM636 includes sdm660.dtsi:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm636.dtsi#L13
Downstream reads it at probe, restarts the idle timer when the last
work completes, and slumbers the GPU when it fires, dropping its CPU
latency request:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/adreno.c#L901
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/kgsl_pwrctrl.c#L2981
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/kgsl_pwrctrl.c#L2467
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/drivers/gpu/msm/kgsl_pwrctrl.c#L2753

Tested on an A508 with the previous patch: 1381 GPU power cycles at
gaps from 50 ms to 3 s without a fault. The A509 and A512 values are
downstream's for SDM636 and SDM660; tested on an A508 only.
---
 drivers/gpu/drm/msm/adreno/a5xx_catalog.c | 18 +++---------------
 1 file changed, 3 insertions(+), 15 deletions(-)

diff --git a/drivers/gpu/drm/msm/adreno/a5xx_catalog.c b/drivers/gpu/drm/msm/adreno/a5xx_catalog.c
index 7b261f045eae..254bae06af39 100644
--- a/drivers/gpu/drm/msm/adreno/a5xx_catalog.c
+++ b/drivers/gpu/drm/msm/adreno/a5xx_catalog.c
@@ -50,11 +50,7 @@ static const struct adreno_info a5xx_gpus[] = {
 			[ADRENO_FW_PFP] = "a530_pfp.fw",
 		},
 		.gmem = (SZ_128K + SZ_8K),
-		/*
-		 * Increase inactive period to 250 to avoid bouncing
-		 * the GDSC which appears to make it grumpy
-		 */
-		.inactive_period = 250,
+		.inactive_period = 80,
 		.cpu_latency_us = 424,
 		.quirks = ADRENO_QUIRK_LMLOADKILL_DISABLE,
 		.funcs = &a5xx_gpu_funcs,
@@ -68,11 +64,7 @@ static const struct adreno_info a5xx_gpus[] = {
 			[ADRENO_FW_PFP] = "a530_pfp.fw",
 		},
 		.gmem = (SZ_256K + SZ_16K),
-		/*
-		 * Increase inactive period to 250 to avoid bouncing
-		 * the GDSC which appears to make it grumpy
-		 */
-		.inactive_period = 250,
+		.inactive_period = 80,
 		.cpu_latency_us = 518,
 		.quirks = ADRENO_QUIRK_LMLOADKILL_DISABLE,
 		.funcs = &a5xx_gpu_funcs,
@@ -102,11 +94,7 @@ static const struct adreno_info a5xx_gpus[] = {
 			[ADRENO_FW_PFP] = "a530_pfp.fw",
 		},
 		.gmem = (SZ_256K + SZ_16K),
-		/*
-		 * Increase inactive period to 250 to avoid bouncing
-		 * the GDSC which appears to make it grumpy
-		 */
-		.inactive_period = 250,
+		.inactive_period = 80,
 		.cpu_latency_us = 518,
 		.quirks = ADRENO_QUIRK_LMLOADKILL_DISABLE,
 		.funcs = &a5xx_gpu_funcs,

-- 
2.56.0

