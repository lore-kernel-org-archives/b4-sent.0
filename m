From: David Heidelberg <david@ixit.cz>
Date: Tue, 25 Nov 2025 21:29:38 +0100
Subject: [PATCH v4 3/8] drm/panel: sw43408: Introduce LH546WF1-ED01 panel
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251125-pixel-3-v4-3-3b706f8dcc96@ixit.cz>
References: <20251125-pixel-3-v4-0-3b706f8dcc96@ixit.cz>
In-Reply-To: <20251125-pixel-3-v4-0-3b706f8dcc96@ixit.cz>
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
 Dmitry Baryshkov <lumag@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: phodina@protonmail.com, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1680; i=david@ixit.cz;
 h=from:subject:message-id; bh=9TAk0DAPWxZVYTBz3bFgNgm0xGew8ziZCJQS5XGU65g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJhGxRm6sRwZPo41Mwxyodut3ZK3FkRghiKnCj
 Bz8/Dg7lIqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSYRsQAKCRBgAj/E00kg
 ckEKEACl9YEzwbH/NPMBTBmhqqST4/0mcBKw0oU2FxWl5UP35HBdt/cuj99YzuZv5UOaqwrQcaQ
 F2G60gHfObfkf7VTJKnKnl9iEEGbEEtslgkCCKiFnoCNP3Rrq6YSRC8cZy/RP6t2ee3f9SE7xsa
 Bu+/4njAMjkJgdn4RC52J7/GTamfr5obbRQlCVn7lEDmkwPKcTeybpyyBhl3l1MYyefuzvYRXNs
 HM64dP3YFCOVkrMSOKsG3HegrzySIhE+0Ufcb7JoPAibjMOGucNNV5PJBY0lHx3ow4K0Jw4pZZP
 J9P8j1ZqggAJsw8/32SfZ+PXPs0uZwocVX4opQBNKDBKLdG2MRT2BOsGVnppGxjcDLGdut5BIKH
 3OUML8BViKjwH5fqbdc4YvlmBe4ZrTLUJej6VZIrHTSVcvplVCkWht3dNzHUO8YrvpLu5o5pSF6
 YxNTnZ0tlCW1nPcON5j0e4vjmQpCKa3UAMx7edxy16DOAnwjqYWlP0EDbbhxMKPEf7ta//7gM6t
 qnuwCJ7B2BhHNLumKm/zPCVN5CJ1MzCUyqwLpnFkWX5pEW2h0GqkUfF/xjuTgXffvbnvyIstP0U
 mRXrIEXmjbX4TZlVhD1J/Xi4tC49q4yQkfF1rToVtUBdjBHiMi+6lxPHSj1NBBsMPE39sA0+7/j
 rSjpl6WXO5wWNng==
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

