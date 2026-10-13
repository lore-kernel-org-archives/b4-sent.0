From: Juerg Haefliger <juerg.haefliger@canonical.com>
Date: Tue, 13 Oct 2026 16:40:58 +0200
Subject: [PATCH 3/3] firmware: qcom: scm: Allow QSEECOM for HP EliteBook 6
 G1q
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-add-elitebook-6-dts-v1-3-f22e67fc7f9d@canonical.com>
References: <20261013-add-elitebook-6-dts-v1-0-f22e67fc7f9d@canonical.com>
In-Reply-To: <20261013-add-elitebook-6-dts-v1-0-f22e67fc7f9d@canonical.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=881;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=KYbEVq00guskfIjy0MSjHHL2QSUlUedgJpB8ExE0VPs=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBqzkMKYh6PXrlTRmQda7nhBHwbiNm0NELmVwkPx
 g+TLwPQ6HGJAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCas5DCgAKCRAP04sJC6ZC
 tw9MD/wOPWrwtaXGmBEAp8LlDKGpT943O94e/jSUYCK0StG015uJUd57f+yc1xRgYPQXlsz8fCM
 ebLI7LYRDRhO2iIzKUSabZlVyhX7Gr4voFEDrjdWHOU9ekm6khsTeQ52tm7D9YWzggfbz1gqHhm
 8gLZ1kfRK8liwFXqoI7Om0pqTCwCN3kvKPbRgdp2vFGDlIF+iD1BQxqr6DOurA4wXDaex+VqZI9
 fc70BOXiD2rjcXqUpcNpzBbG0b4LN5OJ48gZqy85E+7HrSslxuUNseE+dw41hqFbha1Rx36gsIR
 u957GAKbpGMwBHDjCM+lbr1LhYw/X0FT/KF5ljSFtqxFqdZG7jLGWtNfB7RrKf+kpTJ2w3gIF0f
 LsfEPHyof52AX5T0uq8eVlfvSdlktzaa4GtJRQuteAp9Zqa4Ie4vY4y+4GJLI4zkk3QfnlomyMy
 IwLSIPs35uP3JiwpxVKnsE/gh+hLUH/eGaQ/nXsdIUZtIUEk9/oVaRsn5eZ3mubSgX+9ZaDupCw
 ou34Oh+HNNPFfBBN9P9jDpqBhp7fZ71EqdXRt1UarTECFHmP95NNHRFyhdmDA+P9eWPpQFbWWCC
 l5kWtmkkwiVWHg6VxO8dH7omH8ozRLz/6s7I0vKK9kwa+At13vpOD54YUGbKwQex/HjSvQC0l3u
 eY0sg4Fdr7jaSPg==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add HP EliteBook 6 G1q to the QSEECOM allowlist for enabling access to
efivars and uefi bootloader.

Signed-off-by: Juerg Haefliger <juerg.haefliger@canonical.com>
---
 drivers/firmware/qcom/qcom_scm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 43e250faea75..da809c707510 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -2236,6 +2236,7 @@ static const struct of_device_id qcom_scm_qseecom_allowlist[] __maybe_unused = {
 	{ .compatible = "dell,xps13-9345" },
 	{ .compatible = "ecs,liva-qc710" },
 	{ .compatible = "honor,magicbook-art-14-snapdragon" },
+	{ .compatible = "hp,elitebook-6-g1q" },
 	{ .compatible = "hp,elitebook-ultra-g1q" },
 	{ .compatible = "hp,elitebook-x-g2q" },
 	{ .compatible = "hp,omnibook-x14" },

-- 
2.53.0

