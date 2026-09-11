From: =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
Date: Fri, 11 Sep 2026 11:51:04 +0300
Subject: [PATCH RFC 07/10] drm/msm/dpu: describe SM6125 programmable-fetch
 delayed-start quirk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260911-ginkgo-submission-final-v1-7-0e68e63a18d4@gmail.com>
References: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
In-Reply-To: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, freedreno@lists.freedesktop.org, 
 =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789116671; l=4060;
 i=kavakliyigitcan@gmail.com; s=20260911; h=from:subject:message-id;
 bh=dCreEw0ry0ghroTxWJf7tgoAXBd+986oDcr+3tTl2VM=;
 b=KYl/lRrMDLhvHmU1okl6IBNSYl8H3UZgdc2FxvgWCppoBUwtEFIZVK5FOVUPt7/MCw61kGQkv
 KJLS3g1uVXIC9D2IU3cjGrSuCaC0umPhHpUeGM0zuoT1TWfIB4deo3w
X-Developer-Key: i=kavakliyigitcan@gmail.com; a=ed25519;
 pk=W2GaxVotULs2vAjRMMLheaDtMMYs4037zO1LVVfFtPI=
X-Endpoint-Received: by B4 Relay for kavakliyigitcan@gmail.com/20260911 with auth_id=1024
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Qualcomm SM6125 (Snapdragon 665 / Trinket DPU 5.4.0), calculating the
programmable prefetch start counter strictly as:

    (vert_total - vfp_fetch_lines) * horiz_total + 1

causes the fetch trigger to evaluate on the active-video to vertical
front porch line boundary. In hardware, this triggers an internal line
buffer FIFO conflict within the INTF timing generator, resulting in
immediate DSI FIFO overflow and timeout errors (status=5) and complete
loss of pixel output.

Qualcomm downstream display drivers mitigate this erratum via
delay_prg_fetch_start = true, delaying the fetch start by one scanline
(+ horiz_total) into vertical front porch line 1.

Introduce 'has_prg_fetch_delay' in struct dpu_caps, enable it for SM6125
in its catalog entry, and throttle fetch start in programmable_fetch_config()
when the capability is set.

Signed-off-by: YİĞİTCAN KAVAKLI <kavakliyigitcan@gmail.com>
---
 drivers/gpu/drm/msm/disp/dpu1/catalog/dpu_5_4_sm6125.h |  1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_vid.c   | 11 +++++++++++
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.h         |  2 ++
 3 files changed, 14 insertions(+)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/catalog/dpu_5_4_sm6125.h b/drivers/gpu/drm/msm/disp/dpu1/catalog/dpu_5_4_sm6125.h
index 64be51e301591b7f17918475a957623c6fea23d4..ec0315284e0663f57a41a1fdf515d948c3d40d68 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/catalog/dpu_5_4_sm6125.h
+++ b/drivers/gpu/drm/msm/disp/dpu1/catalog/dpu_5_4_sm6125.h
@@ -13,6 +13,7 @@ static const struct dpu_caps sm6125_dpu_caps = {
 	.max_mixer_blendstages = 0x6,
 	.has_dim_layer = true,
 	.has_idle_pc = true,
+	.has_prg_fetch_delay = true,
 	.max_linewidth = 2160,
 	.pixel_ram_size = DEFAULT_PIXEL_RAM_SIZE,
 	.max_hdeci_exp = MAX_HORZ_DECIMATION,
diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_vid.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_vid.c
index ba810f26ea3099106aac1783f7f6bf5e014e41a0..15445eaf9f3baf4661e22bee133cc2059a3cd2b1 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_vid.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder_phys_vid.c
@@ -237,10 +237,21 @@ static void programmable_fetch_config(struct dpu_encoder_phys *phys_enc,
 
 	vfp_fetch_lines = programmable_fetch_get_num_lines(phys_enc, timing);
 	if (vfp_fetch_lines) {
+		const struct dpu_mdss_cfg *catalog = phys_enc->dpu_kms->catalog;
+
 		vert_total = get_vertical_total(timing);
 		horiz_total = get_horizontal_total(timing);
 		vfp_fetch_start_vsync_counter =
 		    (vert_total - vfp_fetch_lines) * horiz_total + 1;
+
+		/*
+		 * SM6125 (DPU 5.4 / Trinket) quirk matching downstream
+		 * delay_prg_fetch_start = true. Throttle fetch start
+		 * to the second line after active video (VFP line 1).
+		 */
+		if (catalog && catalog->caps && catalog->caps->has_prg_fetch_delay)
+			vfp_fetch_start_vsync_counter += horiz_total;
+
 		f.enable = 1;
 		f.fetch_start = vfp_fetch_start_vsync_counter;
 	}
diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.h b/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.h
index f45faf87333e89bbd463504ae3219609ef6209bd..db3cbf9fa04a13baf3ac40390757ed24120ccccd 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.h
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.h
@@ -273,6 +273,7 @@ struct dpu_rotation_cfg {
  * @has_dim_layer      dim layer feature status
  * @has_idle_pc        indicate if idle power collapse feature is supported
  * @has_3d_merge       indicate if 3D merge is supported
+ * @has_prg_fetch_delay indicate if programmable fetch start requires a 1-line delay
  * @max_linewidth      max linewidth for sspp
  * @pixel_ram_size     size of latency hiding and de-tiling buffer in bytes
  * @max_hdeci_exp      max horizontal decimation supported (max is 2^value)
@@ -285,6 +286,7 @@ struct dpu_caps {
 	bool has_dim_layer;
 	bool has_idle_pc;
 	bool has_3d_merge;
+	bool has_prg_fetch_delay;
 	/* SSPP limits */
 	u32 max_linewidth;
 	u32 pixel_ram_size;

-- 
2.47.3

