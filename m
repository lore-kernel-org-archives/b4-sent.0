From: David Heidelberg <david@ixit.cz>
Date: Mon, 08 Dec 2025 10:42:00 +0100
Subject: [PATCH v6 7/8] drm/panel: sw43408: Improve wording when
 reset-gpios aren't available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251208-pixel-3-v6-7-e9e559d6f412@ixit.cz>
References: <20251208-pixel-3-v6-0-e9e559d6f412@ixit.cz>
In-Reply-To: <20251208-pixel-3-v6-0-e9e559d6f412@ixit.cz>
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
 h=from:subject:message-id; bh=dZWtlEK2SHiGGTwbkLjudIbRYRyXhSNsD11k1PpY920=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNp1/LGupKmLwTHUbdE6Mi+rzMOjDQPVev4qCi
 mgH9TAz/uyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTadfwAKCRBgAj/E00kg
 ctjJD/0bKiC9ji2CvVmOnM+ywdGjn+QPwD42c2H6AvGxTEfob7IUszojjuZW03ruHecKGE294zl
 3SBIw5S7sFxHhsMFuD/fz60PJ9CoPesyprWbeh7WAvimi7yRP9W9365CwnOkyBXCW1AozYia/sc
 LVBd8fPJ8qMbuFpvzRPnD76TcyLsQElLEqzJrpDWgEuyTSlUcUJNRYNqPxPuxiN5W34MZ2mfrU6
 nYlCE9Ya2eOYL6CexaA9eCoip9herkSAiALZYUh4YiDsuKXydZTrmrjPzqLQq/kynBm2F1ORTNq
 ksLUHv3pvTFswoCBfIcVX0tGdnkxbd8g6Y9/f4bD2DZDkopv17DbuAqEeivBgj5+8nkPgc5VwIp
 nX+i9dLexMfY+K22SjFNV0cBWgTykTJZ9m0fJpLRmFuKZDFkhPXiwDacq3CF6wLTG0AbFge+oD+
 /gy+UCfY55iJWHioZTiPi3+uwV53l4WHi28oqe3WW7I0lY2zuOa2lFg2tD7gXFt3dwDHquZO9W/
 uq/hd73uVDMIP4PTYL2/tiHHnhTYaELqz90T60mSbASzWO3lZfpygFTrncQ/DoF1an7j9ZOwvhL
 v/nq/gVWMnk+KwHWJaz7JwcFV8D7Hwwk4obpgTR+yiU9D/uTGd/9JWaOl4ogOCQh3gY27FghiAz
 5Hk4PI2REPwmDXQ==
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
index e8a970b53d873..edc7749d98d71 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -262,8 +262,8 @@ static int sw43408_add(struct sw43408_panel *ctx)
 
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

