From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:50 +0000
Subject: [PATCH 2/8] drm/rockchip: vop2: Fix the HDMI sync polarity on
 RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-vop2-fixes-v1-2-d336e9dd90d3@gmail.com>
References: <20261110-vop2-fixes-v1-0-d336e9dd90d3@gmail.com>
In-Reply-To: <20261110-vop2-fixes-v1-0-d336e9dd90d3@gmail.com>
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295129; l=1785;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=/jrSLrVkUlalHW0TPexjIwQp3BO194HjqfgHRaS4qLM=;
 b=HnWtJTR8ePkQiIPst0zqwNylcoBjEN4hJ2NMs1vb6p/D3dePg6kgqqaeDFKfjYqV5fqLL4PTw
 M0pNS36M2UzBZFvNVCTyoEy3Qc/sfBBXs8yb23ZIESbzqYckL4pb84j
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rk3588_set_intf_mux() passes the POLFLAG bits of the mode to
rk3588_get_hdmi_pol(), which decodes them as DRM mode flags: the
VSYNC_POSITIVE bit is taken for DRM_MODE_FLAG_NHSYNC and POLFLAG_DCLK_INV
for DRM_MODE_FLAG_NVSYNC. As a result GRF_VO1_CON0 marks the HSYNC of
every +HSync/+VSync mode (e.g. all 1080p, 2160p CTA modes) as negative
and both syncs of -HSync/-VSync modes (e.g. 720x480, 640x480) as
positive.

The bits in GRF_VO1_CON0 are set for a negative sync; that is how the
vendor kernel programs them (vop2_get_hdmi_pol(), called with the mode
flags, sets them for DRM_MODE_FLAG_NHSYNC/NVSYNC on RK3588). Decode the
POLFLAG bits accordingly.

Fixes: 5a028e8f062f ("drm/rockchip: vop2: Add support for rk3588")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
index 659fd0a3ab63..7c48b440cb29 100644
--- a/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
+++ b/drivers/gpu/drm/rockchip/rockchip_vop2_reg.c
@@ -1687,12 +1687,16 @@ static u32 rk3588_get_mipi_port_mux(int vp_id)
 		return 0;
 }
 
-static u32 rk3588_get_hdmi_pol(u32 flags)
+/*
+ * The HDMI sync polarity bits in GRF_VO1_CON0 are set for an active low
+ * (negative) sync.
+ */
+static u32 rk3588_get_hdmi_pol(u32 polflags)
 {
 	u32 val;
 
-	val = (flags & DRM_MODE_FLAG_NHSYNC) ? BIT(HSYNC_POSITIVE) : 0;
-	val |= (flags & DRM_MODE_FLAG_NVSYNC) ? BIT(VSYNC_POSITIVE) : 0;
+	val = (polflags & BIT(HSYNC_POSITIVE)) ? 0 : BIT(HSYNC_POSITIVE);
+	val |= (polflags & BIT(VSYNC_POSITIVE)) ? 0 : BIT(VSYNC_POSITIVE);
 
 	return val;
 }

-- 
2.55.0

