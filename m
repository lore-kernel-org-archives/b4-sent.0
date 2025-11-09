From: David Heidelberg <david@ixit.cz>
Date: Sun, 09 Nov 2025 10:39:47 +0100
Subject: [PATCH RFC 4/8] media: qcom: camss: Prepare CSID for C-PHY support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251109-qcom-cphy-v1-4-165f7e79b0e1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2110; i=david@ixit.cz;
 h=from:subject:message-id; bh=67QPHtM7I6s6uFEWjy+7P8alMIyko6ww9PvBrgKxm7s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEGFyHQdwgNa69TcTXUJ7+0HiDqgW6zw++IncQ
 ewgH+t9VWyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRBhcgAKCRBgAj/E00kg
 crY+D/wPfC3CCHkyHKDhzQhl7Ydcyh+dDiR/RwwUrrK0RZ+CRoKnn9BELlgYOzt46nfs1R8+L4M
 DjMFrGT2vp+ILDsRLLD6sgYSbcRVZG1wy9y9JUMB1HSrXlciljZtGNGjiH4pxl/uYlmE1aNXo45
 M2uRIpjfVQOZvoJ0tOepwPjUKSqom26ixbQTA5PUHIiRBxCnxuZ2940pqLXT/mmqixOvXsEmWod
 ViKqD+jWLN70a+tmj3fXzTKd5rlcx8VS0C7oxtkmiebSPxMm2Gs2uM+B/IlSzDqlNSmoxnSXJfN
 89GFDCPWeVQGwBSWDEiAn0sx8V5KjXyQ8+RS87p13g5JiPsuVOSlyRV0hGuZG2TFmgh+H1SVrA9
 y3Pydza5wHAoWc1rf2uZGABJFDBulo/1VvstJiss80yJ5BLDJLCWVh5WgQl3QuWO3YVvbki7IG7
 x3H3VbGUrlS8SghJ8SjBZbgvueGPZMFfiSOEIc0yQU2zqRhmMbapjejhIFj/p+c6HvVEBl95NdW
 wZB0gC3EZEWJSe5d6dShv5NrfNGAZMSIghD/2QglRREKKrE+7DxIWDDvuQPJIKIiD5/MG7sTXF1
 wUCF6Q2pG6fQwHV3uI19j11nuLlTXnjwN23uZAWaJQxFMTlT8LktsO1r6VsTOohRK7JYXmiUqKx
 mpbEAcz/YnFcyIw==
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
index 5284b5857368c..68adea33cc719 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -1287,6 +1287,7 @@ static int csid_link_setup(struct media_entity *entity,
 		csid->phy.csiphy_id = csiphy->id;
 
 		lane_cfg = &csiphy->cfg.csi2->lane_cfg;
+		csid->phy.cphy = lane_cfg->cphy;
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

