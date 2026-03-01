From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 01:51:22 +0100
Subject: [PATCH WIP v4 3/9] media: qcom: camss: Prepare CSID for C-PHY
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-qcom-cphy-v4-3-e53316d2cc65@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2138; i=david@ixit.cz;
 h=from:subject:message-id; bh=VE5OUEM0X//rg3dmLrS4SJXKFfJ1U9PcL8DiivLtXg0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpo42I49cCzgz9a1iEZzYEzT800pShZjkIyRzT8
 9ClYGl3pyeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaONiAAKCRBgAj/E00kg
 cp9uD/9t4vqsgoKkGQC54Qqxi9WS+6D9RT4VTCOiO1cKBCcARAmg75XqmFtZ+Le6RsdZwA0JgzX
 xRfnpM791q0ktfoQkuCWV+HHrToLx9GH0qa6l/vE6twum06ypp+Q9QSfRKOBHE78o1eQ1hRmVAy
 KUxBCsjmuU9oVZUsEXrHWsIeiIiT0lJCRSTA5G0TsmizpzhV7fFmBd5AqpnH8Ecw+2ZznzqXtE8
 iWlrA3Lx283fTilleNYC9KbBu/gC1nL/w+XXXVEKTEZ/YpasNc1I30Ibw1TwrRo5GN/DbHr68uP
 IeSGkDTg7sJsq1LlWcBhLssChBFMbfGHXyl+mBeZjutobRkgIIzt+tXhe9XwLrAUGf9+dsMYlZY
 vWgvDLJa1pufeMR9ej8zEe5wRXFbED9+79tyo3jhLjdhxpGjT9ZV9If42W79qJbMRFhBbVJlJ4s
 sXDMCKxY6cZU2+7ELksLXNexpQM6QZ35UEDLr9VyN8rEXNUAfDxaH9Yp4xG8FkrMsNBe4rpJaVX
 BsfVuRI+8h294p/NRIPr+cfZbsSHt0Uccg9i4xV23EHckSuBbABJuXPrFy8SFd8JelUSiUwlLI1
 C6Dsp5/NK2Z16aBqKHTBOEeS5ffZNN29PUu/ROwVWPMmN78fCvJ6YPv3j2t4rbTGhL0oxsedpKL
 0nXgdjA9earRARA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inherit C-PHY information from CSIPHY, so we can configure CSID
properly.

CSI2_RX_CFG0_PHY_TYPE_SEL must be set to 1, when C-PHY mode is used.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csid-gen2.c | 1 +
 drivers/media/platform/qcom/camss/camss-csid.c      | 1 +
 drivers/media/platform/qcom/camss/camss-csid.h      | 1 +
 3 files changed, 3 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csid-gen2.c b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
index 2a1746dcc1c5b..033036ae28a4f 100644
--- a/drivers/media/platform/qcom/camss/camss-csid-gen2.c
+++ b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
@@ -183,6 +183,7 @@ static void __csid_configure_rx(struct csid_device *csid,
 	val = (lane_cnt - 1) << CSI2_RX_CFG0_NUM_ACTIVE_LANES;
 	val |= phy->lane_assign << CSI2_RX_CFG0_DL0_INPUT_SEL;
 	val |= phy->csiphy_id << CSI2_RX_CFG0_PHY_NUM_SEL;
+	val |= csid->phy.cphy << CSI2_RX_CFG0_PHY_TYPE_SEL;
 	writel_relaxed(val, csid->base + CSID_CSI2_RX_CFG0);
 
 	val = 1 << CSI2_RX_CFG1_PACKET_ECC_CORRECTION_EN;
diff --git a/drivers/media/platform/qcom/camss/camss-csid.c b/drivers/media/platform/qcom/camss/camss-csid.c
index ed1820488c987..b50b0cfe280c1 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -1275,6 +1275,7 @@ static int csid_link_setup(struct media_entity *entity,
 		csid->phy.csiphy_id = csiphy->id;
 
 		lane_cfg = &csiphy->cfg.csi2->lane_cfg;
+		csid->phy.cphy = (lane_cfg->phy_cfg == V4L2_MBUS_CSI2_CPHY);
 		csid->phy.lane_cnt = lane_cfg->num_data;
 		csid->phy.lane_assign = csid_get_lane_assign(lane_cfg);
 	}
diff --git a/drivers/media/platform/qcom/camss/camss-csid.h b/drivers/media/platform/qcom/camss/camss-csid.h
index aedc96ed84b2f..a82db31bd2335 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.h
+++ b/drivers/media/platform/qcom/camss/camss-csid.h
@@ -70,6 +70,7 @@ struct csid_phy_config {
 	u32 lane_assign;
 	u32 en_vc;
 	u8 need_vc_update;
+	bool cphy;
 };
 
 struct csid_device;

-- 
2.51.0

