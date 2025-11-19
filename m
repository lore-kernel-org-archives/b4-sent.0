From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Nov 2025 15:21:32 +0100
Subject: [PATCH v3 07/12] drm/panel: sofef00: Add prepare_prev_first flag
 to drm_panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-sofef00-rebuild-v3-7-6cd55471e84e@ixit.cz>
References: <20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz>
In-Reply-To: <20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz>
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
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=918; i=david@ixit.cz;
 h=from:subject:message-id; bh=4SM9hcft9HxR/OcdKpSF5Ee1W0Jyu8dLyBp//WZCcbk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHdJyMun4lNvyG7GRsKltaopxelO91qC/BKWF7
 XZjYMU/nECJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaR3ScgAKCRBgAj/E00kg
 cnlrD/9gFTsd14LOIw9T+8inMsalraoeodlg5dehVIpOfJa1FxQQ8jTMjIMBV2ilXPwbW3giTFz
 +kZ9i3Qf9RcI38mjiG5K1pzKVSZG1bNrP6CLkN6zvFpsky/XYzMByjvKAYF+W0ermUwW+nxB5NE
 9rT5oLfHlBw2HLNsR4ki26mMAMHnvrh4gmJM1hLO5FUcgMP6AK/zUEN2zj4Q1WjwDpxvdOE6M1V
 lj54oU+FALXbSBCs24ehZqIEz9YtJP0Zxp7r/bRuq7dBVtBrUS8H/IB1t6NpR99dtD925WTmtJ+
 4IAt5DC3VPIcrVsdu2eZxWLKBhGQbQRPBKb/NICmYdc+NCUwONZj6vNVh2JmJzgBYLfgbTyJV9P
 v17W51KnfF/TXG13P6ZF3e+xaABqCJfe1O5FIw53B/VxvwvTk715YPlhV2vaNwBI+xV6BeUSfYu
 PiFcmGFm4iVSQTGO1eCwPPUEyu3d5A/36jk3mGo0yekd5rgSDC01y44kjdE7mQ/+RnWuGDuDEMC
 RUn9H2+yS1TlSbKGiYpYXIGyjAXGffYjiY1DrNtp84Szh0YzzW2MYekwsvby+ch9Boc1tET83x1
 gW/H626SKJhnK0OGApSyu6f9yPLs1P9lvt1A4Gq6L/aVX+AqAnMN18uZgevj6dPVf1LUEohDDEr
 pFMWAlgPT69xTjQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

This corrects the host initialisation sequence so that we can send
DSI/DCS commands in prepare().

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index 97122ec8872a1..0d3ae0689a19b 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -242,6 +242,8 @@ static int sofef00_panel_probe(struct mipi_dsi_device *dsi)
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
 
+	ctx->panel.prepare_prev_first = true;
+
 	ctx->panel.backlight = sofef00_create_backlight(dsi);
 	if (IS_ERR(ctx->panel.backlight))
 		return dev_err_probe(dev, PTR_ERR(ctx->panel.backlight),

-- 
2.51.0

