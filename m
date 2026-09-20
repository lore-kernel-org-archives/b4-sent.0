From: David Heidelberg <david@ixit.cz>
Date: Sun, 20 Sep 2026 13:05:50 +0200
Subject: [PATCH 07/11] drm/panel: s6e3ha8: Assert reset GPIO in unprepare
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-crosshatch-panel-v1-7-de6e9512da96@ixit.cz>
References: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
In-Reply-To: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1090; i=david@ixit.cz;
 h=from:subject:message-id; bh=20U0ozvap504c/y7dNH03jLGzPdtj7FO3ci7Ov7l9BM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqr74JI29ZlFwOBeivI0xUK4KNDr/fR/lUt5sf2
 hCXgwI+aeqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaq++CQAKCRBgAj/E00kg
 cgMTEACRs0Ec5QPTNCucUsDUMH1a7vXMyWNR1q0yN2AJ8JYiGI7kOInveX4aUpekPi4Y8fgGaRe
 7zMV2r9Hmnt/dZb01vKzEuy0iOiho28I0qeAbu6moijMbG3zNn6zgeP1ygAfUbKtzpdOoS+kZRf
 isTe/tSQpKqmAkxi6DPrPpZRzOl7eb4aKXJ9/E/NyTUJH8/KYe5pTCjxuc3s28tyYnbFx+E0zH/
 oB9eCLwYVrMYMbM3yHcjLQnavaD/X26gUmsw7yBpzSLX59pGrM8dx6+tMD3ALQIWhaCSBFse1uu
 1TL4xCnRaOphcsDC1QR0waG1iqp2i8mw4DD7KJIIx54eFv3k+8vFiZFo4CqJG4skI+KSLSs9Zu0
 aSBfvZXEUCFJya1ep499H3HopH4FgxGqq8tjeNYIR7dRrb9hFq1e5TbQNSuWYsugbaAy6uttxdE
 62uZa5QU8wmJSB4CamU8BiwPR52NV75vZ/O/mY9s2dRN0ApJsPWnhmo1pD50pmLuII4ByBimWWw
 MdnrlnTY4tNcfaHN171klb7yTJF2kiHu0hWEaPhEkXXgPB44CO3WcaK9nP6aN2H19rcppaGjxLP
 igf3oXxaie0G1r9LwYFd7on0npkjUfM/HBx090E+QjsUVeuG3kXPcUOuML7osXYMbrXT7FA7n08
 d+KAl0IMaUBl6mA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For correct shutdown, the reset should be asserted.

Assisted-by: LLM
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

