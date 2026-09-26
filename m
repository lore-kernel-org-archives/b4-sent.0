From: David Heidelberg <david@ixit.cz>
Date: Sat, 26 Sep 2026 14:40:24 +0200
Subject: [PATCH RFC 05/12] usb: typec: qcom: Make typec_port accept also
 different structure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-typec-v1-5-31adc19f32c6@ixit.cz>
References: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
In-Reply-To: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Lee Jones <lee@kernel.org>, Stephen Boyd <sboyd@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, mfd@lists.linux.dev, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1220; i=david@ixit.cz;
 h=from:subject:message-id; bh=Rv/C1XQqReAptmVTI+ZJAAlK7aFi13337WHcMdGcM48=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqt70+EPEh7Pr+laDPW4tWdnCaH47gu2yL7r0Gt
 l2/AzxTDnCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCare9PgAKCRBgAj/E00kg
 cr+8EACMj0EdXOb53DNNjlp+WWKFSp/7RfbfxhXER7ZgaAxztTLpMF8MUe49qSwIIE7evRvh3U2
 3dtguNMZCawah/9kZLL89nEsaR0piJKrZLC1m6td+zSz0diVBwm22ixLjImzV1w1vkMJdicxH8A
 8QzSC/SsegXq/dZZYXdBEv1N5wKE8WTUT59/4W+JDaYBu7eoB0oG+EcVhfNOrDF7kJxMfpUOZML
 oC8k3IuDvpdPuQ+zY1T+lcOsN8SlkU3HZjzjNY54VeoMz/DCZ0YUhIKnSeOspXgVPMsq82nvJAt
 hpOZosAoeYj4q0R9S9FTqycfx3ZNYdMnJBRaN6+tGK24U7p+8JD67ke/SPgQg3atm/Xnp8cFP70
 m1lKB8rdLu3OHSXEu8qUpi+xuvtFSCFJCWjC85N5cIWTC69oVWqPrb/hcEMkLuWlDYBGAQCIdly
 BtmDFEMkDbc8jcJbOtUnR5RUHWKC1Wv6ffjFCPbwn0Pr0XrL9JhS1U+11XnpgUs15KIpYW2YCqb
 LFMkID4eBa2HMb/cq25zJYFOaXYy12MnmuZcpO+dzIyIS6k9cvX5V80kiNJ7nHQMurJe9MYpgA9
 YWvMbtcY4i74m0sl7u7obrR6Cr1ib1JGhwgcoTcmsZGiQrz4SYGkm/lot/jrcr+3eJfBakNftN5
 MO9GKRI02vmmyFA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is needed by followup commit introducing 1st gen of type-c support.

Assisted-by: LLM
Co-developed-by: Alexey Minnekhanov <alexeymin@minlexx.ru>
Signed-off-by: Alexey Minnekhanov <alexeymin@minlexx.ru>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.h b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.h
index 3c75820c91876..6f89d296ad151 100644
--- a/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.h
+++ b/drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.h
@@ -6,17 +6,17 @@
 #ifndef __QCOM_PMIC_TYPEC_H__
 #define __QCOM_PMIC_TYPEC_H__
 
 struct pmic_typec {
 	struct device		*dev;
 	struct tcpm_port	*tcpm_port;
 	struct tcpc_dev		tcpc;
 	struct pmic_typec_pdphy	*pmic_typec_pdphy;
-	struct pmic_typec_port	*pmic_typec_port;
+	void			*pmic_typec_port;
 
 	int (*pdphy_start)(struct pmic_typec *tcpm,
 			   struct tcpm_port *tcpm_port);
 	void (*pdphy_stop)(struct pmic_typec *tcpm);
 
 	int (*port_start)(struct pmic_typec *tcpm,
 			  struct tcpm_port *tcpm_port);
 	void (*port_stop)(struct pmic_typec *tcpm);

-- 
2.55.0

