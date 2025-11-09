From: David Heidelberg <david@ixit.cz>
Date: Sun, 09 Nov 2025 10:39:46 +0100
Subject: [PATCH RFC 3/8] media: qcom: camss: csiphy-3ph: Use odd bits for
 configuring C-PHY lanes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251109-qcom-cphy-v1-3-165f7e79b0e1@ixit.cz>
References: <20251109-qcom-cphy-v1-0-165f7e79b0e1@ixit.cz>
In-Reply-To: <20251109-qcom-cphy-v1-0-165f7e79b0e1@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Joel Selvaraj <foss@joelselvaraj.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1933; i=david@ixit.cz;
 h=from:subject:message-id; bh=rik/RHpeTR+s30xb3Tj4nu8A19TzZ21cIKR0hmDRMHM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEGFye+wbhg1bmncgyV4ERElXREXgeRp9B0QlL
 yWaPof/AxuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRBhcgAKCRBgAj/E00kg
 cg2lD/9JCjrf/49SXbWR/92Qg7/0NQJrKd1aAnJDHGr9QSoxJcO97CPoA/X55gmUGDPKgxx4F+E
 as+xkB73hQZetG888ca6bLKxyENOb1jSOYRINzFaQzQB4qnHnMdMN5fpgSeheUAmOm4l6gwRiK7
 h/hG5ArEaS5NhlZAh6eVmW6IaZspxoYXh2fvu9KNvy08hxikEg99VhN6EmorrFz6a4rExMwLMs7
 JSscqKZtMjxF0C7J+0J/4h8upV8aAy69MnbE74x+lYGpz/f3r+dVWbe9GOidsQKEuPYsmYzTGFq
 vJCIr3acoDJwV38CXoPCAPTRNBpKYOxKHCWVXztRyCnqCL/Sh6VyE26IuoSiqMltclT2EmyXlYd
 QlqduMwIWfKa0uI95bkStDktM7SbRKJpORq25qj8QZ728STp57vvoW1WISUEzHCG4MFcKax01lL
 SPAp6PT2y8Os1kurC5rznzETEAFgdqmNcc1dbgWR7sBCV3GE99lOo7aFS4NI/BjzvDMOy+/9z6M
 XPfY171BRmBD4GFJbCRxiEmSrUj6sz0dG12kO3imcxAIPSBKqX7nFHzqvh09HKsi/j4wIyVE1J/
 60WX4JNDsgtdthFJI//vKc4iAOZMnYHNPREkFP/Tq6wC0bfW/Tiuh+paDFa8U/Lh8k6+r2VC0oc
 Qj51DBYsZLa9YXA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

So far, only D-PHY mode was supported, which uses even bits when enabling
or masking lanes. For C-PHY configuration, the hardware instead requires
using the odd bits.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 25 ++++++++++++++++------
 1 file changed, 18 insertions(+), 7 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index f28c32d1a4ec5..348b8cd18327e 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1054,10 +1054,17 @@ static u8 csiphy_get_lane_mask(struct csiphy_lanes_cfg *lane_cfg)
 	u8 lane_mask;
 	int i;
 
-	lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
+	if (lane_cfg->cphy) {
+		lane_mask = 0;
 
-	for (i = 0; i < lane_cfg->num_data; i++)
-		lane_mask |= 1 << lane_cfg->data[i].pos;
+		for (i = 0; i < lane_cfg->num_data; i++)
+			lane_mask |= (1 << lane_cfg->data[i].pos) + 1;
+	} else {
+		lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
+
+		for (i = 0; i < lane_cfg->num_data; i++)
+			lane_mask |= 1 << lane_cfg->data[i].pos;
+	}
 
 	return lane_mask;
 }
@@ -1096,10 +1103,14 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 
 	settle_cnt = csiphy_settle_cnt_calc(link_freq, csiphy->timer_clk_rate);
 
-	val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
-	for (i = 0; i < c->num_data; i++)
-		val |= BIT(c->data[i].pos * 2);
-
+	if (c->cphy) {
+		for (i = 0; i < c->num_data; i++)
+			val |= BIT((c->data[i].pos * 2) + 1);
+	} else {
+		val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
+		for (i = 0; i < c->num_data; i++)
+			val |= BIT(c->data[i].pos * 2);
+	}
 	writel_relaxed(val, csiphy->base +
 		       CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(regs->offset, 5));
 

-- 
2.51.0

