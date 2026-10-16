From: Ishu Brar <patches@brar.si>
Date: Fri, 16 Oct 2026 13:50:19 +0530
Subject: [PATCH 2/2] remoteproc: qcom: pas: Add SM7250 ADSP support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-adsp-sm7250-v1-2-2f39ac1f0496@brar.si>
References: <20261016-adsp-sm7250-v1-0-2f39ac1f0496@brar.si>
In-Reply-To: <20261016-adsp-sm7250-v1-0-2f39ac1f0496@brar.si>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792138822; l=1106;
 i=patches@brar.si; h=from:subject:message-id;
 bh=B1Al454eYa4DdVDM6yrNOKl/Z5koP7bFA2fThKPNA7w=;
 b=1glpKh262yOUc6Fg21QDz/o6bf8qkbuu8b+s+2CW9PXTcKfi1qipd76+2oeC+SXxJ94TOfM27
 9g71SQFNknyC7kRUGgdoFT1Cs0TUpVjkMTWo2xeL9We6l4nf79Pvmgf
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM7250 ADSP uses the same PAS ID, crash reason SMEM item, SSR/sysmon
names and proxy power domains as the SM6350 one, so reuse its resource.

Signed-off-by: Ishu Brar <patches@brar.si>
---
 drivers/remoteproc/qcom_q6v5_pas.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/remoteproc/qcom_q6v5_pas.c b/drivers/remoteproc/qcom_q6v5_pas.c
index 2e1e39826..365f4fa5b 100644
--- a/drivers/remoteproc/qcom_q6v5_pas.c
+++ b/drivers/remoteproc/qcom_q6v5_pas.c
@@ -2046,6 +2046,7 @@ static const struct of_device_id qcom_pas_of_match[] = {
 	{ .compatible = "qcom,sm6375-adsp-pas", .data = &sm6350_adsp_resource },
 	{ .compatible = "qcom,sm6375-cdsp-pas", .data = &sm8150_cdsp_resource },
 	{ .compatible = "qcom,sm6375-mpss-pas", .data = &sm6375_mpss_resource },
+	{ .compatible = "qcom,sm7250-adsp-pas", .data = &sm6350_adsp_resource },
 	{ .compatible = "qcom,sm8150-adsp-pas", .data = &sm8150_adsp_resource },
 	{ .compatible = "qcom,sm8150-cdsp-pas", .data = &sm8150_cdsp_resource },
 	{ .compatible = "qcom,sm8150-mpss-pas", .data = &mpss_resource_init },

-- 
2.56.0

