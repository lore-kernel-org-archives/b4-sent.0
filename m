From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Nov 2025 15:21:37 +0100
Subject: [PATCH v3 12/12] drm/panel: sofef00: Non-continuous mode and video
 burst are supported
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-sofef00-rebuild-v3-12-6cd55471e84e@ixit.cz>
References: <20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz>
In-Reply-To: <20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz>
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
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=802; i=david@ixit.cz;
 h=from:subject:message-id; bh=aJ/EglBDysKAXREtcXVh/z+Zh6bgaROjs/Vk7ZuGVZs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHdJyUgxKl+tyy/rxnd3ByE1L+Mfe9B9bTkPee
 MJVkwSsUUKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaR3ScgAKCRBgAj/E00kg
 clwyD/9fUWuyonL8WuG+fTSZT85ZATR6y9QZJHZTGC0Dz0k587dKkHXiq1iJClfNO7LBAWWvjhZ
 UmiHaDU1mM0KZIxo97E301s/ocIacaSvbsGMLx69Z6VPOy00IGZmVVJmrX2708XBfaCWwMJNAXi
 rbynfoy99gZnH/Edzv8cad2wyicOZR2nJHmAvqYYxk61AEc/uBqfwlWLbcfnCqa/TxWWXI7wiYB
 f58nO9XAbsDDNdR/yd7bNW3d17eFwQ3ce0QAINiPzWZvOb/R5JRrHL8rkFtTxxDLcrB8Uk3akSJ
 xR1RB2Wl0eRplxbbwnIT+QyhxiiP5Qkk/75uw/SJ3GG2UswmLTqnFRr4jsdCGI6zxVLLmjguNuT
 yUijUGf7fx45zsdMaraxPq4UqL5tV+Wo+9DL4NEq0FRqxzHM0L8mmiKxkPUVSfSD+08A1Gv5gpb
 lxHifHWXE/Nl7/7oa6GfWZI/5WvoiwcSXsxlFf0BGeRL4HXbXogJpT0/01FpDoudFDPF4DOYa1d
 edFsioFRXFPvCdcW28TphGT60ghR2ObbSWN5yR87ctg2q0xPrysBbWVqg3jWj80bNRK76+NODUV
 8TdyoNJML4CR8ZefQ75Ulh1JF6YESUuu7nP/W/BCViEywHAejH9nazcKGKgE8m7J6b5scRun+I3
 TubsItsGLoGMzxw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The panel supports both modes.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index db9c181695f1d..e00a497a7c961 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -236,7 +236,8 @@ static int sofef00_panel_probe(struct mipi_dsi_device *dsi)
 
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
-	dsi->mode_flags = MIPI_DSI_MODE_LPM;
+	dsi->mode_flags = MIPI_DSI_MODE_VIDEO_BURST |
+			  MIPI_DSI_CLOCK_NON_CONTINUOUS | MIPI_DSI_MODE_LPM;
 
 	ctx->panel.prepare_prev_first = true;
 

-- 
2.51.0

