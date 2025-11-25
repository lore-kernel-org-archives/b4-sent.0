From: David Heidelberg <david@ixit.cz>
Date: Tue, 25 Nov 2025 21:29:42 +0100
Subject: [PATCH v4 7/8] drm/panel: sw43408: Improve wording when
 reset-gpios aren't available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251125-pixel-3-v4-7-3b706f8dcc96@ixit.cz>
References: <20251125-pixel-3-v4-0-3b706f8dcc96@ixit.cz>
In-Reply-To: <20251125-pixel-3-v4-0-3b706f8dcc96@ixit.cz>
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
 Dmitry Baryshkov <lumag@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: phodina@protonmail.com, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 David Heidelberg <david@ixit.cz>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=955; i=david@ixit.cz;
 h=from:subject:message-id; bh=eyxrhAjo3Q3LBCz7245BV72/yNQ0oT9ykg2uQo9OmMs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJhGyTxgwG8AsET/cblYpmHX7APSrmhsNA85TZ
 rEKxp6ieWSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSYRsgAKCRBgAj/E00kg
 csqZEADEmGJFmvTEMJKBfgf7QkfEJ8QSHlzdoY/CWgcOTODlZoewA+VUHWBjNdwe8u8sT8NXB6L
 WdQMrQbhIUJpagjYk7H6xgWR/d8WOP9iQ3WSFBGphi+s9SaYblfPR0zoypwBLh7BqOJrJQ6Vb8K
 Fly4A6O2BfWY7JBqlTnBfH+fs/jvDc9UYkzbTCWKFjQXD9gaAZ6wRY5q3mbh1xJAbI4BRoCzoxd
 hpBFilesNdkiKyQpOT/xDrd4nfrGb3kUxrU6Pt2SKoKq+gn7HDzBUVtCFtI8Q9WYOMpER257iKQ
 bZMJqcbUn4W9PbZ1upR3C61195GtlwHjgN7L7WJgRB//lzCy9Wc3f+ctG1cE9jqrXkgdNqrkTfW
 oR2su62hd4G1g1MqCrgCHGugzhpUyQNpok0S8bg3lmADlu9DJvRvIkvWOpARmhcdmw/KwKMFGo+
 gJQWnM74c26gHvo0fNFpYm7yPZvEOIenOhlBrlELY/DlUEjPtGhzRRE0czqV/JFQdW783qx+5yD
 8rDSoYcZ7tKchZfmjTWw6CkTPELYYo11uyh4RiNtP4xvx6ST0qB0MKGN2slL2HU64ejVYJJWDTK
 QQaelIyq7/pC8hsDmieswlw756IRx5bYZ+NNcFkRPyBMJeLv1H8yuGgq6ThPWwbhpNg7Eiw2OdB
 ChgH/q3/xEoIeRA==
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
index b147f337a7861..c6384b02ad6e0 100644
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

