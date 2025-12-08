From: David Heidelberg <david@ixit.cz>
Date: Mon, 08 Dec 2025 10:41:58 +0100
Subject: [PATCH v6 5/8] drm/panel: sw43408: Remove manual invocation of
 unprepare at remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251208-pixel-3-v6-5-e9e559d6f412@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1036; i=david@ixit.cz;
 h=from:subject:message-id; bh=PuiywuMQuz5mfrzYWDI/bKjfM/bNSPMPp8guUiS9OJE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNp1/nT0ncW/HN8DC1BrbtohoM1XJFWXxG4QT6
 OckF71CXOiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTadfwAKCRBgAj/E00kg
 crxGEACM8tsp7iNoZNIaes9bqO8Zr6PDCG/oAIECR2DvXy2Vni+p678GWQNjcGvI38Hf1taUiVg
 r1TfFU1aEzPMsxTeT3bH6D0cx3w4r2/+IJTZf5UJZhctl4V79mtnkgz6viBkGw59JTNM+oGUN7b
 CHnxaIcMqa+NH5O/cREOpRg/OXhiKfkUSsRdRAVCOXCCd9V+gR7w3fXTzbYo6epz4rx9la9UzLy
 1nFqTjlxRjXjS5f2PULAFzI2ByvJPk0OoN9fVHUbJCdK0YvufAwEA41Kxq8rIq7JMqfdRO38Q71
 aIL9SadNQExjV31pxmCSxrc4mq1N0JmfyzKv/g4RaKs2iQlknnITiwstVxgrb4QX04OjNiBQpGt
 +OYjOTTHW6r0/LrQI5eZx2Qe3NWLxOVjCk3NkXGqqNNo6HvRBs3ivAK3qEwnlsJsVW7FectspfS
 bxsOqUKfBSNCMNTvDCQn6L82njuZTFL+ak8fZapzB2cKO+brL6efoBSPIo17dazXgMQ0z+nWNiK
 mXcBEEFyLHWqFECMmeBkPNg6ZSybM//j7t6cvi373+8oxYedT67JK3sDd+PIXkascIS422oN0fC
 S9V0hFX8xShPPguAw7+UgnwXife3rDFaeNdB1phTbSNBhstsrNLkdoh95FTpfLFimONdA4bYAds
 i4EnvBYzfzewT2A==
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
index dad6b967b92c2..06b9c5e650edf 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -318,10 +318,6 @@ static void sw43408_remove(struct mipi_dsi_device *dsi)
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

