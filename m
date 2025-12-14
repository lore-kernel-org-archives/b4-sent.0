From: David Heidelberg <david@ixit.cz>
Date: Sun, 14 Dec 2025 15:51:21 +0100
Subject: [PATCH v7 5/8] drm/panel: sw43408: Remove manual invocation of
 unprepare at remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251214-pixel-3-v7-5-b1c0cf6f224d@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1036; i=david@ixit.cz;
 h=from:subject:message-id; bh=YxNdyRsS+jWwF0GJLCXUSzneFgU0OdR+Q5S8ObKr8gg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpPs7pk5JtLKnKdkCIskNQb6JYz2ZtvsFDRNpEd
 OVVuVzvsMGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaT7O6QAKCRBgAj/E00kg
 cns5D/423Rzm9+Lz7y7yDWnGiOf57algKXXrUD013LL5l4xOI+/kxRgZeAYs8+ohpxUEI3M3gHK
 zgKvoOxD8BNMu06Zzx8iWjw91Y8IE35kw7YuTx+eQ1wDREM816OPYTe6FMZ3LS6aAWBcwKO6+gF
 4gZsw8WbQce1mnYJxQY94Y9qqxJSHwTIkVpmCCudnSq3SlDQax3HwV6QUOv6WwMU7fmXFlyOivA
 Liz4JPAK4szUIwLeaCiNTYI5wF7M4pZeJ6G64qDEihS/vst2Wjq0rMt8lJKvs0nLS6IZ9sogVje
 fNatplEdIW91cUUDLeiJpZ+K7b515awonAWX8c7IqGQonbCInpJNUyHddsBOkFmTc4xHYMElDEl
 6I7NBUcl/2r6HlSBDcRyjLXAZy8cniyVexI7uBz7MUh3bEi0GKetAQoaBglpmPbo0rt5QBeux6b
 cCdBhObNqJEZuaWVjaIh+845H9VgcYiKHOQsPYAmpuTATIiiKpeDpkArnFto8eroHZd+ElaF6aF
 aBh9DW+GFtp+LWCF9V4bt72cIt80C5PDb9rewh7Sm5AcOcbQk9scp/xKeHBVhS4G5RjCRCho4Be
 LuRHf2b9lAiHpeLbWKVck5szkVmAccHEE0MPvHEAzsej1H/SeP9lplCA/9nfVvWa87bQKBSySmR
 OBl9IugoQcFLnyA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The drm_panel_remove should take care of disable/unprepare. Remove the
manual call from the sw43408_remove function.

Fixes: 069a6c0e94f9 ("drm: panel: Add LG sw43408 panel driver")
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index ed9c7452ea846..f9ec6e9b02c70 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -300,10 +300,6 @@ static void sw43408_remove(struct mipi_dsi_device *dsi)
 	struct sw43408_panel *ctx = mipi_dsi_get_drvdata(dsi);
 	int ret;
 
-	ret = sw43408_unprepare(&ctx->base);
-	if (ret < 0)
-		dev_err(&dsi->dev, "failed to unprepare panel: %d\n", ret);
-
 	ret = mipi_dsi_detach(dsi);
 	if (ret < 0)
 		dev_err(&dsi->dev, "failed to detach from DSI host: %d\n", ret);

-- 
2.51.0

