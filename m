From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Tue, 24 Nov 2026 23:46:52 +0100
Subject: [PATCH] drm/msm/dpu: sc8180x: restore dp_phy_intf_sel on runtime
 resume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-drm-msm-dpu-sc8180x-resume-v1-1-a6201f43136d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAwA0F8ZORtYyhydvyIeNM00QudIVhmM/
 btVj+/yNnAxFYdTs4HJW11fUwUdGuDHdboLaqqG0IaeKHSYLGP2jGku6BwptiuaeMmCQmmgLvJ
 xIIYazCajrr/8fPnby+0pvHxH2PcPEEPraH4AAAA=
X-Change-ID: 20261124-drm-msm-dpu-sc8180x-resume-e1d9148c591c
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795560412; l=2603;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=LEmFhgAwoaN37Scx4SDiFsrI98URrH/adaZQ6fMNsJ0=;
 b=INOGyHygY6Tv+74+M2k8AElw9Kze/4QI4LXYWJ2VRw2Wk3YNQWM0+SiNE3nHBL94sYsecWXUa
 HgUlPP8KsSpA8ANTB4BLOKY1Mo6YH5QBEEFKWI083nhHrSJAUFPbakM
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SC8180X, MDP_DP_PHY_INTF_SEL is currently programmed only once during
dpu_kms_hw_init(). When MDSS/DPU loses register state across runtime PM
or s2idle suspend/resume, dpu_runtime_resume() restores VBIF memtypes
via dpu_vbif_init_memtypes() but leaves MDP_DP_PHY_INTF_SEL reset to
zero, misrouting eDP/DP output after resume.

Factor out dpu_kms_setup_dp_phy_intf_sel() and invoke it from both
dpu_kms_hw_init() and dpu_runtime_resume().

Fixes: be3415c620d1 ("drm/msm/dpu: Configure DP INTF/PHY selector")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Restore MDP_DP_PHY_INTF_SEL in dpu_runtime_resume() on SC8180X so eDP/DP
PHY routing survives MDSS runtime PM and s2idle power collapse.
---
 drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c b/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c
index 1b6286d..31166e7 100644
--- a/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c
+++ b/drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c
@@ -1135,6 +1135,16 @@ unsigned long dpu_kms_get_clk_rate(struct dpu_kms *dpu_kms, char *clock_name)
 
 #define	DPU_PERF_DEFAULT_MAX_CORE_CLK_RATE	412500000
 
+static void dpu_kms_setup_dp_phy_intf_sel(struct dpu_kms *dpu_kms)
+{
+	if (!dpu_kms->hw_mdp || !dpu_kms->hw_mdp->ops.dp_phy_intf_sel)
+		return;
+
+	if (of_device_is_compatible(dpu_kms->pdev->dev.of_node, "qcom,sc8180x-dpu"))
+		dpu_kms->hw_mdp->ops.dp_phy_intf_sel(dpu_kms->hw_mdp,
+						     (unsigned int[]){ 1, 2, });
+}
+
 static int dpu_kms_hw_init(struct msm_kms *kms)
 {
 	struct dpu_kms *dpu_kms;
@@ -1246,8 +1256,7 @@ static int dpu_kms_hw_init(struct msm_kms *kms)
 	 * the INTF <->DP relationship isn't static anymore, this needs to be
 	 * configured through the DT.
 	 */
-	if (of_device_is_compatible(dpu_kms->pdev->dev.of_node, "qcom,sc8180x-dpu"))
-		dpu_kms->hw_mdp->ops.dp_phy_intf_sel(dpu_kms->hw_mdp, (unsigned int[]){ 1, 2, });
+	dpu_kms_setup_dp_phy_intf_sel(dpu_kms);
 
 	dpu_kms->hw_intr = dpu_hw_intr_init(dev, dpu_kms->mmio, dpu_kms->catalog);
 	if (IS_ERR(dpu_kms->hw_intr)) {
@@ -1464,6 +1473,7 @@ static int __maybe_unused dpu_runtime_resume(struct device *dev)
 	}
 
 	dpu_vbif_init_memtypes(dpu_kms);
+	dpu_kms_setup_dp_phy_intf_sel(dpu_kms);
 
 	drm_for_each_encoder(encoder, ddev)
 		dpu_encoder_virt_runtime_resume(encoder);

---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261124-drm-msm-dpu-sc8180x-resume-e1d9148c591c

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

