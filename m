From: David Heidelberg <david@ixit.cz>
Date: Tue, 04 Nov 2025 23:16:17 +0100
Subject: [PATCH 09/12] drm/panel: sofef00: Name of compatible should
 correspond to the panel used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251104-sofef00-rebuild-v1-9-dfcfa17eb176@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1576; i=david@ixit.cz;
 h=from:subject:message-id; bh=Q1+rieBGQ6VeDwGqVLQ0Szo7yx1/bCpLNjnwi01dWXI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCnssjt1R0WlC9R9CBT7rMfF1j9rawbA1vgPw5
 uF09VOMmhWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQp7LAAKCRBgAj/E00kg
 ciIjEACdLKpaSOqpuNGJ6mcYFlJ/2DUTm7OCUG17xINWOVjF0L1sPhuNVtoA0DHr4P+0yAp56is
 kHxWCa6Mq3ggsm37Oz0NSg5U4M+7+PpUycKv4EMIBuThrGtKeTR+Pnq1UbcjPfQKuYFCQduC7Jq
 d8XeGsC+rb2FDqmhbF5CRzUZWbhs0XoAFh1wJb4TUNAzJ1pI1WAcbDyQnVUA0ISyV69ceVq6Yqd
 tqGRCj5UKf5RRUQh2HwIHDclrvH52UiWXYuRcSAEyPAGKpK+94wrWDDVX4WA7yTHWyGUBjveY+i
 Toy/fRW5vXowSJSYPE2gxDCWL3cLw4vIWorLpRqboJ6PIUHR7RRyRTUajRaETtJ8r6AyjIjxA55
 CPXvbsPFbeWqiuam7PZTTPomDAw7e+xHSES4rkPOGE7oq/f7X3ot/gSKgvHCsDEfMUnK9dIzAqb
 dlupjSQ19/upqeygiGnbZ00TvaW4oiTF+NY51R5UPOuqxg7oYAWuWd3D1TngiGfKZQ2ogbubbOg
 xHVowEPtSQXM/JpBA5tEKDa32c9dA7fA7s9xet1eKixQLMxssoT1ukkh6zbXD1knL340Yw0DsQv
 rHEj7kkL+tiTVWEvzPZdtsQ3sESa3lZrZoWDQp51pWpYcD9OdfUbyFeVZ09YO3fwg9twNYrO8Rn
 cdiSK2g2Wcwn94g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

At this moment we support only AMS628NW01 panel.

Adapt also the internal driver structures to reflect the name.

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

