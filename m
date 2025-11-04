From: David Heidelberg <david@ixit.cz>
Date: Tue, 04 Nov 2025 23:16:15 +0100
Subject: [PATCH 07/12] drm/panel: sofef00: Add prepare_prev_first flag to
 drm_panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251104-sofef00-rebuild-v1-7-dfcfa17eb176@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=918; i=david@ixit.cz;
 h=from:subject:message-id; bh=4SM9hcft9HxR/OcdKpSF5Ee1W0Jyu8dLyBp//WZCcbk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCnss+C9hk8uD4rNM/1XSy6pPmwJAizKBdA2Tk
 +J08t4NnMOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQp7LAAKCRBgAj/E00kg
 ckpzD/sGiOdjJOm67e/IWCJRiB70hkmMzwyd7d2X1z27QAASZbQDVydTNZ6yBZPkWcYHqe+a7PG
 qE4V4j27CFp3Ks7KZKWcqBw+la5eWDawaBHsOrgxgEUoBFj2WOsOdLjGfSaotZMjwXVh6w9/qpY
 EboGao+eScyFL0p3wP/DNJ15mmbIJvRZ/D5jxNjNvrPoVmrTIb//y5Fi8nVZMU8P5Vc0UIbgpvo
 zniS3Vs8zxet5f++N/VEs8MeSG3kI2qSZ7c9/17NQmGizFjojUd0LqpBkJ89OPJNKPkLxbRoQpT
 gwBchZoh18w7tnfhVFEdhvM0gIQjdN2FMRxMJKAzNBDMEc16gQ1da34gEFfaA7J0zlJawO5Ok+7
 SLGEySIfPvat/echxOdjop+X8H4Mjhnk4XPjI/xIVmXYbhbYHoE6pRKWm++sIAEDourhE06vr34
 jdgDtjJe6g08+7dFznx4A6HxkPemJR8NqY0WYD9X7hH2zjVkIgdE7Lr5BTraQwPayCuSPPMrcFC
 jtf/6a2sUlStigVdz83Z1Yd7edf/gpKuyFwZ48aJVK/WHz1E2oMP2ZkmifyTU3YU3VgI+xk2qFW
 6S0WcWoI2rnaH7YNLOmB3LGy/va8bKB71QsAr7l4nOg1TdsDnR0mXYloCgWqAzXWIg1A3EFvPnY
 tzxRrQfx8vbCrkQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

This corrects the host initialisation sequence so that we can send
DSI/DCS commands in prepare().

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index 97122ec8872a1..0d3ae0689a19b 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -242,6 +242,8 @@ static int sofef00_panel_probe(struct mipi_dsi_device *dsi)
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
 
+	ctx->panel.prepare_prev_first = true;
+
 	ctx->panel.backlight = sofef00_create_backlight(dsi);
 	if (IS_ERR(ctx->panel.backlight))
 		return dev_err_probe(dev, PTR_ERR(ctx->panel.backlight),

-- 
2.51.0

