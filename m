From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 18:57:43 +0100
Subject: [PATCH v2 09/12] drm/panel: sofef00: Introduce compatible which
 includes the panel name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sofef00-rebuild-v2-9-e175053061ec@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1727; i=david@ixit.cz;
 h=from:subject:message-id; bh=M9STxFOLgg4Zium2zG4uC3SLMrSpuJlpn7X6CzXpmTc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwVQ/8nXWi6K7GnvwZyzFNJteNMpJQtpCVU2
 4O8dGk/9yKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFQAKCRBgAj/E00kg
 ctibEACJRajzKlRPa0TDMeJPxo3qOg7JXlDXrnKIE6HPhSkTpARjokYkkgkM1X45ZNx1LCgWsoy
 fecDxr73NUD3BhRQfQ24aWmDO+F97mBgoMAARIDHHzGDezmX8eBnlZNPs7Rwbrxzv2m+AFnoOSp
 X9qgXLk14Prvw96FBvUQoJC0D/YnjSR2eRzarCqP5cgKrBDmw30hC1yKSiDRf1LfEEAZsxq3/X2
 WgZaNBIyk3FyYtlb0f+Q8CUGd68sTYlOmfsBf0wKyCBcM836A2tRLizvZhLZECqEDCKCatdCc44
 I3EOGHWgG8k8lE58nWgXUTKqJntwaLMWesx7S/8eEBlLT9F0J3tOsZFnxFgwK2xLk0u0s6e9E/H
 8kmiJU9t8orrRE6u9zFp/jp2OJ/H5TilbssmBF68csa2wRgjzmcB3PFxZWGCgrbNT6JxAUk+/TQ
 AfMUewJFrhCvpAq+jgKifyt8MiJBdn9nUDRFYfwmV666qxhrvk16Cgeo/+Fd4J4xpRYz683sigj
 p0JbKRqYucomwDnMyeyRiYeGQnZQI5D8aaWU6aKvM2EB6H8CUCR38DUDWFSIRU6ZlIZnCL0M/uK
 SpfMYdG9Qut4jHSF5Rcqz21Ycfdq8DhLWBvErInYSztWel3YfocCZmxPrXvbLU72Syes3+J8UeA
 62fXbBeOFYubHdw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Compatible should correspond to the panel used and the driver currently
supports only AMS628NW01 panel. Adapt the internal driver structures to
reflect the name.
Original, not very descriptive, compatible is kept to ensure compatibility
with older device-trees.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index d1e5340d7e337..7947adf908772 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -141,7 +141,7 @@ static int sofef00_panel_unprepare(struct drm_panel *panel)
 	return 0;
 }
 
-static const struct drm_display_mode enchilada_panel_mode = {
+static const struct drm_display_mode ams628nw01_panel_mode = {
 	.clock = (1080 + 112 + 16 + 36) * (2280 + 36 + 8 + 12) * 60 / 1000,
 	.hdisplay = 1080,
 	.hsync_start = 1080 + 112,
@@ -159,7 +159,7 @@ static int sofef00_panel_get_modes(struct drm_panel *panel, struct drm_connector
 {
 	struct drm_display_mode *mode;
 
-	mode = drm_mode_duplicate(connector->dev, &enchilada_panel_mode);
+	mode = drm_mode_duplicate(connector->dev, &ams628nw01_panel_mode);
 	if (!mode)
 		return -ENOMEM;
 
@@ -274,7 +274,9 @@ static void sofef00_panel_remove(struct mipi_dsi_device *dsi)
 }
 
 static const struct of_device_id sofef00_panel_of_match[] = {
+	/* legacy compatible */
 	{ .compatible = "samsung,sofef00" },
+	{ .compatible = "samsung,sofef00-ams628nw01" },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, sofef00_panel_of_match);

-- 
2.51.0

