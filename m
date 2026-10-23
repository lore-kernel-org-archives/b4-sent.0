From: Ishu Brar <patches@brar.si>
Date: Fri, 23 Oct 2026 14:19:02 +0530
Subject: [PATCH v2 4/4] drm/msm/adreno: Add Adreno 620
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-adreno-a620-v2-4-1d654c3f52d5@brar.si>
References: <20261023-adreno-a620-v2-0-1d654c3f52d5@brar.si>
In-Reply-To: <20261023-adreno-a620-v2-0-1d654c3f52d5@brar.si>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792745340; l=2351;
 i=patches@brar.si; h=from:subject:message-id;
 bh=tU61s/7XnImqnoXanHZtlX9L/8bbUJ87V/QXf+2mrqI=;
 b=OG6UaA9YwE3jmVOZ0IRBLIxk82gnLtPxhTtMjMEkVUhl1vSTVzrmwhVpXvvAMrBh2xa1Wwae1
 XDeSEWgm/KKBtxQn9doZl9UHBq9NAeGvqTYqEgHU/fsinYx/+kRMyH8
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the catalog entry for the Adreno 620 (chip id 0x06020000) found in
the Snapdragon 765/765G/768G (SM7250). It is an A650 derivative and
uses its SQE and GMU firmware and protect table, together with the A620
zap shader.

The speed-bin fuse values map to the OPP bins as in the downstream
"lito" devicetree: fuse 0 is the default bin and fuse 132 and 115 are
the two alternate ones.

The GMU clock gating mode is 0x00020202, which is what the downstream
driver programs on every A6xx except the A612 and A615 family. List the
SH0/MC0/ACV bus clock managers like the other A6xx and A7xx parts do, so
the bandwidth table is generated from the OPP table once it carries
bandwidth votes; until then the table added earlier in this series is
used. The bus widths are the ones the other parts use.

Signed-off-by: Ishu Brar <patches@brar.si>
---
 drivers/gpu/drm/msm/adreno/a6xx_catalog.c | 35 +++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/drivers/gpu/drm/msm/adreno/a6xx_catalog.c b/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
index 4ef2bd6e7..bea11ba6c 100644
--- a/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
+++ b/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
@@ -943,6 +943,41 @@ static const struct adreno_info a6xx_gpus[] = {
 			{ 169, 2 },
 			{ 180, 1 },
 		),
+	}, {
+		.chip_ids = ADRENO_CHIP_IDS(0x06020000),
+		.family = ADRENO_6XX_GEN3,
+		.fw = {
+			[ADRENO_FW_SQE] = "a650_sqe.fw",
+			[ADRENO_FW_GMU] = "a650_gmu.bin",
+		},
+		.gmem = SZ_512K,
+		.inactive_period = DRM_MSM_INACTIVE_PERIOD,
+		.quirks = ADRENO_QUIRK_HAS_CACHED_COHERENT |
+			  ADRENO_QUIRK_HAS_HW_APRIV,
+		.funcs = &a6xx_gpu_funcs,
+		.zapfw = "a620_zap.mbn",
+		.a6xx = &(const struct a6xx_info) {
+			.hwcg = a620_hwcg,
+			.protect = &a650_protect,
+			.gbif_cx = a640_gbif,
+			.gmu_cgc_mode = 0x00020202,
+			.prim_fifo_threshold = 0x00010000,
+			.bcms = (const struct a6xx_bcm[]) {
+				{ .name = "SH0", .buswidth = 16 },
+				{ .name = "MC0", .buswidth = 4 },
+				{
+					.name = "ACV",
+					.fixed = true,
+					.perfmode = BIT(3),
+				},
+				{ /* sentinel */ },
+			},
+		},
+		.speedbins = ADRENO_SPEEDBINS(
+			{ 0,   0 },
+			{ 132, 1 },
+			{ 115, 3 },
+		),
 	}, {
 		.chip_ids = ADRENO_CHIP_IDS(0x06020100),
 		.family = ADRENO_6XX_GEN3,

-- 
2.56.0

