From: David Heidelberg <david@ixit.cz>
Date: Tue, 04 Nov 2025 23:16:20 +0100
Subject: [PATCH 12/12] drm/panel: sofef00: Non-continuous mode and video
 burst are supported
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251104-sofef00-rebuild-v1-12-dfcfa17eb176@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=802; i=david@ixit.cz;
 h=from:subject:message-id; bh=OE1UAGoiypb8yw70x3xMaGL61XZlHwmG/9vzbFRjYK8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCnssHwg8Lskik0Sixi0f0lMdo/NU6KJS+qhtl
 c+BcqyrhcGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQp7LAAKCRBgAj/E00kg
 coP3EACq2H5LzaMgEuOSQdBm5V1/Z0IrgpWiiHh00ZeFLGXhSzhNbJyT4zifpu9FOMDE2JKiHwK
 e7kvGVDLhKE+e2bKTOF4xgW2gx9HoQcqHbuZyu2uuKASiT58GD50SDuWQk6hUHVB8rQRFuOrnzC
 8Y7xnppScEJhsgHbf4hM4qWwptHFsL9IJY32cusiD2Y4vqsLz4WAasilNxd1xYNUjzqq5WiHTOS
 7k6JGFPmZkPHvuFWaPN2HVIak8OxcEL21w6/lFdwRjROjDl5yDn6EwISDjmVgauAaAMXxZbg0tY
 Eza2y0tCWO3K4WLQN0kL7TWF8lcFx7PWJ7n9NtivduDJgnKUCVRQ1wMMFnO22+bIwRjElM9VSkk
 Vzmjk8nNAjXg1HKnrGKNNae6pf0H7ZSb2NGQFGqXB9fN54KEBUx9SamPh7CQaT5WGih+SVMj7SG
 0XlTY/jkpXkLmDWPIlatE+jOQxwRfwpY/m3eybnCjHYx6ONZqt82WbFrl0IdLwwyfo1yQIJh8Bt
 zn7A3VVUrnWbpvbRoxuTaFFb0j9jpsGkTkGiEDScYxR+4QSZo39WUIPkSIEtWc5jIkPYn7VhxP5
 XAsBYLWaW0bMfx+GXH4eD7TEgF4PjUdWas3prmx0BeWDzSdunxvHegoiUtrhg0DvNj5GOqmGkUq
 yb5CdZWYqCESkXw==
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
index 8286cad385738..b330c4a1ad19d 100644
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

