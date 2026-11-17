From: David Heidelberg <david@ixit.cz>
Date: Tue, 17 Nov 2026 20:51:18 +0100
Subject: [PATCH] remoteproc: qcom_q6v5_mss: Save the need_pas_mem_setup
 into qproc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-qcom_q6v5_mss_msm8953-v1-1-0fdaea2855ff@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Nz3cLk/Nz4QrMy0/jc4mIgzrWwNDXWTUxKtDA0NTI2MjJOUgLqLSh
 KTcusAJsbHQvhF5cmZaUml4AMU6qtBQAZG3wJeQAAAA==
X-Change-ID: 20261117-qcom_q6v5_mss_msm8953-aba81523223b
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Bryan O'Donoghue <bod@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sashiko <sashiko-bot@kernel.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1721; i=david@ixit.cz;
 h=from:subject:message-id; bh=YXA0PBEQxG7y3KQPuhFsjnj3v8mXJmuKIs88QrqT56o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/LA3t4wTRLmCJRD8Rbmf1F2YC+5aKN1QBaJ6W
 Vf6R+LYyPaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavywNwAKCRBgAj/E00kg
 cjKFEACm4UVdY1Sc6btYgmxzmBtq/95vt8znRQ2e5Uebw9/R6eOFohV3r1xnfyYTQquxU8NDuqm
 f3gAvlhpM4fw7aA2QZ73jD3CfXZR1NOP3aBJ7T17H/KKNnuHVsg/uW4iRxFc1G3MsAOYwpafMRH
 isoj0sY2qMgKKP6QWnQZRVy+aR53VmfXaSKk1HGWazqj19BF6qyXK9hF5WVvk9QkaVgymiqR8w6
 FedoyuHicdvmrM76j23H5hISpGU9OgX1/Sp7cEwXlNDHTRXxE3v6TlL2MnFXJyWu/1BGR1Z0l6T
 Nw2nPPmgheWJFQVABOXMsCugpffHN8A/Ag61BDxvMnkcB0RxUrouf+77BgLUUd3g5Cr59N2llTM
 rB5Fg4LK8t9gDAfCSZ249VeoxihlgBDd0kvElH3x+DCx9hAEWaWsP7cj4cXfrJwqzihoGfHdrR4
 e5kqvkGqiYpJsZghgiRwWAg5pqimQfAsSd8zp+oh2bokXNtRoX9jpUwW41wBrP8uRBgJ1iUg4mk
 5jpqaOWYxzYkKKc9/3Lbjw3vq2NLkXOD8bpnF3KOu76k8NT20mdgrPnQbk1s3fM+HMfzla2jdZQ
 AjptKnUD869OLIZTNvczaQgDj4OynEQB/jgDFAc2bMIW7R1gOcZqEwk9eOI2Q7JehRNABEl4jkL
 jQnvLHzHaSteBmw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On hardware requiring Peripheral Authentication Service (PAS) for modem
memory setup (e.g., SDM632), the remoteproc subsystem skips hardware memory
authentication because q6v5_probe() fails to copy the need_pas_mem_setup
flag to the allocated device instance.

Original commit didn't save the value into the structure thus quietly
skipping if (qproc->need_pas_mem_setup) condition.

Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/bug/linux-83fcbc28-236c-48e4-a6bd-731f4361f9ae
Fixes: f56052f4d87c ("remoteproc: qcom_q6v5_mss: Introduce need_pas_mem_setup")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/remoteproc/qcom_q6v5_mss.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/remoteproc/qcom_q6v5_mss.c b/drivers/remoteproc/qcom_q6v5_mss.c
index dd052a62b8583..5d084aa2eac36 100644
--- a/drivers/remoteproc/qcom_q6v5_mss.c
+++ b/drivers/remoteproc/qcom_q6v5_mss.c
@@ -2189,16 +2189,17 @@ static int q6v5_probe(struct platform_device *pdev)
 
 	qproc->has_alt_reset = desc->has_alt_reset;
 	ret = q6v5_init_reset(qproc);
 	if (ret)
 		goto detach_proxy_pds;
 
 	qproc->version = desc->version;
 	qproc->need_mem_protection = desc->need_mem_protection;
+	qproc->need_pas_mem_setup = desc->need_pas_mem_setup;
 	qproc->has_mba_logs = desc->has_mba_logs;
 
 	ret = qcom_q6v5_init(&qproc->q6v5, pdev, rproc, MPSS_CRASH_REASON_SMEM, "modem",
 			     qcom_msa_handover);
 	if (ret)
 		goto detach_proxy_pds;
 
 	qproc->mpss_perm = BIT(QCOM_SCM_VMID_HLOS);

---
base-commit: aaa2f954c21b205a0bcd0961e5b2be4e82e58455
change-id: 20261117-qcom_q6v5_mss_msm8953-aba81523223b

Best regards,
--  
David Heidelberg <david@ixit.cz>

