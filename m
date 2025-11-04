From: David Heidelberg <david@ixit.cz>
Date: Tue, 04 Nov 2025 23:16:19 +0100
Subject: [PATCH 11/12] drm/panel: sofef00: Mark the LPM mode always-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251104-sofef00-rebuild-v1-11-dfcfa17eb176@ixit.cz>
References: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
In-Reply-To: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1446; i=david@ixit.cz;
 h=from:subject:message-id; bh=dv4mgLKU6V9KA5Q8a78znnVTuWL2bX0IVKAwUPXHk8E=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCnss5hUpSPsdjW0ukYNFOlQ+Ocni+pVvHaxBz
 bFmfbI4Y1aJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQp7LAAKCRBgAj/E00kg
 ckWtD/4ygHvR0CvpB1cA8D2r355X7hHWLtpzCaCEo2h29/XoojxCI/rXsvGT8mZPfFIiaI8on1O
 OFVxVBeO3obIlKmJBZT50fPKsWH1HGIyt4R2ruN/nzuzjMu9NZmIXJJfJVd2tPDxq9kvZIxt9+M
 ZIH5vfyjU1v0qbEZjHPNj5/8kQg7P/ShsF+XOULB0sGfvLbwLxyIpyRthhqfAR5PTjoPtD26mon
 5Pilf4fDZzzXy03+KxbxzdZEzIZgk3RgPGx2slG8ZOY9beymJlZggMysUjrXNpwluTIzUBlpZZu
 pW5KrK1M0iv3XqjCqFRriNP5D6czdOK4jehb0ZPZPESHDdnKMXyMLzfIgSuzl+dlgXH8fUXeUld
 wVlKofGQV4ef8mrBD4aIiIN9HrWyR5UpwLGYC7t8oJIVmnXi8yG58pT63Oc8V/mrOXJ6jPeshb/
 hPxU2qpUHSnL5fq/ac8YPX8kam79jJrq2swoPdrhVwKZppvq6lAA0Po/FKc3luaOeicGJkWBN13
 I3ANyxg3/1aORK0tgRyfEGvz5pi2wRCMstU0+kbMD4QL6pEGW7uAjmGzk605NGB1UW+sHeW2oNC
 i1g799xbgN3F3+CySS2WwQ+bT7bDzXB01LWu3bzG3TZOaOztYELiQWvNFqMaEsMxMaq5qvQdABF
 Pz2qlswvD7yvEEQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The panel operated in low-power mode, with exception of changing the
brightness levels.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index e69a28628b656..8286cad385738 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -92,8 +92,6 @@ static int sofef00_panel_off(struct sofef00_panel *ctx)
 	struct mipi_dsi_device *dsi = ctx->dsi;
 	struct mipi_dsi_multi_context dsi_ctx = { .dsi = dsi };
 
-	dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
-
 	mipi_dsi_dcs_set_display_off_multi(&dsi_ctx);
 	mipi_dsi_msleep(&dsi_ctx, 40);
 
@@ -180,10 +178,14 @@ static int sofef00_panel_bl_update_status(struct backlight_device *bl)
 	int err;
 	u16 brightness = (u16)backlight_get_brightness(bl);
 
+	dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
+
 	err = mipi_dsi_dcs_set_display_brightness_large(dsi, brightness);
 	if (err < 0)
 		return err;
 
+	dsi->mode_flags |= MIPI_DSI_MODE_LPM;
+
 	return 0;
 }
 
@@ -234,6 +236,7 @@ static int sofef00_panel_probe(struct mipi_dsi_device *dsi)
 
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
+	dsi->mode_flags = MIPI_DSI_MODE_LPM;
 
 	ctx->panel.prepare_prev_first = true;
 

-- 
2.51.0

