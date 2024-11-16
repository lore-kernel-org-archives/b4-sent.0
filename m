From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 16 Nov 2024 14:44:39 +0100
Subject: [PATCH] firmware: qcom: scm: Allow QSEECOM on the asus vivobook
 s15
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241116-add_asus_qcom_scm-v1-1-5aa2b0fb52bd@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAMahOGcC/x3MSwqAMAwA0atI1hZM1QpeRaTUNmoW/hoUQby7x
 eVbzDwgFJkE2uyBSBcLb2sC5hn42a0TKQ7JoAtdIaJRLgTr5BR7+G2x4heFZWO8HmpjkCB1e6S
 R7//Z9e/7AcLp1DFjAAAA
X-Change-ID: 20241116-add_asus_qcom_scm-1376c2b5661e
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731764682; l=1061;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=LGt2vVLNhgxRFLVYlxRxtn5kjW0oNXk/G6bF1cNREYc=;
 b=Xi/cjvg8PRVTuBhZbAHv+dX7ue1iv3nEv5wUfqWK5n1IHHZCz2+aEiz5Q3N8FgYO+XMG+dnPO
 tvK5hXdJNeIDgfZs1hqIDn15/4uV0jYifYgQSHP85IPFug76cJcnVNU
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the asus vivobook s15 to the compatible list to allow access to
efivars

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 drivers/firmware/qcom/qcom_scm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 72bf87ddcd969834609cda2aa915b67505e93943..0bdfe64a0ff009c38720692fe60d9f13342181a9 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -1768,6 +1768,7 @@ EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_send);
  + any potential issues with this, only allow validated machines for now.
  */
 static const struct of_device_id qcom_scm_qseecom_allowlist[] __maybe_unused = {
+	{ .compatible = "asus,vivobook-s15" },
 	{ .compatible = "dell,xps13-9345" },
 	{ .compatible = "lenovo,flex-5g" },
 	{ .compatible = "lenovo,thinkpad-t14s" },

---
base-commit: 744cf71b8bdfcdd77aaf58395e068b7457634b2c
change-id: 20241116-add_asus_qcom_scm-1376c2b5661e

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

