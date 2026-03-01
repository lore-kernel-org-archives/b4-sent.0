From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 01:51:27 +0100
Subject: [PATCH WIP v4 8/9] media: qcom: camss: csiphy-3ph: C-PHY needs own
 lane configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-qcom-cphy-v4-8-e53316d2cc65@ixit.cz>
References: <20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz>
In-Reply-To: <20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1623; i=david@ixit.cz;
 h=from:subject:message-id; bh=xJUXUtwBIhekrOdLKRvTP/J2Ey1JhDpeic7sPTFnqSI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpo42JBwEFoFHmRtNt2RnACQuIFO0B25Bk1KcHL
 LCMYuudgouJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaONiQAKCRBgAj/E00kg
 ckb2D/9QD2HGudr+0YjoFLjEVf53a3ZwgZGfpLQBVrLFg4AdFWKoLg8EjGd2FpVxlSPdyQ+ObPz
 2Uj/1Xz5yUgtRSuBQYjcgNkOSr6ZPQvDTSxLIQ7Wicu18wZRl3aWb3QlH7IfOpFnpLTKU78z5MO
 CB+zs7PcSfmQFwc8zdru/6n7xSjlptL1QjSLb5Jcy9lbel4vnM64Jv8sOJLK0pYJdGZbyxvzbIN
 IOj0sBQ7Ll2H3l1nwC6+wBNKf7ySLyaN5t1lS1A074AlKfvvtpTLXw6Vf4RQpefdX9raTB4ujD3
 9BlGZQzqwgr4c7+Xaab1xhkYOTq43qoIlbohsSi1DKlIHvU8kGhBflQiDlZnNNzsLiX27BwuqGB
 S1mVgkcWXF2D0h4PBY2cPjkEPDXE3d3M7pqpMZzNnhZI1woevOOl6R5FVpHEwMGxueN+USnptPa
 ygHA17qun12HUtZfptjtyY59Vm6AztwRPc1fHUMlytTTkaaabkDIdvQmkG4aMR/AcccZG1RUcd+
 A35YulDU26Tz/DHrQN6Y1bIdHDxGN5btZCmHLJXesPpuMIQIaYaVNKFTYeafjCNFnnpVOocbsA3
 FdgaaSclrd0bQBWJBHOm7u9q7cmX82vkZ85V5eVN3XL9R0UoS5h+k47EvaRWe4NtUHp4d2oFReb
 czcWyDXMz2zV6zA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Catch when C-PHY configuration gets used on SoC with CAMSS missing C-PHY
configuration lane registers.

Hopefully this check will disappear as these lane regs gets populated.

--
@bod
Proliferating special cases in switch statements on a per-SoC basis is
verboten.

Please find another way to do this, you already have a bool to indicate
cphy in struct csid_phy_config {} so at some level CAMSS already has a
bool to indicate what to do.

Please make that logic accessible to logical consumers throughout,
in this case the CPHY code.
--

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index e48f5c1290173..2164647211c8d 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1221,6 +1221,22 @@ static int csiphy_lanes_enable(struct csiphy_device *csiphy,
 	u8 val;
 	int i;
 
+	if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+		switch (csiphy->camss->res->version) {
+		case CAMSS_2290:
+		case CAMSS_8280XP:
+		case CAMSS_X1E80100:
+		case CAMSS_8550:
+		case CAMSS_8650:
+		case CAMSS_8300:
+		case CAMSS_8775P:
+			dev_err(dev, "Missing lane_regs definition for C-PHY\n");
+			return -EINVAL;
+		default:
+			break;
+		}
+	}
+
 	switch (csiphy->camss->res->version) {
 	case CAMSS_845:
 		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {

-- 
2.51.0

