From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 22 Apr 2026 16:54:44 +0530
Subject: [PATCH 03/12] power: sequencing: qcom-wcn: Add support for
 'is_fixed()' callback to 'bluetooth' target
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-pwrseq-m2-bt-v1-3-720d02545a64@oss.qualcomm.com>
References: <20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com>
In-Reply-To: <20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Shuai Zhang <quic_shuaz@quicinc.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1665;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=OSA0rk78WdDSmkcO/t8XlaqhuYDC5RIPI2ByJSjXDI8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp6LAVY4ZUMxgx8tEOqbhjBW009KzxqC7sLg0vT
 YkPI3/4rnmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaeiwFQAKCRBVnxHm/pHO
 9XLTCACmBOZ/6vCM4GiNJ4EAGBbpjMZp+nMbfjxiLoBS84VUGeB8Hj8Xoy1cIX1iWY4oEe2c2/D
 YkmNGMDuV4gDCUu4QClzMHbBZeBfAkOLRttaC2X+uY24y0qyyiBqW7zuZD+KyCY+/dtNooVG/8V
 t/nqfqoVvJAW1FXZ6yXL0G6rxs3RCZZv61pGlJf4jr7OOoc4RvTMTLXfiBqSaKvXFiuKNN60/bJ
 2/ERYv1EOw0+oo3S8KroevAAVwhTmM6JePXZpuqJZEizu+GBsRnA3CZOLAwoKl3x6MFjSTxv6nT
 NcYo1MoZvG8k7207e3Byz4wsXLkXTgGq68ShZY0sUYUDpVSb
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for 'is_fixed()' callback to indicate the consumers whether
this power sequencer target 'bluetooth' is fixed or controllable. This is
decided based on the availability of the 'bt-enable' GPIO in DT.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/pwrseq-qcom-wcn.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/power/sequencing/pwrseq-qcom-wcn.c b/drivers/power/sequencing/pwrseq-qcom-wcn.c
index b55b4317e21b..50ac5973b8e7 100644
--- a/drivers/power/sequencing/pwrseq-qcom-wcn.c
+++ b/drivers/power/sequencing/pwrseq-qcom-wcn.c
@@ -254,10 +254,18 @@ static int pwrseq_qcom_wcn6855_xo_clk_deassert(struct pwrseq_device *pwrseq)
 	return pwrseq_qcom_wcn_pwup_delay(pwrseq);
 }
 
+static bool pwrseq_qcom_wcn_bt_is_fixed(struct pwrseq_device *pwrseq)
+{
+	struct pwrseq_qcom_wcn_ctx *ctx = pwrseq_device_get_drvdata(pwrseq);
+
+	return !ctx->bt_gpio;
+}
+
 static const struct pwrseq_target_data pwrseq_qcom_wcn_bt_target_data = {
 	.name = "bluetooth",
 	.unit = &pwrseq_qcom_wcn_bt_unit_data,
 	.post_enable = pwrseq_qcom_wcn_pwup_delay,
+	.is_fixed = pwrseq_qcom_wcn_bt_is_fixed,
 };
 
 static const struct pwrseq_target_data pwrseq_qcom_wcn_wlan_target_data = {
@@ -281,6 +289,7 @@ static const struct pwrseq_target_data pwrseq_qcom_wcn6855_bt_target_data = {
 	.name = "bluetooth",
 	.unit = &pwrseq_qcom_wcn6855_bt_unit_data,
 	.post_enable = pwrseq_qcom_wcn6855_xo_clk_deassert,
+	.is_fixed = pwrseq_qcom_wcn_bt_is_fixed,
 };
 
 static const struct pwrseq_target_data pwrseq_qcom_wcn6855_wlan_target_data = {

-- 
2.51.0

