From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 19 Oct 2026 16:23:19 +0300
Subject: [PATCH] drm/mediatek: mtk_dsi: do not enable HS clock in
 pre-enable for LPM panels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-6768-dsi-fix-v1-1-3e5616b45a67@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0NLXTNzMwvdlOJM3bTMCl3LNINko+REo6REyzQloJaColSgMNi46Fg
 Iv7g0KSs1uQRkhlJtLQAoHfg2cAAAAA==
X-Change-ID: 20261019-6768-dsi-fix-9f0c2ca2ba9f
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 CK Hu <ck.hu@mediatek.com>, Gary Bisson <bisson.gary@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 stable@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792416200; l=2272;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=JSG4TWGCcAQcls3Iu49KLqCH7zkim5ue4YYLwNCf0vg=;
 b=a1priHrWzzd5wggrEpf0KowBgM/lZiW5nLcwsUa91RhGy3yUoUHijxKnHdjdQOHPpFcIKUe5F
 nDuzITpaye8CDsDEK32e6TtMCcHv+eia4EKvKhzllTtgq97gUzNtITe
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 76255024cadb ("drm/mediatek: mtk_dsi: enable hs clock during
pre-enable") moved HS clock enablement from the mtk_output_dsi_enable()
to mtk_dsi_poweron(). Later, the commit 3e191eddbdcb ("drm/mediatek:
mtk_dsi: Enable HS clock only at pre-enable") moved the call to the
mtk_dsi_bridge_atomic_pre_enable().

However, mtk_dsi_lane_ready() explicitly sets mtk_dsi_clk_hs_mode(dsi, 0)
so that DSI panels with MIPI_DSI_MODE_LPM can transmit initialization
commands in Low-Power mode during their prepare() callback. Enabling the
HS clock unconditionally in mtk_dsi_bridge_atomic_pre_enable() overrides
this before panel prepare() runs, causing command transmission to fail.

Only enable the HS clock in mtk_dsi_bridge_atomic_pre_enable(), when
MIPI_DSI_MODE_LPM is not set, and restore mtk_dsi_clk_hs_mode(dsi, 1) in
mtk_output_dsi_enable(). This is no-op for non-LPM bridges.

Fixes: 76255024cadb ("drm/mediatek: mtk_dsi: enable hs clock during pre-enable")
Fixes: 3e191eddbdcb ("drm/mediatek: mtk_dsi: Enable HS clock only at pre-enable")
Cc: stable@vger.kernel.org
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
This fix was tested with the Tianma NT36672A panel on the mt6768 platform.
---
 drivers/gpu/drm/mediatek/mtk_dsi.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_dsi.c b/drivers/gpu/drm/mediatek/mtk_dsi.c
index 7961139333ad..e5b433f353d5 100644
--- a/drivers/gpu/drm/mediatek/mtk_dsi.c
+++ b/drivers/gpu/drm/mediatek/mtk_dsi.c
@@ -794,6 +794,7 @@ static void mtk_output_dsi_enable(struct mtk_dsi *dsi)
 		return;
 
 	mtk_dsi_set_mode(dsi);
+	mtk_dsi_clk_hs_mode(dsi, 1);
 	mtk_dsi_start(dsi);
 
 	dsi->enabled = true;
@@ -858,7 +859,8 @@ static void mtk_dsi_bridge_atomic_pre_enable(struct drm_bridge *bridge,
 		drm_err(drm, "failed to power on dsi\n");
 
 	mtk_dsi_lane_ready(dsi);
-	mtk_dsi_clk_hs_mode(dsi, 1);
+	if (!(dsi->mode_flags & MIPI_DSI_MODE_LPM))
+		mtk_dsi_clk_hs_mode(dsi, 1);
 }
 
 static void mtk_dsi_bridge_atomic_post_disable(struct drm_bridge *bridge,

---
base-commit: c03c1a14507dfaf8b856c2608f9ac216021fc222
change-id: 20261019-6768-dsi-fix-9f0c2ca2ba9f

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

