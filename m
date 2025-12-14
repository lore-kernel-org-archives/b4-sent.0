From: David Heidelberg <david@ixit.cz>
Date: Sun, 14 Dec 2025 15:51:20 +0100
Subject: [PATCH v7 4/8] drm/panel: sw43408: Separate reset sequence into
 own function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251214-pixel-3-v7-4-b1c0cf6f224d@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1539; i=david@ixit.cz;
 h=from:subject:message-id; bh=5aFne3CXus5NuIRnX30e5rFmCgrdPMD+0rFZ6fyE3yo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpPs7pU6yexG9rodzNHtDr27W0QxJohKicQ8AWk
 Yd2GeLMKg2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaT7O6QAKCRBgAj/E00kg
 crfOEACr/nul51iXYZAg7d9hPYj/1defLJUI0rZLjsEdRcrLrZJ4OIcP+LpUjy91cIzgdNbbeq/
 yNYGJM2PqzU5bspzz+r32zl+oeY2xzHkPFaRyevtsVlC8rZstZ91+gyXFaPZy6m+Cst2FyHFmsI
 vUDPEe9vvJ4Jx1/J6l9We+1u0LU5GGo/1qIVvgSod7cNwhk4k7U7t19rAYvP+sly+KAZ+K9rHsO
 JQJQz3TicLIHj4Mbr6Jy86fUxzBM/CVX4Vg5YaSMXhT9R8HQo/HgkwC3Bvduq5f82PU6TBclIW8
 1rsymaKmCsra6fZRXTWDAurSiCPrn7+0uyQNv+JnNMtqAjuu0BPlVslAGXG1SXC77wZ7Neu3Yg8
 xPmsc25l4b6+7lrLZpTCs0OTWh5F/D1Y+v2FUTleB1GYd5jHjP8cTEtrk1QWP78htU1fM8a8S9u
 2yyrHuGe03z3IK/fKygZZV8tsGlGh5O1wiRVn/T8ZPVoRr6X3uY+3oGMLwBDLJ9u4AGJ+3bxsEY
 V4E5zIkX9mbXMmvN6NgGkd61vFqSykBmwMUlX9+ZGVx/4H8ORkNtRlg+f0pl9MVEempilIycQ1i
 KlRxJD/oHX8E6M1jMtxzgz3eOGc5QcvWfzmacvLejyMVk1g4b6jBtlF4RIqcT6yuWCiIvD3jGKk
 6COADOMXh1qiIbg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Splitting reset() from prepare() follows clean coding practices and lets
us potentially make reset optional in the future for flicker-less
takeover from a bootloader or framebuffer driver where the panel is
already configured.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 17 +++++++++++------
 1 file changed, 11 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index dcca7873acf8e..ed9c7452ea846 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -119,6 +119,16 @@ static int sw43408_program(struct drm_panel *panel)
 	return ctx.accum_err;
 }
 
+static void sw43408_reset(struct sw43408_panel *ctx)
+{
+	gpiod_set_value(ctx->reset_gpio, 0);
+	usleep_range(9000, 10000);
+	gpiod_set_value(ctx->reset_gpio, 1);
+	usleep_range(1000, 2000);
+	gpiod_set_value(ctx->reset_gpio, 0);
+	usleep_range(9000, 10000);
+}
+
 static int sw43408_prepare(struct drm_panel *panel)
 {
 	struct sw43408_panel *ctx = to_panel_info(panel);
@@ -130,12 +140,7 @@ static int sw43408_prepare(struct drm_panel *panel)
 
 	usleep_range(5000, 6000);
 
-	gpiod_set_value(ctx->reset_gpio, 0);
-	usleep_range(9000, 10000);
-	gpiod_set_value(ctx->reset_gpio, 1);
-	usleep_range(1000, 2000);
-	gpiod_set_value(ctx->reset_gpio, 0);
-	usleep_range(9000, 10000);
+	sw43408_reset(ctx);
 
 	ret = sw43408_program(panel);
 	if (ret)

-- 
2.51.0

