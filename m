From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Nov 2025 15:21:34 +0100
Subject: [PATCH v3 09/12] drm/panel: sofef00: Introduce compatible which
 includes the panel name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-sofef00-rebuild-v3-9-6cd55471e84e@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1754; i=david@ixit.cz;
 h=from:subject:message-id; bh=P0KIvmsjpu/GWMlI4xRr9BftnVEaKH9jmqWZeoZaE+o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHdJyDdkZ1dEYA7cSJjMj0hi5SZJtdieQo1zH8
 OUiuQgGWg6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaR3ScgAKCRBgAj/E00kg
 clXaEADNKwuBmStKGfsh+h+OK2PQP+yZXa0WJEoWH6Qg5AwLC9bwI4Mr7iO3wYgwWEASDGL9p+A
 vm691Nzgl8UpQCIgIJbCNZkeQB3RmL9Bt0NjP6t3OtiBrKTE5wjb9BwOlIcXpGwAA1KVW+rgCvL
 qS422FqiRWXjnJ2U+TxU5h85AGIAYHtFA0JIS5ULcpNHkSyE18O70XWNN2GjgMedH5wZm2BpADy
 mGgTjVt5w7PqMue0iSNBGnsNP/36kKWyqDHOjfhO9+6p37yWx0LKPTnHsFGCpuL+cSH3R8+uaSL
 4RKaHMA+rMZA8jE7YczNs7GB7MkRd4fUI+QREwkcd0IHda/Uh5jlMVR0kQVUrLJb6HtQgZoi1cx
 05CjK7wjOasbwZK6V0buaDxyUneAuLuATF/kbPRdJzxn+jgziTFOtodZpT7jtQFXkwjD0RVu6Dt
 5Cdhpv0/8e52O1mIzqdNqisDq68WimwLFnKbaDC9/Z7njqnhKRMaqss11a0E5uV82axkdwBlvGO
 lGzpWh1+ZruDm/I7weozNtttI6XLBtcEBJYPqVjpvnk7DpY4yOWmOsaaKRF4wFXki5sutCztU/H
 PqIozS8EfHqneoZFH6OBG6dFtPTSs9oICmY+2JG/zBl7Cspheu+LfItnelfEGxTGDxU7dPmcfiD
 Hzx9olMhPW40gAA==
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
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index d1e5340d7e337..c2cb85997e4f3 100644
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
 
@@ -274,7 +274,8 @@ static void sofef00_panel_remove(struct mipi_dsi_device *dsi)
 }
 
 static const struct of_device_id sofef00_panel_of_match[] = {
-	{ .compatible = "samsung,sofef00" },
+	{ .compatible = "samsung,sofef00" }, /* legacy */
+	{ .compatible = "samsung,sofef00-ams628nw01" },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, sofef00_panel_of_match);

-- 
2.51.0

