From: Zhendong Liu <yzddmr6@gmail.com>
Date: Fri, 27 Nov 2026 23:24:37 +0800
Subject: [PATCH v2] drm/msm/dsi: Fix double put of the PHY device on probe
 deferral
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-upstream2-msm-dsi-phy-ref-v2-1-be82aab71166@gmail.com>
X-B4-Tracking: v=1; b=H4sIALSgCWsC/42Oyw6CMBBFf8V07SAtL+PK/zAs+higxgLpAJEQ/
 t0WE9cuz507J3djhN4isdtpYx4XS3boA4jzielO9i2CNYGZSEXJuUhhHmnyKJ0ARw4MWRi7FTw
 2oLDJjMbMNFiy8D+G0L4P96P+Ms3qiXqKwthQkhCUl73uYvRTX47DUiU5eJ3FZmdpGvx6zFx4N
 P6zaOHAwYiyUtfKFHnR3Fsn7SvRg2P1vu8ffpuClv4AAAA=
X-Change-ID: 20261120-upstream2-msm-dsi-phy-ref-bef3dce3dfe6
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Miaoqian Lin <linmq006@gmail.com>, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>, 
 linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Zhendong Liu <yzddmr6@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795793078; l=2946;
 i=yzddmr6@gmail.com; s=20261028; h=from:subject:message-id;
 bh=7pDeVytCnO+Ht8gillWTKBsW0hZk8jkNgWUnJt2sCQc=;
 b=OP/iel1IqGfob8BkPZuho3vNQCEgYSMhN1s5aYKbitq3QmqUqaPt8DOPBLz+9gYhVM0WI8chv
 FLaoDIVNTruAwtKO+up8aAXOqEGzDbNxK6geJVWNHxPH5Pf8bqEBBP1
X-Developer-Key: i=yzddmr6@gmail.com; a=ed25519;
 pk=QLT2mwairk4R38oU379hkHynqjoLrlqd0Cl1ERUqIqY=
X-Endpoint-Received: by B4 Relay for yzddmr6@gmail.com/20261028 with auth_id=1489
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 6977cc89c875 ("drm/msm/dsi: Fix some reference counted
resource leaks"), dsi_get_phy() stores the PHY device it looked up in
msm_dsi->phy_dev before it checks whether the PHY driver has bound, and
dsi_destroy() drops that reference. dsi_init() calls dsi_destroy() when
dsi_get_phy() fails.

Commit c04c3148ca12 ("drm/msm/dsi: Fix missing put_device() call in
dsi_get_phy") then added a put_device() for the case where the PHY
device exists but has no driver data yet. In that case the reference is
now dropped twice, once in dsi_get_phy() and again in dsi_destroy(), so
each probe deferral for this reason takes one reference too many from
the PHY platform device. Enough deferrals underflow its refcount and
free it while it is still registered.

fw_devlink normally keeps the DSI host from probing before its PHY has
bound. The path is reached with fw_devlink=permissive or off, and after
the deferred probe timeout when no driver matches the PHY device, as
the device link is relaxed then and every probe retry of the DSI host
drops another reference.

Drop the put_device() and leave the reference to dsi_destroy(). This
effectively reverts that commit and brings back the single check that
it split in two.

The double put was found with the help of an AI coding assistant during
a review of the driver.

Fixes: c04c3148ca12 ("drm/msm/dsi: Fix missing put_device() call in dsi_get_phy")
Signed-off-by: Zhendong Liu <yzddmr6@gmail.com>
---
Found by reading the code; I have not hit this on hardware, and there
is no reproducer. Build-tested only: drivers/gpu/drm/msm/ with W=1
(arm64 defconfig) on the base commit below, no new warnings.

I used an AI coding assistant for this work. It found the double put
while reviewing the driver and drafted this patch and changelog. I have
reviewed the change.
---
Changes in v2:
- Use my legal name in the From: and Signed-off-by: lines, as requested.
- Link to v1: https://patch.msgid.link/20261120-upstream2-msm-dsi-phy-ref-v1-1-d267b87d545f@gmail.com
---
 drivers/gpu/drm/msm/dsi/dsi.c | 7 +------
 1 file changed, 1 insertion(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/msm/dsi/dsi.c b/drivers/gpu/drm/msm/dsi/dsi.c
index 090726be5061..5f9a1409432a 100644
--- a/drivers/gpu/drm/msm/dsi/dsi.c
+++ b/drivers/gpu/drm/msm/dsi/dsi.c
@@ -44,12 +44,7 @@ static int dsi_get_phy(struct msm_dsi *msm_dsi)
 
 	of_node_put(phy_node);
 
-	if (!phy_pdev) {
-		DRM_DEV_ERROR(&pdev->dev, "%s: phy driver is not ready\n", __func__);
-		return -EPROBE_DEFER;
-	}
-	if (!msm_dsi->phy) {
-		put_device(&phy_pdev->dev);
+	if (!phy_pdev || !msm_dsi->phy) {
 		DRM_DEV_ERROR(&pdev->dev, "%s: phy driver is not ready\n", __func__);
 		return -EPROBE_DEFER;
 	}

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261120-upstream2-msm-dsi-phy-ref-bef3dce3dfe6

Best regards,
--  
Zhendong Liu <yzddmr6@gmail.com>

