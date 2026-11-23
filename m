From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 17:33:26 +0000
Subject: [PATCH v3] drm/panfrost: Enable GPU_PM_RT for RK3399
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-panfrost-rk3399-pm-rt-v3-1-04c7c58d1140@iav.lv>
X-B4-Tracking: v=1; b=H4sIAOV4BGsC/4XOwQ6CMAyA4VchO1uzbijWk+9hPDSwyaIC6ciiI
 by7g4OejMe/Sb92UtFJcFEdi0mJSyGGvsthN4WqW+6uDkKTWxlt9qithoE7L30cQW7WEsHwABm
 hdmx9jRXphlTeHcT58Fzd8yV3G+LYy2s9k3CZ/hMTAoKjsrQV7oipOQVO23tSC5fMl0BjfhEmE
 6X2+S1kRj58iHme34wldAD6AAAA
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Daniel Stone <daniel@fooishbar.org>, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2865; i=iav@iav.lv;
 h=from:subject:message-id; bh=jVdmdH5Fy/vduyoI4gZY5e3ymBwUoj6ShIzYh5QXSJg=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNksFc8rdlg+iPedscv2zTeRq886bvTwXj389ETWup/Tx
 Yx0XCpfd5SyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJvNjCyLDxom9Vt/Cntm3z
 p2a3/bu646580qG17p4BC/eL/+p9a1fH8M+OY+r5VRVeDdumxLzwZV7zhZVPfseqbxx3Tm3hi2R
 78JkTAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3399 Mali-T860 matches arm,mali-t860 and gets default_data, so
panfrost enables aclk_gpu at probe and keeps it enabled until unbind;
runtime suspend powers the GPU off but leaves the clock on.

On ROCK Pi 4A restore from hibernation hangs in genpd_restore_noirq()
of the GPU when the hibernated kernel had panfrost bound and the
kernel that loads the image does not. There clk_disable_unused()
gates aclk_gpu, while the restored image still holds an enable count
on it, so powering the GPU domain back on does not ungate the clock.
With the clock gated in runtime suspend, as on the Allwinner H616 and
the Renesas RZ/G3L and RZ/G3E, restore completes.

Match rockchip,rk3399-mali to default_pm_rt_data, which differs from
default_data only in GPU_PM_RT.

Reviewed-by: Steven Price <steven.price@arm.com>
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ROCK Pi 4A, drm-misc-next c408466a4dfa with the rkvdec fix [1]
applied: hibernation restores 9 of 9 with this patch (3 with an HDMI
mode held, 3 right after glmark2-es2-drm, 3 idle), and the GPU renders
after restore. With the GPU node left with arm,mali-t860 only, restore
hangs 2 of 2, in genpd_restore_noirq() of the GPU.
[1] fixes the same kind of hang in rkvdec, which otherwise hits first;
this patch applies and builds without it.

[1] https://lore.kernel.org/r/20261030-rkvdec-runtime-pm-clocks-v2-1-8ff510a231de@iav.lv

Changes in v3:
- Retitle as Steven suggested, say what GPU_PM_RT changes
- Add Steven's Reviewed-by, given on v1 (same code)
- Link to v2: https://lore.kernel.org/r/20261122-panfrost-rk3399-pm-rt-v2-1-40f1791aa1a8@iav.lv

Changes in v2:
- Name the SoCs that already use default_pm_rt_data
- Say why restore hangs
- Rebase onto drm-misc-next
- Link to v1: https://lore.kernel.org/r/20261030-panfrost-rk3399-pm-rt-v1-1-e94437159a9d@iav.lv
---
 drivers/gpu/drm/panfrost/panfrost_drv.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_drv.c b/drivers/gpu/drm/panfrost/panfrost_drv.c
index eeda113037fe..91acfa13ef42 100644
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
base-commit: c408466a4dfaee4b12587e926c5b85e68c8b3c40
change-id: 20261030-panfrost-rk3399-pm-rt-cea3fc1790d9

Best regards,
-- 
Igor Velkov <iav@iav.lv>

