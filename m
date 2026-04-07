From: David Heidelberg <david@ixit.cz>
Date: Tue, 07 Apr 2026 08:43:55 +0200
Subject: [PATCH v5 2/3] ath10k: Add device-tree quirk to skip host cap QMI
 requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260407-skip-host-cam-qmi-req-v5-2-dfa8a05c6538@ixit.cz>
References: <20260407-skip-host-cam-qmi-req-v5-0-dfa8a05c6538@ixit.cz>
In-Reply-To: <20260407-skip-host-cam-qmi-req-v5-0-dfa8a05c6538@ixit.cz>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Vasanthakumar Thiagarajan <vasanthakumar.thiagarajan@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Amit Pundir <amit.pundir@linaro.org>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3626; i=david@ixit.cz;
 h=from:subject:message-id; bh=duxRMTRGnz0BVuY8CUPzChCzTzgdtO7LKOK19WE1+G0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1Keu88ybLs7hox4Z8WZ8o/SOGrjIyc50jOeLX
 QOeUbddEHaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadSnrgAKCRBgAj/E00kg
 csgHEACboOgcD/LfRDDFDXsLlNM8GQpmFctiiv8IiSa6B7WuuCZJPAlP3WC0R2Ey4yNoNjHQCr0
 ZyvWsz6GOjzVbxcOf5+/c4qMuiSvnJ7ulQ1Kk4gGgG9+W5blpLLajSw97dXGLS/wSCUXeIvDGp2
 BPLTJjNlkgfd7gnD/Dt4VEgOFxpMv9xE27OxvYSyGb6ipvdxJtkebQ+4ty46eutqLo2+9m00NwN
 0AH9Ftd/rDohmPpYJbm+oTsLY2PmhLf5iNDk8l9sQChoPfJMl3Exf53kqW8YqB9dp0Tms2JRCoG
 NXQyh7XsX8uQpLNg2f3vB/eCgAObfDWABwjtSq+PxXjWDOUprrOVcsPdfrcLxVdzFoSWPk8o+nm
 ao6WLbn4AQ9hjbYwJ6nelY4kPUDs6tS1eZHtGjes/kCHXf7vP4FxbcbCmgDmpHOKGJBJE3U/kyD
 ZRJegTIBgZiSVp9Viq8iGgd0/DypawqzUWfoalT1VVxZQoEezg0LUw09Xk7puDEqce8p/25O2vB
 +vglqLByzcXiWIX5FM0cW3TZOe14Wr7AYmg6g3deIOtKjXatGDIG9VxvEXTKp1s9aN7pAjtaTIB
 Zcixl/7/AJULaUwRoSzAv5PhFxu+QOxALaXb6mWYGlSsvamwVXBqkOEoHcCWijHOyIpIZKyxPvw
 lS+1BqIPk5NW51Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

Some firmware versions do not support the host capability QMI request.
Since this request occurs before firmware-N.bin and board-M.bin are
loaded, the quirk cannot be expressed in the firmware itself.

The root cause is unclear, but there appears to be a generation of
firmware that lacks host capability support.

Without this quirk, ath10k_qmi_host_cap_send_sync() returns
QMI_ERR_MALFORMED_MSG_V01 before loading the firmware. This error is not
fatal - Wi-Fi services still come up successfully if the request is simply
skipped.

Add a device-tree quirk to skip the host capability QMI request on devices
whose firmware does not support it.

For example, firmware build
"QC_IMAGE_VERSION_STRING=WLAN.HL.2.0.c3-00257-QCAHLSWMTPLZ-1"
on Xiaomi Poco F1 phone requires this quirk.

Suggested-by: Bjorn Andersson <andersson@kernel.org>
Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
Tested-by: Paul Sajna <sajattack@postmarketos.org>
Reviewed-by: Baochen Qiang <baochen.qiang@oss.qualcomm.com>
Reviewed-by: Vasanthakumar Thiagarajan <vasanthakumar.thiagarajan@oss.qualcomm.com>
Acked-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/net/wireless/ath/ath10k/qmi.c  | 13 ++++++++++---
 drivers/net/wireless/ath/ath10k/snoc.c |  3 +++
 drivers/net/wireless/ath/ath10k/snoc.h |  1 +
 3 files changed, 14 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/qmi.c b/drivers/net/wireless/ath/ath10k/qmi.c
index eebd78e7ff6bc..e7f90fd9e9b83 100644
--- a/drivers/net/wireless/ath/ath10k/qmi.c
+++ b/drivers/net/wireless/ath/ath10k/qmi.c
@@ -808,6 +808,7 @@ ath10k_qmi_ind_register_send_sync_msg(struct ath10k_qmi *qmi)
 static void ath10k_qmi_event_server_arrive(struct ath10k_qmi *qmi)
 {
 	struct ath10k *ar = qmi->ar;
+	struct ath10k_snoc *ar_snoc = ath10k_snoc_priv(ar);
 	int ret;
 
 	ret = ath10k_qmi_ind_register_send_sync_msg(qmi);
@@ -819,9 +820,15 @@ static void ath10k_qmi_event_server_arrive(struct ath10k_qmi *qmi)
 		return;
 	}
 
-	ret = ath10k_qmi_host_cap_send_sync(qmi);
-	if (ret)
-		return;
+	/*
+	 * Skip the host capability request for the firmware versions which
+	 * do not support this feature.
+	 */
+	if (!test_bit(ATH10K_SNOC_FLAG_SKIP_HOST_CAP_QUIRK, &ar_snoc->flags)) {
+		ret = ath10k_qmi_host_cap_send_sync(qmi);
+		if (ret)
+			return;
+	}
 
 	ret = ath10k_qmi_msa_mem_info_send_sync_msg(qmi);
 	if (ret)
diff --git a/drivers/net/wireless/ath/ath10k/snoc.c b/drivers/net/wireless/ath/ath10k/snoc.c
index f72f236fb9eb3..3106502275781 100644
--- a/drivers/net/wireless/ath/ath10k/snoc.c
+++ b/drivers/net/wireless/ath/ath10k/snoc.c
@@ -1362,6 +1362,9 @@ static void ath10k_snoc_quirks_init(struct ath10k *ar)
 
 	if (of_property_read_bool(dev->of_node, "qcom,snoc-host-cap-8bit-quirk"))
 		set_bit(ATH10K_SNOC_FLAG_8BIT_HOST_CAP_QUIRK, &ar_snoc->flags);
+
+	if (of_property_read_bool(dev->of_node, "qcom,snoc-host-cap-skip-quirk"))
+		set_bit(ATH10K_SNOC_FLAG_SKIP_HOST_CAP_QUIRK, &ar_snoc->flags);
 }
 
 int ath10k_snoc_fw_indication(struct ath10k *ar, u64 type)
diff --git a/drivers/net/wireless/ath/ath10k/snoc.h b/drivers/net/wireless/ath/ath10k/snoc.h
index 1ecae34687c21..46574fd8f84ee 100644
--- a/drivers/net/wireless/ath/ath10k/snoc.h
+++ b/drivers/net/wireless/ath/ath10k/snoc.h
@@ -51,6 +51,7 @@ enum ath10k_snoc_flags {
 	ATH10K_SNOC_FLAG_MODEM_STOPPED,
 	ATH10K_SNOC_FLAG_RECOVERY,
 	ATH10K_SNOC_FLAG_8BIT_HOST_CAP_QUIRK,
+	ATH10K_SNOC_FLAG_SKIP_HOST_CAP_QUIRK,
 };
 
 struct clk_bulk_data;

-- 
2.53.0

