From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 18:57:45 +0100
Subject: [PATCH v2 11/12] drm/panel: sofef00: Mark the LPM mode always-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sofef00-rebuild-v2-11-e175053061ec@ixit.cz>
References: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
In-Reply-To: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwVWR0DhH3x/QekF3rJ8kiBp445Bbqdsqmu0
 DdyTzmWe7yJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFQAKCRBgAj/E00kg
 cpEdD/9kDTBHwwsLMzCluvZCQG+MVWx7VHsDr/2TaORCXi68pKGY8svhOAB48NGv5nUCWkQbEHc
 Kep8Qx+rf3Ht1JHdpUoDJ5FwNbeYlPaXJhsQv967lwvTt5sAloZk8j4FYxxCP+HqbZ0oXVDmqNp
 ErPs5Y8tbiFkgUVjFiQ41LrPc8Shl7R9aIw0DKrmTQFSkfpRurb36KC4I8cE3bVD38+k/cEhuy7
 JHq0mH/1PKntoxIm+T7XPQ1tQSwlRCSuXlrnIRcwjvs3/T052qaJXNC1RkM8a51WIGLiHZR7cvK
 de0wjvU35VOGe97oA0JoqYgpQhLRkDjvbO5Wgah2pijoPq1l5pWezoxDTOU91TpC6bdQFRyCLtP
 rLISelPF7lCoUmiJeImxd5y9eEXMDMYLQcJ4Uz1aBuJbha+ki4bW0hR2jwcEdJ8BPTCobiHt24I
 PYR3XAF+4oKRyNz5ciwXz1RVH5drEQpzwOqFuFOENyc9HQ/9GtYriexYuNhrNfnhbxwCyigaIfs
 d+gbrJslaKwhbOEEp6dFOuN1oEkM1FJGBygGVTdI1GBUH+5UFae1d1Tk5R3g2HwWvJ3XIZnQO1P
 /IqDJz9Hq5/fYK5kqOz33UkK9zUidF1ewOpnoJTRfiKcAinFz3bN21ZbcqYmaN72MDgPHZMsJ9M
 /BTsijqnJE+U7QA==
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

