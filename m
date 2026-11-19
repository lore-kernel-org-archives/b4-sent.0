From: =?utf-8?q?Alexandru_Andrie=C8=99?= <alex.andries.aa@gmail.com>
Date: Thu, 19 Nov 2026 01:47:58 +0100
Subject: [PATCH] drm/msm/dpu: use single DSC encoder when slice_count is 1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261119-upstream-drm-msm-dpu-dsc-single-slice-v1-v1-1-4744ad5b9747@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQrCMBCF4auUWTtgirXWq4iLOBnrSBPDTFOE0
 rsbdfX4Nv9bwViFDc7NCsqLmLxShds1QA+fRkYJ1dDu26NzbsCSbVb2EYNGjFY3FwxGaJLGidE
 mIcbFYdf1RL6n4XQgqLmsfJf37+py/dvK7ck0f/uwbR/+4X6DjAAAAA==
X-Change-ID: 20261119-upstream-drm-msm-dpu-dsc-single-slice-v1-557cca7c984c
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 =?utf-8?q?Alexandru_Andrie=C8=99?= <alex.andries.aa@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795049300; l=2415;
 i=alex.andries.aa@gmail.com; s=20261118; h=from:subject:message-id;
 bh=f5QJmSYrdCgoJ98DDgeJ718yQzeQFrq5DX9OKNMAinQ=;
 b=rXC2vTGceRQp0u2V8QoFCw7XfnzFKhnBDOn2ug/aufs/tPdEbAjHloh/v8jz8fV6yqUYOOnsT
 ZnHYpjgXT73D+qJA46bwgRoo3hvneMu/5Zh6S3+xMEJw2zW2w+qLN80
X-Developer-Key: i=alex.andries.aa@gmail.com; a=ed25519;
 pk=kNAqgavfB7uUd1mA8o8TszhGxzyqBwY71PGO/oK4v84=
X-Endpoint-Received: by B4 Relay for alex.andries.aa@gmail.com/20261118 with auth_id=1564
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dpu_encoder_update_topology() currently selects 2 DSC encoders whenever
catalog->dsc_count >= 2, even when the panel only uses a single DSC
slice (dsc->slice_count == 1).

A single slice cannot be split across two DSC encoders: merge mode
halves the per-encoder input width below slice_width and, on DPU 7.0+,
computes num_active_slice_per_enc = dsc->slice_count / 2 = 0 in
dpu_hw_dsc_config_1_2(), dividing by zero in
_dsc_calc_output_buf_max_addr().

Require dsc->slice_count >= 2 before selecting 2 DSC encoders on a
single interface so single-slice panels use 1 DSC encoder.

Fixes: b6090ffb30f3 ("drm/msm/dpu: Fall back to a single DSC encoder (1:1:1) on small SoCs")
Cc: stable@vger.kernel.org
Signed-off-by: Alexandru Andrieș <alex.andries.aa@gmail.com>
---
Testing:
- Tested on a Xiaomi MIX 4 (SM8350, DPU 7.0) with a 1080x2400@120Hz
  single-DSI single-slice DSC panel; dual-DSI topologies were not
  hardware-tested.

AI disclosure:
- Debugged and drafted with assistance from Gemini 4 Carbon
  (Antigravity), and reviewed and tested on hardware by the submitter.
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
index 0a6be69a3e83..ffccee6b41f1 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c
@@ -680,13 +680,14 @@ void dpu_encoder_update_topology(struct drm_encoder *drm_enc,
 		/*
 		 * Use 2 DSC encoders, 2 layer mixers and 1 or 2 interfaces
 		 * when Display Stream Compression (DSC) is enabled,
-		 * and when enough DSC blocks are available.
+		 * and when enough DSC blocks and slices are available.
 		 * This is power-optimal and can drive up to (including) 4k
 		 * screens.
 		 */
 		WARN(topology->num_intf > 2,
 		     "DSC topology cannot support more than 2 interfaces\n");
-		if (topology->num_intf >= 2 || dpu_kms->catalog->dsc_count >= 2)
+		if (topology->num_intf >= 2 ||
+		    (dpu_kms->catalog->dsc_count >= 2 && dsc->slice_count >= 2))
 			topology->num_dsc = 2;
 		else
 			topology->num_dsc = 1;

---
base-commit: 97d73c8251226cf27cc6656b4c542869bb8c69fa
change-id: 20261119-upstream-drm-msm-dpu-dsc-single-slice-v1-557cca7c984c

Best regards,
--  
Alexandru Andrieș <alex.andries.aa@gmail.com>

