From: David Heidelberg <david@ixit.cz>
Date: Sat, 17 Jan 2026 16:36:22 +0100
Subject: [PATCH v3 7/8] media: qcom: camss: csiphy-3ph: C-PHY needs own
 lane configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260117-qcom-cphy-v3-7-8ce76a06f7db@ixit.cz>
References: <20260117-qcom-cphy-v3-0-8ce76a06f7db@ixit.cz>
In-Reply-To: <20260117-qcom-cphy-v3-0-8ce76a06f7db@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1248; i=david@ixit.cz;
 h=from:subject:message-id; bh=hi1draDMnwPdDs8jfyuKlJLJyRCchlejwfH5kHTkrC0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpa6xzZuyGf/U/5S0suMcazfP+fy+n3xT4JQXGi
 wskuX13a+WJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaWuscwAKCRBgAj/E00kg
 crGDEACQZprBdLGE9LREwg8hMB/wq0tHg4YCWXxyzX33J01v1AJUB1i4khpdVVL3qAcidGggzU6
 +IveUeMakwoJNLE84/o4QYn2f02HgarO/jQj36QzSWr+Gb9cDuDP1MB65fhLqm4e0vqkyVwRwHw
 tfFFow8Y0HA0q2qJKUpPZfsi5xzbyyPOMhTGMGovppknucM/Jrpdpen6+/DsptVH2bPfcI8yhw4
 u47ouLfkeLlO+OY48mXuZv/8BD4X/r6unw2SHpvs1EePASC9BSKRqSkgAmHZ7PorGN60nTdIuvI
 O4tcvbEnTMkcL3HkWYmkLjAVKWavRA9BcvbawAS/TLjhiWqEhtAfTVVLf6mw+ytUR4OkCO5bEER
 6+Jhca+WiZSnKqKJv6kW5xlItDaesvLqj6WH01OjLr+qqVLUB/B0rOTpdYOukdxz56jQ4YkT3D8
 ZxegJJA/PJGosiXAIySa8h5XMZr0tQPkPYjPw5AaSRpsczoAHDuXT8UzbNUT+zra3IBlY3zG+Cm
 ORxOrAOayzJz5gVw3OFczQhMGhRLhUzQxL32VsF7ne9J79GYkjWXlmBJWjeSCa1D+JMSFdXSYwq
 rKS/7M1qntBKcJqo856fDhvm9VWp8hcwCxcSJWbG/d9ZGa/pbf3XjqhdNNCpzbyi9+CfIltzhwV
 nhTeejkhGbVrJCQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Catch when C-PHY configuration gets used on SoC with CAMSS missing C-PHY
configuration lane registers.

Hopefully this check will disappear as these lane regs gets populated.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index d82a88dad74b5..89bfe3710fc3a 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1217,6 +1217,22 @@ static int csiphy_lanes_enable(struct csiphy_device *csiphy,
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

