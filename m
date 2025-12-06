From: David Heidelberg <david@ixit.cz>
Date: Sat, 06 Dec 2025 14:34:20 +0100
Subject: [PATCH v5 3/8] drm/panel: sw43408: Introduce LH546WF1-ED01 panel
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251206-pixel-3-v5-3-dc99732e7d35@ixit.cz>
References: <20251206-pixel-3-v5-0-dc99732e7d35@ixit.cz>
In-Reply-To: <20251206-pixel-3-v5-0-dc99732e7d35@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Petr Hodina <phodina@protonmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1747; i=david@ixit.cz;
 h=from:subject:message-id; bh=K5KrfoqgLLk98vvZLiz1OAUosAiZymNlygbzh53UxIQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNDDw0iRqtud2wJK5tlpQJSM3IKgtgqcfBohqK
 sddE6k+kJiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTQw8AAKCRBgAj/E00kg
 crtAD/9Y2PURNGt6jhl8+861Qln6l4gWac48D5IsT5LGy9ZGrbNVcSAgNHHEw1FxJ/gDVT+Fmjx
 jbNq8ERVvdeegB93LYpcdLt3moc9pRnORIEipdEv0MLzjqN6NwOzgNQ9+/d21FZv4lIpSCdMjNs
 rUHGQ7jPWsc1rw+n08dbEO5nH1w17s/nY6pIP7QMSiEepSyAZ9Xz+j2qx0WDtqOm+lTPtACdUkM
 +2SC8jVsWQVzpFNg3j47sdpTmW2aFWWL1PfkTCIHMqyyLsFRQw5Kl+NARX7L8qV+cDNjg8yLw/W
 IhRfLFVT65+Z2dIgNxVO+OLwm1IZzl1Fg5P3vPtCPUb6PP08YwJxIRklW0o2uwTERYuWdCuqTo2
 8o7S+KBqB9QssgxV66Th9z/dKnB2kPyzWaFXmIDnrtDTw2IyJgwQhoAqn/z7s4w8d2TE/p8aOr5
 PZcL6Yv4fhVx411BYrPjISyMwAbnpHxtJhXrM4z0GEgLC0sTD72cFEmzyYcVLM0cd1uPuDvn436
 3he85OmFwSXW8ZMI78M5ie/1yjIlD/ctn+MsDe3UnsZSvsfp3EntZ5XCpnKqze6INoc1KxOrY9m
 a1iyMqfN8m+SSTLIRK/aakgREU+1xIn6eK4rv0GnVDKS/rUsC8Wwu1vqjLyy7uDs5YuDm5A/sEc
 sSLk1ddUOQpAC3Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The supported panel is LH546WF1-ED01, add compatible and adjust the
struct name to reflect that.

The standalone compatible lg,sw43408 will continue to work, even thou
there are no users yet.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index 46a56ea92ad9f..dcca7873acf8e 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -149,7 +149,7 @@ static int sw43408_prepare(struct drm_panel *panel)
 	return ret;
 }
 
-static const struct drm_display_mode sw43408_mode = {
+static const struct drm_display_mode lh546wf1_ed01_mode = {
 	.clock = (1080 + 20 + 32 + 20) * (2160 + 20 + 4 + 20) * 60 / 1000,
 
 	.hdisplay = 1080,
@@ -171,7 +171,7 @@ static const struct drm_display_mode sw43408_mode = {
 static int sw43408_get_modes(struct drm_panel *panel,
 			     struct drm_connector *connector)
 {
-	return drm_connector_helper_get_modes_fixed(connector, &sw43408_mode);
+	return drm_connector_helper_get_modes_fixed(connector, &lh546wf1_ed01_mode);
 }
 
 static int sw43408_backlight_update_status(struct backlight_device *bl)
@@ -214,7 +214,8 @@ static const struct drm_panel_funcs sw43408_funcs = {
 };
 
 static const struct of_device_id sw43408_of_match[] = {
-	{ .compatible = "lg,sw43408", },
+	{ .compatible = "lg,sw43408", }, /* legacy */
+	{ .compatible = "lg,sw43408-lh546wf1-ed01", },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, sw43408_of_match);

-- 
2.51.0

