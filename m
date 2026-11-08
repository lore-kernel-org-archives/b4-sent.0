From: David Heidelberg <david@ixit.cz>
Date: Sun, 08 Nov 2026 12:32:27 +0000
Subject: [PATCH v3 06/10] drm/panel: s6e3ha8: Assert reset GPIO in
 unprepare
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-crosshatch-panel-v3-6-87dd4ec4f7cc@ixit.cz>
References: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
In-Reply-To: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1129; i=david@ixit.cz;
 h=from:subject:message-id; bh=YoR8O/9CziH74UhYPjrFBAlu0YEV4HfID7khfmE7WHM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GvfEC5NRlkhJL4+HcK7VBEhx7z6sDuyw0I76
 DppDT7mhqGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBr3wAKCRBgAj/E00kg
 cjoDD/9J5mFkylqCbm65T/GFGtuzKg7d4xB5v+2mc+08FOvjJu5iwKFz9xcbIE+z/lOPY9UVXr+
 3fQPgIQsbNRr2AlfAKzdurdzikQrqYMWNKFD0nwYr5mfUPTcxH+6wwNP+2OHNgT66Gv0+yn9IVv
 uZVxm1wU8/1Nnuj+apUbt+1ujM1d01by8IQ0Ml7Gui4W1+x6FESeKMEFwVZE7z8nrVV/Df7UTin
 sX6khTTWJyAUEi0zf+aT9cgGt/Meqg+hPBoCqFdtkU4RQaWxKlj/usrTQKgKHlq8EATeKvL2z+1
 J2UpRG59L5KOq+9RmTiZLoxvPYgVbGMcUkjrPOClhX47Lsms+tBhCuagu2I8sF0RVqXfqHnt8Z3
 a+duinbh++ZG43mJVKK/TfJx3I4xKJ/Wc9a0ZzR0nlG4GL+GSpnCI3aCmXN+fQg1diqhmewf0E1
 pTi4JPpZvkg4W/OI0CjHrXzvKYbtYih0CyPm59bx5rdMls6ulJUl7Mud04s4cKRgvYsSeLgWjgf
 sWXZMl5N5aI90hQngHzFPYwBKewB+1xC8bahBrxYC7Q8G+UhvjBx3KmsatsIvR6AfVuc5FxmyPo
 zg5/4s3M/k2+7SwPDJVQcqeNOBm7EKpjpKS8G75mGkNFWg4SBWuQGkbCq8zly5UxOehgE6FW/Nx
 N5U5J0n8iTfGRdw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For correct shutdown, the reset should be asserted.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
index 99290913de69a..2591b8c1a7753 100644
--- a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
+++ b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
@@ -58,16 +58,17 @@ static int s6e3ha8_get_modes(struct drm_panel *panel,
 
 	return drm_connector_helper_get_modes_fixed(connector, priv->desc->mode);
 }
 
 static int s6e3ha8_unprepare(struct drm_panel *panel)
 {
 	struct s6e3ha8 *priv = to_s6e3ha8(panel);
 
+	gpiod_set_value_cansleep(priv->reset_gpio, 1);
 	return regulator_bulk_disable(priv->desc->num_supplies, priv->supplies);
 }
 
 static void s6e3ha8_amb577px01_wqhd_reset(struct s6e3ha8 *priv)
 {
 	gpiod_set_value_cansleep(priv->reset_gpio, 0);
 	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(priv->reset_gpio, 1);

-- 
2.55.0

