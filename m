From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 15 Dec 2025 10:35:09 +0400
Subject: [PATCH v7 4/8] mailbox: qcom: fix IPC register offset for IPQ5424
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251215-ipq5018-wifi-v7-4-ec4adba941b5@outlook.com>
References: <20251215-ipq5018-wifi-v7-0-ec4adba941b5@outlook.com>
In-Reply-To: <20251215-ipq5018-wifi-v7-0-ec4adba941b5@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Manikanta Mylavarapu <quic_mmanikan@quicinc.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-remoteproc@vger.kernel.org, devicetree@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765780526; l=1407;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=bQie0gh5+yB2rgVd9SAgk+hMuExkZX7LZ4wgufEEF9I=;
 b=ejBjz1LnFrBL/mN4ZXwRdohWziR6hrBgFOzVNjlMYOPl3t3qhEz31c6JPnxymw5zM8PgRY6+P
 dvXEaL+YUfHDWVkNsPgJFw+gE37Bea24ptnDnd7MjIVPqKR6KcHwSwU
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IPC register in IPQ5424 is at offset 0xc instead of 0x8 as defined
in driver data for msm8994. As such, switch to the existing
apps_shared_apcs_data driver data which has offset set to 0xc.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/mailbox/qcom-apcs-ipc-mailbox.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/mailbox/qcom-apcs-ipc-mailbox.c b/drivers/mailbox/qcom-apcs-ipc-mailbox.c
index d3a8f6b4a03b368821ef9a5b24fee78037104610..258b03307869b244e053e7a355531268114906df 100644
--- a/drivers/mailbox/qcom-apcs-ipc-mailbox.c
+++ b/drivers/mailbox/qcom-apcs-ipc-mailbox.c
@@ -164,7 +164,7 @@ static const struct of_device_id qcom_apcs_ipc_of_match[] = {
 	{ .compatible = "qcom,sm6125-apcs-hmss-global", .data = &msm8994_apcs_data },
 	{ .compatible = "qcom,sm6115-apcs-hmss-global", .data = &msm8994_apcs_data },
 	{ .compatible = "qcom,ipq5332-apcs-apps-global", .data = &ipq6018_apcs_data },
-	{ .compatible = "qcom,ipq5424-apcs-apps-global", .data = &msm8994_apcs_data },
+	{ .compatible = "qcom,ipq5424-apcs-apps-global", .data = &apps_shared_apcs_data },
 	{ .compatible = "qcom,ipq8074-apcs-apps-global", .data = &ipq6018_apcs_data },
 	{ .compatible = "qcom,sc7180-apss-shared", .data = &apps_shared_apcs_data },
 	{ .compatible = "qcom,sc8180x-apss-shared", .data = &apps_shared_apcs_data },

-- 
2.52.0

