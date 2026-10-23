From: Ishu Brar <patches@brar.si>
Date: Fri, 23 Oct 2026 14:19:00 +0530
Subject: [PATCH v2 2/4] drm/msm/a6xx: Add a bandwidth table for the Adreno
 620 GMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-adreno-a620-v2-2-1d654c3f52d5@brar.si>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792745340; l=3158;
 i=patches@brar.si; h=from:subject:message-id;
 bh=ZgldijA3JDgDsTY5MOw8s5Wh1FCac7/xjEdjhBWUFz8=;
 b=PNMT/GH5Th4EWpLP567H9jPExcocaDeL/mKA6+DjOYItbWDx5d6oy+g0qVJ+1//kwvQY5AWvc
 8RozAjkVxWUD9h0+6IynxGRDilXyhpcv+7C8sGEiqAmZsmPOORsMXSo
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without an A620 specific table the GMU falls back to the generic A630
one, whose BCM addresses do not exist on SM7250, and the first GX
performance vote times out.

Like the A650 one, send a single "off" entry just to get things running,
with the BCM addresses looked up in cmd-db. This is only used while the
GPU OPP table has no bandwidth levels; with them, the table is generated
from the BCMs listed in the catalog entry. Add adreno_is_a620() for the
selection.

Assisted-by: Claude
Signed-off-by: Ishu Brar <patches@brar.si>
---
 drivers/gpu/drm/msm/adreno/a6xx_hfi.c   | 34 +++++++++++++++++++++++++++++++++
 drivers/gpu/drm/msm/adreno/adreno_gpu.h |  5 +++++
 2 files changed, 39 insertions(+)

diff --git a/drivers/gpu/drm/msm/adreno/a6xx_hfi.c b/drivers/gpu/drm/msm/adreno/a6xx_hfi.c
index 6b34e704a..b59853678 100644
--- a/drivers/gpu/drm/msm/adreno/a6xx_hfi.c
+++ b/drivers/gpu/drm/msm/adreno/a6xx_hfi.c
@@ -553,6 +553,38 @@ static void a650_build_bw_table(struct a6xx_hfi_msg_bw_table *msg)
 	msg->cnoc_cmds_data[1][0] =  0x60000001;
 }
 
+static void a620_build_bw_table(struct a6xx_hfi_msg_bw_table *msg)
+{
+	/*
+	 * Used when the OPP table has no bandwidth levels, otherwise the
+	 * table is generated from the BCMs in the catalog. Send a single
+	 * "off" entry just to get things running.
+	 */
+	msg->bw_level_num = 1;
+
+	msg->ddr_cmds_num = 3;
+	msg->ddr_wait_bitmask = 0x01;
+
+	msg->ddr_cmds_addrs[0] = cmd_db_read_addr("MC0");
+	msg->ddr_cmds_addrs[1] = cmd_db_read_addr("SH0");
+	msg->ddr_cmds_addrs[2] = cmd_db_read_addr("ACV");
+
+	msg->ddr_cmds_data[0][0] =  0x40000000;
+	msg->ddr_cmds_data[0][1] =  0x40000000;
+	msg->ddr_cmds_data[0][2] =  0x40000000;
+
+	/*
+	 * These are the CX (CNOC) votes - these are used by the GMU but the
+	 * votes are known and fixed for the target
+	 */
+	msg->cnoc_cmds_num = 1;
+	msg->cnoc_wait_bitmask = 0x01;
+
+	msg->cnoc_cmds_addrs[0] = cmd_db_read_addr("CN0");
+	msg->cnoc_cmds_data[0][0] =  0x40000000;
+	msg->cnoc_cmds_data[1][0] =  0x60000001;
+}
+
 static void a690_build_bw_table(struct a6xx_hfi_msg_bw_table *msg)
 {
 	/*
@@ -818,6 +850,8 @@ static int a6xx_hfi_send_bw_table(struct a6xx_gmu *gmu)
 		a619_build_bw_table(msg);
 	else if (adreno_is_a640_family(adreno_gpu))
 		a640_build_bw_table(msg);
+	else if (adreno_is_a620(adreno_gpu))
+		a620_build_bw_table(msg);
 	else if (adreno_is_a650(adreno_gpu))
 		a650_build_bw_table(msg);
 	else if (adreno_is_7c3(adreno_gpu))
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

