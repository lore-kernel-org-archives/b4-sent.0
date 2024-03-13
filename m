From: Douglas Anderson <dianders@chromium.org>
Date: Wed, 13 Mar 2024 14:12:14 -0700
Subject: [PATCH] drm/panel: atna33xc20: Fix unbalanced regulator in the
 case HPD doesn't assert
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240313-homestarpanel-regulator-v1-1-b8e3a336da12@chromium.org>
X-B4-Tracking: v=1; b=H4sIAK0W8mUC/x2MywqAIBAAfyX2nKAl9PiV6GC12kJprBZB9O9Jp
 2EOMw9EZMIIffEA40WRgs+iygLm1XiHgpbsUMlKy1opsYYdYzJ8GI+bYHTnZlJgYfXUdtJmNDP
 k+mC0dP/nYXzfD1GOg+BpAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Douglas Anderson <dianders@chromium.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710364346; l=2015;
 i=dianders@chromium.org; s=20240311; h=from:subject:message-id;
 bh=/jgB/LgJDly6Altvbipo14aZmr/j8F+XuDmbB4fICv0=;
 b=ZSkyjZHVIxke1plTs0iVfALVXhp73xvZV1inGwLQ3nW5eOV+sfMENciF2dYF1l2+2oZFBEoiT
 vi6lBPds8GkA6mNzmas1XXWF4TafE7e2SSJw22U5dDDFyN3gdum072f
X-Developer-Key: i=dianders@chromium.org; a=ed25519;
 pk=3pyAfvsLkkkp4Xpq0XV7ZHOoA0WmPoJTE/BIAhunPKg=
X-Endpoint-Received: by B4 Relay for dianders@chromium.org/20240311 with auth_id=138
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the atna33xc20 driver was first written the resume code never
returned an error. If there was a problem waiting for HPD it just
printed a warning and moved on. This changed in response to review
feedback [1] on a future patch but I accidentally didn't account for
rolling back the regulator enable in the error cases. Do so now.

[1] https://lore.kernel.org/all/5f3cf3a6-1cc2-63e4-f76b-4ee686764705@linaro.org/

Fixes: 3b5765df375c ("drm/panel: atna33xc20: Take advantage of wait_hpd_asserted() in struct drm_dp_aux")
Signed-off-by: Douglas Anderson <dianders@chromium.org>
---
 drivers/gpu/drm/panel/panel-samsung-atna33xc20.c | 22 +++++++++++++---------
 1 file changed, 13 insertions(+), 9 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-atna33xc20.c b/drivers/gpu/drm/panel/panel-samsung-atna33xc20.c
index 76c2a8f6718c..9c336c71562b 100644
--- a/drivers/gpu/drm/panel/panel-samsung-atna33xc20.c
+++ b/drivers/gpu/drm/panel/panel-samsung-atna33xc20.c
@@ -109,19 +109,17 @@ static int atana33xc20_resume(struct device *dev)
 		if (hpd_asserted < 0)
 			ret = hpd_asserted;
 
-		if (ret)
+		if (ret) {
 			dev_warn(dev, "Error waiting for HPD GPIO: %d\n", ret);
-
-		return ret;
-	}
-
-	if (p->aux->wait_hpd_asserted) {
+			goto error;
+		}
+	} else if (p->aux->wait_hpd_asserted) {
 		ret = p->aux->wait_hpd_asserted(p->aux, HPD_MAX_US);
 
-		if (ret)
+		if (ret) {
 			dev_warn(dev, "Controller error waiting for HPD: %d\n", ret);
-
-		return ret;
+			goto error;
+		}
 	}
 
 	/*
@@ -133,6 +131,12 @@ static int atana33xc20_resume(struct device *dev)
 	 * right times.
 	 */
 	return 0;
+
+error:
+	drm_dp_dpcd_set_powered(p->aux, false);
+	regulator_disable(p->supply);
+
+	return ret;
 }
 
 static int atana33xc20_disable(struct drm_panel *panel)

---
base-commit: b33651a5c98dbd5a919219d8c129d0674ef74299
change-id: 20240311-homestarpanel-regulator-f4b890ff4b7c

Best regards,
-- 
Douglas Anderson <dianders@chromium.org>

