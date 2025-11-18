From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 12:30:40 +0100
Subject: [PATCH v3 5/8] drm/panel: sw43408: Remove manual invocation of
 unprepare at remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-pixel-3-v3-5-317a2b400d8a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=904; i=david@ixit.cz;
 h=from:subject:message-id; bh=InL4IEJK9SCfpvLnrH751SzB3QvgsZ1MDVnoJ5xWIq0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHFjgYbn0WPWPCSGgCqAi80SoSxWT3vZwegAVa
 OXROI5fxDiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRxY4AAKCRBgAj/E00kg
 cs05D/4oJJX22556aW4MvjAKcBubbkD6X06QIGWjSeo5Nr9LdeIfakO56jEXd918axdJD/qg5kx
 cJKmfnmeQdFSSilK51YTcviXAjTmXHmYqn94jU42AuYGfhcPjA0PpND+n8dFa95n/++GUL4ufRD
 4I/odGbC+cRw1p1YeIf7xCh0rS0O3ma8UdMWhqPX1Hd8BtEyN7ZzA/rE2GSgO+qD/30SNNOI/4p
 9K9jerDo83mdhc9g+CzXqFgU5pTgY8Fe5afYbTB9pg3nCPwOetcytpHM7hX0bRJXQZctoj9oQ7z
 ZHAhEgrVVfIWn7Lj/Oexdb8sEN2unpSLrItDNFKvZzOd3T08F5AYRbNpfKeOY/k0I6XZz9O3KYh
 t0A1NBGFgn/Lfd1BCPqg908Z65RlqxhMYWV4HNgRRUtVhBtSqlOxu4RY2mVKGmjGA2evxdeEPxn
 fXCmIUxuHbux6TocNwEbJRMfnp64dNNgyyO2dr6ooIgsQRho3VvLS3ijKHeNrZJIv3gZV2KboV+
 T1vj7y6oKDRvob8GqRX2/sOiw+tkR2s0nU4jDx+VICk4Jd5zN4tixNBi7vXj7yu5eXJQ7wmSWx9
 uZBdeq5gNHOdW7bLFLAfyvEnIc2iPQusJ2e0NGfKyXySQ1dxj6oWeBiyWig3G1xwRaBW7LbD+Uc
 Hbj4I8BllB3gA6A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The drm_panel_remove should take care of disable/unprepare. Remove the
manual call from the sw43408_remove function.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index e5a8a9bb8d15c..d8481bdafd6dd 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -319,10 +319,6 @@ static void sw43408_remove(struct mipi_dsi_device *dsi)
 	struct sw43408_panel *ctx = mipi_dsi_get_drvdata(dsi);
 	int ret;
 
-	ret = sw43408_unprepare(&ctx->base);
-	if (ret < 0)
-		dev_err(&dsi->dev, "failed to unprepare panel: %d\n", ret);
-
 	ret = mipi_dsi_detach(dsi);
 	if (ret < 0)
 		dev_err(&dsi->dev, "failed to detach from DSI host: %d\n", ret);

-- 
2.51.0

