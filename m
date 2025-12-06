From: David Heidelberg <david@ixit.cz>
Date: Sat, 06 Dec 2025 14:34:24 +0100
Subject: [PATCH v5 7/8] drm/panel: sw43408: Improve wording when
 reset-gpios aren't available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251206-pixel-3-v5-7-dc99732e7d35@ixit.cz>
References: <20251206-pixel-3-v5-0-dc99732e7d35@ixit.cz>
In-Reply-To: <20251206-pixel-3-v5-0-dc99732e7d35@ixit.cz>
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
 h=from:subject:message-id; bh=GyQvEwxDvNQdHbjN2iJyHIARYij0btqlXIWdWGzCINE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNDDxtdsdyZTRII7faXPHMLqcHBdNUtm1hB4n9
 Y/tQ8DwiHmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTQw8QAKCRBgAj/E00kg
 cgoGD/sGRfgdLMW9j5UXx+fps1MGyddnL8U5s42c7eYZmeSUQ9DuHGUMoLC1wUoBWDSr+ncCVjk
 ohFTrMRteBjKioco4gdoCm6CnNaepk59n2qGsQPHZSB99dA73a/XZciVeOfBr+XutqBGfMK1wNR
 4x7DzdnJj2lb/7zUufZR3r9GhO7sf0+0z1PaiJ7nATKIgfE70AwqWuOsGKNraw4lica7Y0msov6
 Di+6PKOmb/5GES9mvJtQ3Z1aUGoGrB4+7ei9T+UtmWZrTazkGeKsijLv0dKQquPoo679HnDtM9w
 MxkzEZ0WfmgojdxKuYSXNbMAiK4RSkrcfM+a1n6i0k7odi51zE0yWZKycyd9mhJaVZCxCNIS3S+
 R1YrKNSxDoUYKvDGT2301yXYZHOt+HksLPHQ2KxZZDfLBpDN6ca098WtDdm0cYysPRtGW6A8JcW
 V1Ljz29QORgmsn5OxWeaCOpAw8LN9tPGbzk1Mh5xHtGaiLJwTglX14q5C+UW86IAKqiJgbt51G5
 nleLMD84u/Z/Ae/PC+jOFETq+t2zCIl86I/7m8Yqgt6VmSMLB3UrFC2Yi/u/Efrk8RvyBj2EvW8
 7q7QBTnN6vFmenePwrRM825mEdzWc4Tu51+1igSRyelu/VRFjQFuKjVi8OLRl4MXf1g8xwieCJ3
 t/T6mQSiE7g4yRQ==
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
index 65d54c8a9630f..bef60dfc925d1 100644
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

