From: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
Date: Tue, 14 Oct 2025 14:57:10 +0530
Subject: [PATCH v2] soc: qcom: pd-mapper: Add Kaanapali compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251014-knp-pdmapper-v2-v2-1-ba44422ac503@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAG0X7mgC/13MywrCMBCF4Vcps3ZKkkaCrnwPcTFNJzZoLiZah
 NJ3N7hw4ebAtzj/CpWL5wrHboXCi68+xQa168DOFK+MfmoGJdReCqnxFjPmKVDOXHBRaNjI0Zn
 BajbQXrmw8+9v8XxpdiUFfM6F6dcRB/XfkSjRWaf1SDwYQ6dUa/940d2mEPo2sG0f20QgkKwAA
 AA=
X-Change-ID: 20251014-knp-pdmapper-v2-7e71bf73c4e7
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>, 
 Jingyi Wang <jingyi.wang@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760434031; l=1855;
 i=prasad.kumpatla@oss.qualcomm.com; s=20251014; h=from:subject:message-id;
 bh=sCqvfA32ZCOl3TIUlO+J7YRwsshujOttwAP0Dgj/0+A=;
 b=/84Xt5SlsU4+IEZFisXbbIcOZxoiS/C2GvlOxuDvVZ2jn9L/zQ+eub17Jy8qQOSf3uT7eIFop
 95v6Npr3K4NB5QkrDmdmaJqm07H5Y+pBgI8Gwe6QzhOrH8Fw7OwQCDL
X-Developer-Key: i=prasad.kumpatla@oss.qualcomm.com; a=ed25519;
 pk=I3mn8JNlYnnm7frqMGXms1Rm2H+0gpAfknMlnBYqCzw=
X-Endpoint-Received: by B4 Relay for prasad.kumpatla@oss.qualcomm.com/20251014 with auth_id=541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Qualcomm Kaanapali SoC to the protection
domain mapper. Kaanapali shares the same protection domain
configuration as SM8550, except charger_pd as it move to SoCCP.

Signed-off-by: Jingyi Wang <jingyi.wang@oss.qualcomm.com>
Signed-off-by: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
---
Changes in v2:
- Add separate pd domain data for Kaanapali SoC.
- Link to v1: https://lore.kernel.org/r/20250924-knp-pdmapper-v1-1-fcf44bae377a@oss.qualcomm.com
---

---
 drivers/soc/qcom/qcom_pd_mapper.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/soc/qcom/qcom_pd_mapper.c b/drivers/soc/qcom/qcom_pd_mapper.c
index 6384f271953d..1bcbe69688d2 100644
--- a/drivers/soc/qcom/qcom_pd_mapper.c
+++ b/drivers/soc/qcom/qcom_pd_mapper.c
@@ -360,6 +360,15 @@ static const struct qcom_pdm_domain_data mpss_wlan_pd = {
 	},
 };
 
+static const struct qcom_pdm_domain_data *kaanapali_domains[] = {
+	&adsp_audio_pd,
+	&adsp_root_pd,
+	&adsp_sensor_pd,
+	&cdsp_root_pd,
+	&mpss_root_pd_gps,
+	NULL,
+};
+
 static const struct qcom_pdm_domain_data *msm8996_domains[] = {
 	&msm8996_adsp_audio_pd,
 	&msm8996_adsp_root_pd,
@@ -552,6 +561,7 @@ static const struct of_device_id qcom_pdm_domains[] __maybe_unused = {
 	{ .compatible = "qcom,apq8074", .data = NULL, },
 	{ .compatible = "qcom,apq8084", .data = NULL, },
 	{ .compatible = "qcom,apq8096", .data = msm8996_domains, },
+	{ .compatible = "qcom,kaanapali", .data = kaanapali_domains, },
 	{ .compatible = "qcom,msm8226", .data = NULL, },
 	{ .compatible = "qcom,msm8909", .data = NULL, },
 	{ .compatible = "qcom,msm8916", .data = NULL, },

---
base-commit: 2b763d4652393c90eaa771a5164502ec9dd965ae
change-id: 20251014-knp-pdmapper-v2-7e71bf73c4e7

Best regards,
-- 
Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>

