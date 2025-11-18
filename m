From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 12:30:38 +0100
Subject: [PATCH v3 3/8] drm/panel: sw43408: Introduce LH546WF1-ED01 panel
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-pixel-3-v3-3-317a2b400d8a@ixit.cz>
References: <20251118-pixel-3-v3-0-317a2b400d8a@ixit.cz>
In-Reply-To: <20251118-pixel-3-v3-0-317a2b400d8a@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: phodina@protonmail.com, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1646; i=david@ixit.cz;
 h=from:subject:message-id; bh=zdnKJDIMeMRyO+SWDYgfxVtOGiWokm8aDgNXOD3aXMY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHFjgWqFBlPThDTkfgTV3N4jMym0YwB4V2B+dW
 6PDa8UbHRCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRxY4AAKCRBgAj/E00kg
 cqXbD/0RNQIrlcYy/v35U2jD3fu+nnPV67tqnJajTOoTXZLZ/mcaqg/MnDG95MkVC29lhXajD5D
 6E+a28DGo0YtIlZpYxLq2AcrkcVO3zfbN4WLu2eRjjZ42sgE+kQtHOnL+kWX0FnNbf0ZVoiTMnY
 E6Mmn+A/2nBM4BL71ZzqWQZHmD2kt1DYLle17JQAcY3EQWN8Su2sNW6ctvuB5o0yOSnJmRY5uLl
 3O5NIcdDlzk9N+h8ViMTlPLLv5zzcP8t+1ozTyocz/FiY9NjxG9PBTsuoiKUCd3hW+OKVaggGFW
 5307ZvWd3yI+aQD5UY05hNgif72k38Vl8Sk/CfAQIPe0lXpTzWCJ6EC9frJxyeEhnuPefGFhX+9
 d/SyJE0RWM6j+klvEnZvytF44qhCXufuuaXrVReAEu6ylOC3eoyeYI20fAyBoRJPLKXnOeGxrhU
 OPhkXgHmVzcW4PTmaW8p8f3EKF2jhtn6RCkJ4cMQ+R8f5T7NP3wr/dI3D01Fn2A+m3r39CexR0r
 Gj60/U3YiSsbQMKXdc0RSZZ3OYKqiRSe81BYwNX/0rIjrZqtXvAfYPVvppybagDEmeSXUP6Do9z
 JlXL7jks19LwWxzmmgWsLPshA3Bl7osN5AhEYCPnuGBYQI3fzVsRqWpYd8joqBj9uKeGAL5F4zS
 AC8geMn3XdtDJfg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The supported panel is LH546WF1-ED01, add compatible and adjust the
struct name to reflect that.

The standalone compatible lg,sw43408 will continue to work, even thou
there are no users yet.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index 46a56ea92ad9f..bd55f6d8f2771 100644
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
@@ -214,7 +214,9 @@ static const struct drm_panel_funcs sw43408_funcs = {
 };
 
 static const struct of_device_id sw43408_of_match[] = {
+	/* legacy */
 	{ .compatible = "lg,sw43408", },
+	{ .compatible = "lg,sw43408-lh546wf1-ed01", },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, sw43408_of_match);

-- 
2.51.0

