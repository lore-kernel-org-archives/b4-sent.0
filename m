From: David Heidelberg <david@ixit.cz>
Date: Tue, 11 Nov 2025 13:34:22 +0100
Subject: [PATCH 1/2] ath10k: Introduce a firmware quirk to skip host cap
 QMI requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251111-xiaomi-beryllium-firmware-v1-1-836b9c51ad86@ixit.cz>
References: <20251111-xiaomi-beryllium-firmware-v1-0-836b9c51ad86@ixit.cz>
In-Reply-To: <20251111-xiaomi-beryllium-firmware-v1-0-836b9c51ad86@ixit.cz>
To: Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Selvaraj <foss@joelselvaraj.com>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3152; i=david@ixit.cz;
 h=from:subject:message-id; bh=5FMo9aFaXqxUB4HypgN53V7+QK1qunFr3c9JmlKcclY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEy1OcjSNQgfs3SkjYQdqB3Ac1e1i9BymzVK5p
 q4Vd41ioPWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRMtTgAKCRBgAj/E00kg
 cuyWEAC9D0030HM8wP/qOsIJRe/Pu8yq1QRUwOLD8sGwTzLPMwrqnQvJxZAZYY4KDsblKksdaqB
 E6isr1E4Rwhw5/0C/CLclqBDTR5rESUqxnXB2wgAnRtIS6Gcf4V+Eoo5tNWo9NXoxES+dcfEfm8
 iIHczTJEU1p+gAeI4FBS548n3rA52l99eq15iCO7gMwGZaPWsJimQm3wrtQujkBQc+WKwCb/GgX
 +nOIXwd6X13j1/zyk8BVIud1PTTvzpWIjmpEPiQDig0/KJIfU1RecnWuMXmW3C+Y/peFjpJmnXb
 lv1/40F5WjdPWiViIpu4ilAO2FIdjcrkJzIRReREHA/9yHb8I+p4FDwIO5qGEe7Q1eSYp6jmqAb
 cbG6mvK8RmkwE71vUk8CHTnRTmLyJd/CWmLXHUTEfxWljiy1sW8emsS8QhVpuizCrSMeplh1aqA
 QMvB51XPKAIaiabfWZnS5LcAeGgd0o77VBCI6R+PK9ijJOpwH8hguuOh6Dev9VT4DQh1fRu7qsr
 vYTvxKNFVTRtICrzq5G8AtjGIy0aaBhjsNUvQBLukVtQoQKl2DEiw/lTz38Ghxo03IEc9kxLI3k
 zhUodl6gKCl6O9hByLElR7Qjxx4cbAxFpuqxtPSIp7jXvKpb+TCpZxOEWc82FMTaT8CgWttDnwV
 R1n70DsqzVPrzBA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are firmware versions which do not support host capability
QMI request. We suspect either the host cap is not implemented or
there may be firmware specific issues, but apparently there seem
to be a generation of firmware that has this particular behavior.

For example, firmware build on Xiaomi Poco F1 (sdm845) phone:
"QC_IMAGE_VERSION_STRING=WLAN.HL.2.0.c3-00257-QCAHLSWMTPLZ-1"

If we do not skip the host cap QMI request on Xiaomi Poco F1,
then we get a QMI_ERR_MALFORMED_MSG_V01 error message in the
ath10k_qmi_host_cap_send_sync(). But this error message is not
fatal to the firmware nor to the ath10k driver and we can still
bring up the WiFi services successfully if we just ignore it.

Hence introducing this firmware quirk to skip host capability
QMI request for the firmware versions which do not support this
feature.

Suggested-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/net/wireless/ath/ath10k/core.c |  1 +
 drivers/net/wireless/ath/ath10k/core.h |  3 +++
 drivers/net/wireless/ath/ath10k/qmi.c  | 13 ++++++++++---
 3 files changed, 14 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/core.c b/drivers/net/wireless/ath/ath10k/core.c
index 7c2939cbde5f0..7602631696798 100644
--- a/drivers/net/wireless/ath/ath10k/core.c
+++ b/drivers/net/wireless/ath/ath10k/core.c
@@ -773,6 +773,7 @@ static const char *const ath10k_core_fw_feature_str[] = {
 	[ATH10K_FW_FEATURE_SINGLE_CHAN_INFO_PER_CHANNEL] = "single-chan-info-per-channel",
 	[ATH10K_FW_FEATURE_PEER_FIXED_RATE] = "peer-fixed-rate",
 	[ATH10K_FW_FEATURE_IRAM_RECOVERY] = "iram-recovery",
+	[ATH10K_FW_FEATURE_NO_HOST_CAP_QMI_REQ] = "no-host-cap-qmi-req",
 };
 
 static unsigned int ath10k_core_get_fw_feature_str(char *buf,
diff --git a/drivers/net/wireless/ath/ath10k/core.h b/drivers/net/wireless/ath/ath10k/core.h
index 73a9db302245d..b20541e4046f8 100644
--- a/drivers/net/wireless/ath/ath10k/core.h
+++ b/drivers/net/wireless/ath/ath10k/core.h
@@ -838,6 +838,9 @@ enum ath10k_fw_features {
 	/* Firmware support IRAM recovery */
 	ATH10K_FW_FEATURE_IRAM_RECOVERY = 22,
 
+	/* Firmware does not support host capability QMI request */
+	ATH10K_FW_FEATURE_NO_HOST_CAP_QMI_REQ = 23,
+
 	/* keep last */
 	ATH10K_FW_FEATURE_COUNT,
 };
diff --git a/drivers/net/wireless/ath/ath10k/qmi.c b/drivers/net/wireless/ath/ath10k/qmi.c
index 8275345631a0b..5dc8ea39372c1 100644
--- a/drivers/net/wireless/ath/ath10k/qmi.c
+++ b/drivers/net/wireless/ath/ath10k/qmi.c
@@ -819,9 +819,16 @@ static void ath10k_qmi_event_server_arrive(struct ath10k_qmi *qmi)
 		return;
 	}
 
-	ret = ath10k_qmi_host_cap_send_sync(qmi);
-	if (ret)
-		return;
+	/*
+	 * Skip the host capability request for the firmware versions which
+	 * do not support this feature.
+	 */
+	if (!test_bit(ATH10K_FW_FEATURE_NO_HOST_CAP_QMI_REQ,
+		      ar->running_fw->fw_file.fw_features)) {
+		ret = ath10k_qmi_host_cap_send_sync(qmi);
+		if (ret)
+			return;
+	}
 
 	ret = ath10k_qmi_msa_mem_info_send_sync_msg(qmi);
 	if (ret)

-- 
2.51.0

