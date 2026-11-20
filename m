From: yzddMr6 <yzddmr6@gmail.com>
Date: Fri, 20 Nov 2026 21:12:58 +0800
Subject: [PATCH] drm/msm/dsi: Fix double put of the PHY device on probe
 deferral
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-upstream2-msm-dsi-phy-ref-v1-1-d267b87d545f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFlHAGsC/z2MywrCMBBFf6XM2tEmkQr+irjIY2IiJJZMW5TSf
 zep4PLcx1mBqURiuHYrFFoix1euIA4d2KDzgzC6yiB7OQghe5xHngrpJDFxQscRx/DBQh4NeeU
 sKedpgPofaxjfu/t2/zHP5kl2asK2MJoJTdHZhhb91ae9WC7HMxarYNu+Btjip6cAAAA=
X-Change-ID: 20261120-upstream2-msm-dsi-phy-ref-bef3dce3dfe6
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>
Cc: Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Miaoqian Lin <linmq006@gmail.com>, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>, 
 linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 yzddMr6 <yzddmr6@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795180379; l=2738;
 i=yzddmr6@gmail.com; s=20261028; h=from:subject:message-id;
 bh=UCVOCZGuxoSVYeQlAgN1/asYu4mtdgFa/QW169bkdC0=;
 b=7QmFwZrvmrODkce+oy/gZC9S60KYzd01Pcnk2A90Mlmot2xKuEHEWd+NWCw/J7sx7fn96rqNt
 8HLm21FetuqBbfXBNqL78hOjmlhrRxBqtU5JJms6lLdvRn58302t7l3
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
Signed-off-by: yzddMr6 <yzddmr6@gmail.com>
---
Found by reading the code; I have not hit this on hardware, and there
is no reproducer. Build-tested only: drivers/gpu/drm/msm/ with W=1
(arm64 defconfig) on the base commit below, no new warnings.

I used an AI coding assistant for this work. It found the double put
while reviewing the driver and drafted this patch and changelog. I have
reviewed the change.
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
yzddMr6 <yzddmr6@gmail.com>

