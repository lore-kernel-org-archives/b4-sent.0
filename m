From: Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>
Date: Fri, 27 Feb 2026 20:15:01 +0800
Subject: [PATCH] phy: qcom: qmp-usbc: Fix out-of-bounds array access in dp
 swing config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260227-master-v1-1-8d91b9407fdb@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAMWKoWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIyNz3dzE4pLUIl2LJEsTi2RTM2Pj1EQloOKCotS0zAqwQdGxtbUAVve
 n8lgAAAA=
X-Change-ID: 20260227-master-8b948c5633ea
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 linux-kernel@vger.kernel.org, fange.zhang@oss.qualcomm.com, 
 yongxing.mou@oss.qualcomm.com, li.liu@oss.qualcomm.com, 
 tingwei.zhang@oss.qualcomm.com, Konrad Dybcio <konradybcio@kernel.org>, 
 Dan Carpenter <dan.carpenter@linaro.org>, 
 Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772194522; l=1203;
 i=xiangxu.yin@oss.qualcomm.com; s=20241125; h=from:subject:message-id;
 bh=pdrpH5cTTs+ijKgI12OITbrW3X2fkvMKZRJEqz9UHyo=;
 b=MCp8ELqBe4xNj0zEqPVDUDfiJUGcLcxa4ZPNWTAC7dcq0ZgPqU1gJXVl+HmIE/g0m5C0W/gzt
 r50BRSiilyaCI5SXfWmUohtIIHvcugL/WhmjrgXKfLe54Ft6bn1VKJH
X-Developer-Key: i=xiangxu.yin@oss.qualcomm.com; a=ed25519;
 pk=F1TwipJzpywfbt3n/RPi4l/A4AVF+QC89XzCHgZYaOc=
X-Endpoint-Received: by B4 Relay for xiangxu.yin@oss.qualcomm.com/20241125 with auth_id=542
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

swing_tbl and pre_emphasis_tbl are 4x4 arrays (valid indices 0-3), but
the boundary check uses "> 4" instead of ">= 4", allowing index 4 to
cause an out-of-bounds access.

Reported-by: Dan Carpenter <dan.carpenter@linaro.org>
Fixes: 81791c45c8e0 ("phy: qcom: qmp-usbc: Add QCS615 USB/DP PHY config and DP mode support")
Signed-off-by: Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>
---
 drivers/phy/qualcomm/phy-qcom-qmp-usbc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-qmp-usbc.c b/drivers/phy/qualcomm/phy-qcom-qmp-usbc.c
index 14feb77789b3..0dd7000614f4 100644
--- a/drivers/phy/qualcomm/phy-qcom-qmp-usbc.c
+++ b/drivers/phy/qualcomm/phy-qcom-qmp-usbc.c
@@ -794,7 +794,7 @@ static int qmp_v2_configure_dp_swing(struct qmp_usbc *qmp)
 		p_level = max(p_level, dp_opts->pre[i]);
 	}
 
-	if (v_level > 4 || p_level > 4) {
+	if (v_level >= 4 || p_level >= 4) {
 		dev_err(qmp->dev, "Invalid v(%d) | p(%d) level)\n",
 			v_level, p_level);
 		return -EINVAL;

---
base-commit: 7d6661873f6b54c75195780a40d66bad3d482d8f
change-id: 20260227-master-8b948c5633ea

Best regards,
-- 
Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>

