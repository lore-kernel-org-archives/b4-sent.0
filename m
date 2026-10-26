From: Xi Zhang <xz.ca.cn@gmail.com>
Date: Mon, 26 Oct 2026 16:16:56 -0300
Subject: [PATCH 8/8] drm/msm/dpu: reset DSC_CMN_MAIN_CNF in dsc disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-msm-dpu-res-clean-v1-8-f46130a8a717@gmail.com>
References: <20261026-msm-dpu-res-clean-v1-0-f46130a8a717@gmail.com>
In-Reply-To: <20261026-msm-dpu-res-clean-v1-0-f46130a8a717@gmail.com>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Xi Zhang <xz.ca.cn@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793042236; l=1211;
 i=xz.ca.cn@gmail.com; s=20261026; h=from:subject:message-id;
 bh=wGiN+gugp5FNldO/Kg3sFcSJT75myNdU6h5lxozuNKM=;
 b=nZsMcnqOnHbzY5XUKzRyVEOuXUJzxph+ChWqkFDxajHQLKX7ODGcxSaWtu3dJ/g1DTLbZ35fj
 Bk/lg76NhylDt2yhCP9gqPDgJf7pbvrQ9fVMgbXzok2zcQP0f1LC/fE
X-Developer-Key: i=xz.ca.cn@gmail.com; a=ed25519;
 pk=aRUll5L3eJbwG8Y4BO9uySKGzm+Uy+Ccei9prnRVZRs=
X-Endpoint-Received: by B4 Relay for xz.ca.cn@gmail.com/20261026 with auth_id=1328
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From observation, DSC_CMN_MAIN_CNF has hardware restriction on
differing values between paired even/odd dsc.

Reset it to 0 when dsc disable to avoid issues when a dsc pair
is later used individually for each of its dsc.

Note that currently dpu always assigns dsc in pairs if possible
for power saving. In the future, it may be desired to assign
singular dsc if possible to support high display count. e.g.
when dsc for DisplayPort support is added.

Tested on Ayaneo Pocket DS (SM8550 Kalama)

Signed-off-by: Xi Zhang <xz.ca.cn@gmail.com>
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_dsc_1_2.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_dsc_1_2.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_dsc_1_2.c
index b3395e9c34a1..b8a330d813e6 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_dsc_1_2.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_hw_dsc_1_2.c
@@ -78,6 +78,7 @@ static void dpu_hw_dsc_disable_1_2(struct dpu_hw_dsc *hw_dsc)
 
 	hw = &hw_dsc->hw;
 	sblk = hw_dsc->caps->sblk;
+	DPU_REG_WRITE(hw, DSC_CMN_MAIN_CNF, 0);
 	DPU_REG_WRITE(hw, sblk->ctl.base + DSC_CFG, 0);
 
 	DPU_REG_WRITE(hw, sblk->enc.base + ENC_DF_CTRL, 0);

-- 
2.55.0

