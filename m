From: David Heidelberg <david@ixit.cz>
Date: Wed, 10 Jun 2026 20:28:22 +0200
Subject: [PATCH v8 2/9] media: qcom: camss: csiphy-3ph: Fix lane mask
 calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-qcom-cphy-v8-2-cd4387785179@ixit.cz>
References: <20260610-qcom-cphy-v8-0-cd4387785179@ixit.cz>
In-Reply-To: <20260610-qcom-cphy-v8-0-cd4387785179@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>
Cc: Frank Li <Frank.Li@nxp.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1206; i=david@ixit.cz;
 h=from:subject:message-id; bh=fVr/sKiSUifC1zTyd9NJfz2/7dlahZ+nJFq+MKqII4Q=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqKazHrEq72fCIjBjv5GAwcwAD87AwFCvVFNX8o
 UcaO9akx5uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaimsxwAKCRBgAj/E00kg
 ctpwD/4/WsbiW6UstsGTs+oI+7288BjF7yxrlnh9CnB6PTSK0uj2fe50jkbGJWP45Gw0aCYoobM
 eabGhwamHCUahsw7Rmw3ewmJbIOcK5UNB/0NC57x/5XVZXMXYRLYF23AfC9O5wzHUh7RxZ4YeMY
 UNmuHdmhcyAahwrjAZTIBjbeqQUO9yFIFyrzXshdLlZE5ChpodZroYN0p2J7WVD/LDHIFsWEcHU
 Z636bAZ/72L9Zv5l3IUm8FgMZFG5vfHgJW1PdMwILI8UM7iVG71T+nTvfgTDRd0jQQ8ekwBkhqY
 DM7Q0qe9gsaXejuf8nA4+FLNOeMxrof7iw10YuVsI099/juO//84+HNWomMEAdbNN91bnFdnWwD
 lFNNDjvYC1AFxK3ApgbiitMZMP1YQN19hevUBOqZMNrvJ2K/v13fsZkts/LKApZuxcmKfoisHNG
 aWNRQfi+W//gqYg7nDBaiLWnO6B4RklvCJvYA68N3z478jkRIdJpmZGh5U6SG8LxUuBBSKthXqB
 0w+YMH/Zoa8VVbrU2NNq2iQnzQZ7y2UDViAtil3sREALE8OAXeAh8YdNOsxfUVi2w3uv8GYx3LP
 f+BscvKk5Fvs+m+/xtO7udSCXkCUXcb7aXIaQx5wqTa7mzU4sy/k0fVcWCMdmvvvZl4O1yI+wfI
 5CRlocIMb2+jzfQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lane mask must be multiplied by 2, but this was accidentally omitted.

Fixes: c94d21ffa814 ("media: camss: Add CSIPHY files")
Cc: stable@vger.kernel.org
Suggested-by: Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index dac8d2ecf7995..7c8c0e41bc62f 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1114,17 +1114,17 @@ static void csiphy_gen2_config_lanes(struct csiphy_device *csiphy,
 static u8 csiphy_get_lane_mask(struct csiphy_lanes_cfg *lane_cfg)
 {
 	u8 lane_mask;
 	int i;
 
 	lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
 
 	for (i = 0; i < lane_cfg->num_data; i++)
-		lane_mask |= 1 << lane_cfg->data[i].pos;
+		lane_mask |= BIT(lane_cfg->data[i].pos * 2);
 
 	return lane_mask;
 }
 
 static bool csiphy_is_gen2(u32 version)
 {
 	bool ret = false;
 

-- 
2.53.0

