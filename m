From: David Heidelberg <david@ixit.cz>
Date: Sun, 14 Dec 2025 15:51:23 +0100
Subject: [PATCH v7 7/8] drm/panel: sw43408: Improve wording when
 reset-gpios aren't available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251214-pixel-3-v7-7-b1c0cf6f224d@ixit.cz>
References: <20251214-pixel-3-v7-0-b1c0cf6f224d@ixit.cz>
In-Reply-To: <20251214-pixel-3-v7-0-b1c0cf6f224d@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=955; i=david@ixit.cz;
 h=from:subject:message-id; bh=xiRuRI627EVxbYMotExrfzaJ9rtq89cPkPZhyucnC8k=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpPs7qW94IO0AcSLnbrZATEICV7JcrROYo1EJ9L
 8yk3YNgh4yJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaT7O6gAKCRBgAj/E00kg
 cuBaD/45BzmNR273ZnD0o/Jyo7UIWbcUXLdUkKD6Pbo2szq3SwOROX0RvCi8nOYebjycsHGcvVE
 WLv5yXfcynjxlxJB20c+cLDqGDzu08YdRKXAKNMgJTOt+CcV42KyENUPCbzXGpJ8PJHzWXcrSlR
 Vuc3CEPhW896+noSoNUlkWpkuXg9jdncI4amWLqipSw9qjoFeXT10LMaFW9cwjaiQc92aOEh53m
 qL3zEYqK1LdbD/soEtMV5TX1BvoJVc23COu9NpDK+QmaxVnJB9PMByyWS7hTq42N4xoNNeXCdzj
 EOFdFX9F1cRA67bDuhqYxFh7vJrtSLsrJ2DHyI08EMjAHzt3710Z8LF9ouHEuesOEk3YT5lcCxK
 hylu3HgYef4/DsoQsiLgGQ3T0OMIeNUmaiYXZFq8MiMC0+0RG+kLAljf22O5hBJGnIO6hySNqH7
 Uck1du7fkR8y20qdEM5A+oQ5D4CPi7m5cgdjaJpCAOlmIuPw4Phv5MeJwboBPJ2NwF1YA33o6Cf
 U+spQdNZtZO0IQ6DXirFr8IqUV8nfOMFwtyAo9ye+2wHzXcOzPdYC23q8UxkFhg76nY6q79rknY
 93eCeeyAA1/udewU5yqYV6Du9qw9cfc0tn7XWU+UGLP2EP9QdqoY0VXmq5XAX3iI+nQbmAD/vAr
 k1GpMcN6DWofAMA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Choose better wording.

Cosmetic: also inline PTR_ERR.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index a5708c7d04192..293826c5006b9 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -244,8 +244,8 @@ static int sw43408_add(struct sw43408_panel *ctx)
 
 	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
 	if (IS_ERR(ctx->reset_gpio)) {
-		ret = PTR_ERR(ctx->reset_gpio);
-		return dev_err_probe(dev, ret, "cannot get reset gpio\n");
+		return dev_err_probe(dev, PTR_ERR(ctx->reset_gpio),
+				     "Failed to get reset-gpios\n");
 	}
 
 	ret = sw43408_backlight_init(ctx);

-- 
2.51.0

