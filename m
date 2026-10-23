From: Ishu Brar <patches@brar.si>
Date: Fri, 23 Oct 2026 15:23:32 +0530
Subject: [PATCH v3 2/4] drm/msm/a6xx: Program the PDC sequencer on Adreno
 620
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-adreno-a620-v3-2-2d1d566e5e13@brar.si>
References: <20261023-adreno-a620-v3-0-2d1d566e5e13@brar.si>
In-Reply-To: <20261023-adreno-a620-v3-0-2d1d566e5e13@brar.si>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792749211; l=5355;
 i=patches@brar.si; h=from:subject:message-id;
 bh=Obs8CON0X6HWKVk8YPJT/kXnMrbnAoIHP9bqVC978ec=;
 b=jyX1ZvF9oDj+esowCc1UUn9to4UyZo7aYH8B7Ut0tLXoAz5FLwMW/xx0JGLyDxJmySDapmjij
 r5fnK+yXTDxAFwnq58wNnjeJGBGUgahrZxeOV8qJyYABOTKinZyhuok
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unlike the rest of the A650 family, the A620 does not get its PDC set up
by AOP (the downstream devicetree has no pdc_in_aop for it). Without the
sequence, the RSC never acks the second power-up ("Unable to power on
the GPU RSC") and the device hangs.

Program the sequence from the driver, taking the xo, mx and cx resource
addresses from cmd-db instead of the hardcoded ones. Like the downstream
driver, also program the VRM command when cmd-db has a vrm.soc resource.
Add adreno_is_a620() for the selection.

Assisted-by: Claude
Signed-off-by: Ishu Brar <patches@brar.si>
---
 drivers/gpu/drm/msm/adreno/a6xx_gmu.c   | 35 +++++++++++++++++++++++++++------
 drivers/gpu/drm/msm/adreno/adreno_gpu.h |  5 +++++
 2 files changed, 34 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/msm/adreno/a6xx_gmu.c b/drivers/gpu/drm/msm/adreno/a6xx_gmu.c
index 662f09bec..8d426f1f1 100644
--- a/drivers/gpu/drm/msm/adreno/a6xx_gmu.c
+++ b/drivers/gpu/drm/msm/adreno/a6xx_gmu.c
@@ -686,6 +686,7 @@ static void a6xx_gmu_rpmh_init(struct a6xx_gmu *gmu)
 	u32 seqmem0_drv0_reg = REG_A6XX_RSCC_SEQ_MEM_0_DRV0;
 	void __iomem *seqptr = NULL;
 	uint32_t pdc_address_offset;
+	u32 mx_addr = 0x30010, cx_addr = 0x30000, vrm_addr = 0;
 	void __iomem *pdcptr;
 	bool pdc_in_aop = false;
 
@@ -697,8 +698,18 @@ static void a6xx_gmu_rpmh_init(struct a6xx_gmu *gmu)
 	if (IS_ERR(pdcptr))
 		return;
 
-	if (adreno_is_a650_family(adreno_gpu) ||
-	    adreno_is_a7xx(adreno_gpu))
+	/* Unlike the rest of the A650 family, A620 has no PDC setup from AOP */
+	if (adreno_is_a620(adreno_gpu)) {
+		pdc_address_offset = cmd_db_read_addr("xo.lvl");
+		mx_addr = cmd_db_read_addr("mx.lvl");
+		cx_addr = cmd_db_read_addr("cx.lvl");
+		vrm_addr = cmd_db_read_addr("vrm.soc");
+		if (!pdc_address_offset || !mx_addr || !cx_addr) {
+			DRM_DEV_ERROR(gmu->dev, "No PDC resource addresses in cmd-db\n");
+			return;
+		}
+	} else if (adreno_is_a650_family(adreno_gpu) ||
+		 adreno_is_a7xx(adreno_gpu))
 		pdc_in_aop = true;
 	else if (adreno_is_a618(adreno_gpu) || adreno_is_a640_family(adreno_gpu))
 		pdc_address_offset = 0x30090;
@@ -766,25 +777,31 @@ static void a6xx_gmu_rpmh_init(struct a6xx_gmu *gmu)
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD_WAIT_FOR_CMPL_BANK, 0);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CONTROL, 0);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_MSGID, 0x10108);
-	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_ADDR, 0x30010);
+	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_ADDR, mx_addr);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_DATA, 1);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_MSGID + 4, 0x10108);
-	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_ADDR + 4, 0x30000);
+	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_ADDR + 4, cx_addr);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_DATA + 4, 0x0);
 
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_MSGID + 8, 0x10108);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_ADDR + 8, pdc_address_offset);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_DATA + 8, 0x0);
 
+	if (vrm_addr) {
+		pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_MSGID + 12, 0x10108);
+		pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_ADDR + 12, vrm_addr + 0x4);
+		pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS1_CMD0_DATA + 12, 0x0);
+	}
+
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD_ENABLE_BANK, 7);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD_WAIT_FOR_CMPL_BANK, 0);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CONTROL, 0);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_MSGID, 0x10108);
-	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_ADDR, 0x30010);
+	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_ADDR, mx_addr);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_DATA, 2);
 
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_MSGID + 4, 0x10108);
-	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_ADDR + 4, 0x30000);
+	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_ADDR + 4, cx_addr);
 	if (adreno_is_a618(adreno_gpu) || adreno_is_a619(adreno_gpu) ||
 			adreno_is_a650_family(adreno_gpu))
 		pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_DATA + 4, 0x2);
@@ -794,6 +811,12 @@ static void a6xx_gmu_rpmh_init(struct a6xx_gmu *gmu)
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_ADDR + 8, pdc_address_offset);
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_DATA + 8, 0x3);
 
+	if (vrm_addr) {
+		pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_MSGID + 12, 0x10108);
+		pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_ADDR + 12, vrm_addr + 0x4);
+		pdc_write(pdcptr, REG_A6XX_PDC_GPU_TCS3_CMD0_DATA + 12, 0x1);
+	}
+
 	/* Setup GPU PDC */
 setup_pdc:
 	pdc_write(pdcptr, REG_A6XX_PDC_GPU_SEQ_START_ADDR, 0);
diff --git a/drivers/gpu/drm/msm/adreno/adreno_gpu.h b/drivers/gpu/drm/msm/adreno/adreno_gpu.h
index 4b2156825..b77502446 100644
--- a/drivers/gpu/drm/msm/adreno/adreno_gpu.h
+++ b/drivers/gpu/drm/msm/adreno/adreno_gpu.h
@@ -443,6 +443,11 @@ static inline int adreno_is_a619_holi(const struct adreno_gpu *gpu)
 	return adreno_is_a619(gpu) && adreno_has_gmu_wrapper(gpu);
 }
 
+static inline int adreno_is_a620(const struct adreno_gpu *gpu)
+{
+	return gpu->info->chip_ids[0] == 0x06020000;
+}
+
 static inline int adreno_is_a621(const struct adreno_gpu *gpu)
 {
 	return gpu->info->chip_ids[0] == 0x06020100;

-- 
2.56.0

