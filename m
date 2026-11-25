From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 19:12:50 +0100
Subject: [PATCH v4 6/9] drm/panel: s6e3ha8: Assert reset GPIO in unprepare
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-crosshatch-panel-v4-6-120adc58e737@ixit.cz>
References: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
In-Reply-To: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1129; i=david@ixit.cz;
 h=from:subject:message-id; bh=YoR8O/9CziH74UhYPjrFBAlu0YEV4HfID7khfmE7WHM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrByUeXjhNqg1Il1wuxj2H7RwoaQiUOVFCvR4aA
 DkR/LV7ZbuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawclHgAKCRBgAj/E00kg
 cgItD/9zboRb9u6jw6iHWKJzQFwFH0Z6HMNJekQQ154IEmmmvysEAfE7wlnLWnJNj4joZ4OsHS3
 tJKtYm9oa3emHik9vUnnrc/kb9VxTi4kKn8HxMy1EkF0PwDxv0f7eudwzZo0qsgMhjIBUuxMhed
 epTaW9tCKcT5n1Lw0hnZ4DAGpbDBCl/wvRe+36i7TcQBLCZX4P02aKvwLd/mzX5aODwAiwP3RL0
 gviH3Qn0DFUowCB/pYJYPdtNctLW0jie1X46A/QkYKfYd91Ps1Kgnq0QzIhMSlwT965MADf9X7S
 d4Ny5kJMbHqmKQlR8qrnMkgY7d3KgQoqf4/e8RabRmRJyRkGi2+1pTkFsDqKNuuI1+Pe3mzWa0Y
 6TOBAyYFrDsyUA2d4CdRZqxMzwxjL8sEhFSAL//oOQ4HRkX5t9khGc3Kjwl+CfmyI5LhNSg2Y4a
 n8NP5ih5Hrr5fp88jUCVEEXDHzUjtpMD/90PQiTx0zAlra5fv92nfAq+6V+djMix2SV6iaFZSoC
 I3OB7FijYrjCAwWSPHGkbacT7edL0V+pok/AkFj+rkZdVP0DwLcoMeDSHqPEAiaC/RUkpcp5lQH
 uEV1uRGgpxvu/DnvkNQ9WZGc56zFZoiPd9qgWrdC2wfUxqrh2zEMQuSfdCc2c1VcB0f/X9oLtSs
 dsypsNwch5PeMLw==
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

