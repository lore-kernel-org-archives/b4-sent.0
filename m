From: George Neacsu <geocausa@gmail.com>
Date: Fri, 16 Oct 2026 15:56:15 +0100
Subject: [PATCH v3 5/6] phy: qcom-mipi-csi2: Use fsleep() for init sequence
 delays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-x1e-cphy-rfc-v3-5-40a346a72153@gmail.com>
References: <20261016-x1e-cphy-rfc-v3-0-40a346a72153@gmail.com>
In-Reply-To: <20261016-x1e-cphy-rfc-v3-0-40a346a72153@gmail.com>
To: Bryan O'Donoghue <bod@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 David Heidelberg <david@ixit.cz>
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>, 
 Vikram Sharma <vikram.sharma@oss.qualcomm.com>, 
 Suresh Vankadara <svankada@qti.qualcomm.com>, tjose@qti.qualcomm.com, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, linux-phy@lists.infradead.org, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, George Neacsu <geocausa@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792162570; l=1325;
 i=geocausa@gmail.com; s=20261015; h=from:subject:message-id;
 bh=9kgF6eCoWKoJtXzcHCM7JYWoQiK6MqWjKyWCuLZbYNo=;
 b=MJURgf8PcL2d1vyDxikxUMr1tK+dJRgdnoA1QAvGbpfjfoaSr74WoIqg0h+eUoZLDJNwlmfdv
 3WkbvGu0E2dAeafzBDOHgziTqZnzU5jtj8You2l1rWxSqY7RvWnwhae
X-Developer-Key: i=geocausa@gmail.com; a=ed25519;
 pk=KyQk/iWbxsikewDBh0SwlHI51RvAqahD3loqmRp9DVI=
X-Endpoint-Received: by B4 Relay for geocausa@gmail.com/20261015 with auth_id=1199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The init sequence delays are applied with udelay(), which busy-waits.
That is fine for the 1 us delays in the current D-PHY sequence, but the
X1E80100 C-PHY sequence added next waits about 3 ms after its reset
exit, and busy-waiting that long is wasteful. The sequence is written
from phy_power_on(), in process context, where sleeping is allowed; the
PHY reset just before it already uses usleep_range().

Switch to fsleep(). It still uses udelay() for delays of 10 us or less,
so the existing D-PHY sequence behaves as before.

Suggested-by: Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: George Neacsu <geocausa@gmail.com>
---
 drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c b/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c
index a44e104301..84c45f67fd 100644
--- a/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c
+++ b/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c
@@ -264,7 +264,7 @@ phy_qcom_mipi_csi2_gen2_config_lanes(struct mipi_csi2phy_device *csi2phy,
 		}
 		writel(val, csi2phy->base + r->reg_addr);
 		if (r->delay_us)
-			udelay(r->delay_us);
+			fsleep(r->delay_us);
 	}
 }
 

-- 
2.53.0

