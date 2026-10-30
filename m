From: Igor Velkov <iav@iav.lv>
Date: Fri, 30 Oct 2026 06:43:21 +0200
Subject: [PATCH] drm/panfrost: Gate the RK3399 GPU clock in runtime suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-panfrost-rk3399-pm-rt-v1-1-e94437159a9d@iav.lv>
X-B4-Tracking: v=1; b=H4sIAGgg5GoC/x3MQQqAIBBA0avErBvQhMKuEi1ExxoikzEiiO6et
 HyL/x8oJEwFxuYBoYsLH6lCtw341aWFkEM1dKrrtTIKs0tRjnKibMZYi3lHOdGTM9HrwapgobZ
 ZKPL9f6f5fT9c1dbTZwAAAA==
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1888; i=iav@iav.lv;
 h=from:subject:message-id; bh=aee4514usbOrnKBJFpIWBVeVFNuEk+tVTdQcWikAb04=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlPFLLOSB8ueTB1946dbsLytj3Moo8S1xtIW4sndIR+v
 7bd2nJWRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZjIhVkM//Q7npVszd0963Zd
 2oV1yvyt9yTsRLr/X5zN+ntr6snTzcmMDF9lnhourWM5pFXj6FZrvLLt5sZfk0p7bSNiTbL/x2a
 YMwIA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3399 Mali-T860 matches arm,mali-t860 and gets default_data, so
panfrost enables aclk_gpu at probe and keeps it enabled until unbind;
runtime suspend powers the GPU off but leaves the clock on.

On ROCK Pi 4A restore from hibernation hangs in genpd_restore_noirq()
of the GPU while panfrost is bound. With the clock gated in runtime
suspend, as on the Allwinner H616 and the Renesas parts, it restores.

Match rockchip,rk3399-mali to default_pm_rt_data.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ROCK Pi 4A, drm-misc-next 33ed26235db9 with the rkvdec fix [1]
applied: hibernation with HDMI active restores 6 of 6 with this patch
(once right after glmark2-es2-drm), and hangs 2 of 2 without it.
[1] fixes the same kind of hang in rkvdec, which otherwise hits first.

[1] https://lore.kernel.org/r/20261030-rkvdec-runtime-pm-clocks-v1-1-fb2c5b629e79@iav.lv
---
 drivers/gpu/drm/panfrost/panfrost_drv.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_drv.c b/drivers/gpu/drm/panfrost/panfrost_drv.c
index 7c348a0bf1ee..21a9a12abefc 100644
--- a/drivers/gpu/drm/panfrost/panfrost_drv.c
+++ b/drivers/gpu/drm/panfrost/panfrost_drv.c
@@ -983,6 +983,7 @@ static const struct of_device_id dt_match[] = {
 	  .data = &amlogic_data, },
 	{ .compatible = "renesas,r9a08g046-mali", .data = &default_pm_rt_data },
 	{ .compatible = "renesas,r9a09g047-mali", .data = &default_pm_rt_data },
+	{ .compatible = "rockchip,rk3399-mali", .data = &default_pm_rt_data },
 	{ .compatible = "arm,mali-t604", .data = &default_data, },
 	{ .compatible = "arm,mali-t624", .data = &default_data, },
 	{ .compatible = "arm,mali-t628", .data = &default_data, },

---
base-commit: 33ed26235db93162935d1719bc6f538c384a2fd8
change-id: 20261030-panfrost-rk3399-pm-rt-cea3fc1790d9

Best regards,
-- 
Igor Velkov <iav@iav.lv>

