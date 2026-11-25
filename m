From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 14:08:12 +0100
Subject: [PATCH v3 1/5] drm/panel: lg-sw43408: use the full DCS brightness
 range
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-fix-blueline-panel-v3-1-914b4a30b73e@ixit.cz>
References: <20261125-fix-blueline-panel-v3-0-914b4a30b73e@ixit.cz>
In-Reply-To: <20261125-fix-blueline-panel-v3-0-914b4a30b73e@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Airlie <airlied@gmail.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, Jessica Zhang <jesszhan0024@gmail.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maxime Ripard <mripard@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Simona Vetter <simona@ffwll.ch>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Thomas Zimmermann <tzimmermann@suse.de>, Vinod Koul <vkoul@kernel.org>
Cc: devicetree@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1238; i=david@ixit.cz;
 h=from:subject:message-id; bh=BTFoVtQ+iUfQkeRFRyilwFinpDXvmQQRSApa2qXLTP0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBt3BfYaMW928WOflnWdaGzyvapdChsW+JU+vU
 mLw7o1aUEKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawbdwQAKCRBgAj/E00kg
 cizCD/9Q+0moQNafz3AdHRwJAvSxq/yQOdJqD/kUukDkcsb7HcP5EEsCAWxuzo5hP5IsoMWD+HP
 EY9ptHylH7xhn2CBnnbZo3JtG7+zzAMpNURQrzSBEyet5HP4MduD/Xr3+MdViWLFV3YssBbBuPh
 7KPL8ixG6yP+rnyV2IyBzXhGeJZ6LLgdOVVZ8gP8EJIGoiz1c5ecXeD6YKdH62sjkvA3NMQErdo
 SSBhcTZU7GCLJIEt4l0zeQ6rvVZfVjTJBLQOud511b9xjBTP2l9T4nhgyyzXvvC7rJA8pkvkErT
 4dzC3Aww5Czl+jn/9zhFUfRPp5HR7YM3wzHk761TkvRvpWiU5X20sOa7VjQiEnYv1iACwN1DXQq
 Mp0xf3zaucVTgKXgPe4Kn0K+qBlMiWqEv5h1gmP0AB4LahoPZsj7j5V1Mb2Jqt8X1MnMupOWJdn
 QjGbuVMrytRnI58OwfNsBu3JvBm7UkwAhMW59U8uGmnwfIWxCCouGkUjmJgJIhTXk4CcHLX+lQo
 9/SBxzU12zDHAOZPVTStv2liMnNonq8vcCPYYRSo7uCkVOc9Teg3ot4GPRd7T9JlmDOH2sV0eKf
 q2knHBpZhtujT68zot7eH8B67mHyko2wNfheDUfb5Gu8HfDfi0Wc9sGZGn7DxC4LobIBzHwoRZa
 bHi6StcgAj9om+Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vendor changed the value multiple times. Last value for production
devices was 900. HBM can go up to 1023, but keep value safe for now.

Fixes: 069a6c0e94f9 ("drm: panel: Add LG sw43408 panel driver")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index 822318f546ef3..92cab6478ea61 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -197,17 +197,18 @@ static const struct backlight_ops sw43408_backlight_ops = {
 };
 
 static int sw43408_backlight_init(struct sw43408_panel *ctx)
 {
 	struct device *dev = &ctx->link->dev;
 	const struct backlight_properties props = {
 		.type = BACKLIGHT_PLATFORM,
 		.brightness = 255,
-		.max_brightness = 255,
+		/* HBM can go up to 1023, stay safe for now */
+		.max_brightness = 900,
 	};
 
 	ctx->base.backlight = devm_backlight_device_register(dev, dev_name(dev), dev,
 							     ctx->link,
 							     &sw43408_backlight_ops,
 							     &props);
 
 	if (IS_ERR(ctx->base.backlight))

-- 
2.55.0

