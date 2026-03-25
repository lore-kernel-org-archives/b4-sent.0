From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Mar 2026 17:41:13 +0100
Subject: [PATCH v3 2/3] ath10k: Introduce a device-tree quirk to skip host
 cap QMI requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-skip-host-cam-qmi-req-v3-2-b163cf7b3c81@ixit.cz>
References: <20260325-skip-host-cam-qmi-req-v3-0-b163cf7b3c81@ixit.cz>
In-Reply-To: <20260325-skip-host-cam-qmi-req-v3-0-b163cf7b3c81@ixit.cz>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Amit Pundir <amit.pundir@linaro.org>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3403; i=david@ixit.cz;
 h=from:subject:message-id; bh=zduhmi7M53CiNDhpnd/UxVSeff3VorLQBqTI4Nh5rZY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpxBAsricF0IftT2NeNw1Yuu7Qi7iezsb/5SpV/
 BgONR0OiXCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacQQLAAKCRBgAj/E00kg
 cmnbEACckc0Tpfu2hVTQN1sZFx/yaaL1GbxZ0hXnHFkdzxQwJDVW/lgSjuYfyJCQcnwU5Nnz+Lp
 P2sZEY6bYTvg6uYOS2eM99d5yQl9QnB9OaglGU9C90ZCKmVVJT4m4WvvAZ2bQHXu3gWN9p0zHVw
 ckMJ7hXK7xLdSFJTprmWRYNLHvkAzrnO6k/6s7YIfM/hXXMY9h/hyZqtnfBjoJxoGqOvHXCcg4X
 5x9VFKB2M4CMSh7Q3wSS9CKHLZAjhivIqFw7jFowjK4fAqstlBnvFSLGSaO167TMNXA0GpyERNJ
 f093MYWb2tIY5UG34SKx9Rl1GknDQY7Dty5r+jDjG5IzngGI0b1iIbfNPwiENz4JVeL7aolulFc
 G0lxz0I64iMo6DF9gAaq1Bm8bMPNIDi2AeHrSJQsz6wfwfXWm+w9yGtPGYb4gxGmFo5OtKqexFU
 NDkwMCnPanGLixrBjWJAcPEyPl4taWzt7cUCt6NzF3uehQcWWy1phZoIqPugWOqoS4xxSAsM+tD
 /tCPCNAFnRhaX3JqwACAkl2Sdb6ittGtXJ6dqR/Zj2NIJL7grm4HWugFtHXV7qGXJOJkWz/DSRU
 2x6eVLKfG9e0Jnxa7XcLFS5Wyrdw8wNIRWf31xuhwFk1ScctO7YhYGg7+l7X5WHsRrGU4SDwhLJ
 4WALCKtnZkdDq8g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

There are firmware versions which do not support host capability QMI
request. We suspect either the host cap is not implemented or there may
be firmware specific issues, but apparently there seem to be a generation
of firmware that has this particular behavior.

For example, firmware build on Xiaomi Poco F1 (sdm845) phone:
"QC_IMAGE_VERSION_STRING=WLAN.HL.2.0.c3-00257-QCAHLSWMTPLZ-1"

If we do not skip the host cap QMI request on Poco F1, then we get a
QMI_ERR_MALFORMED_MSG_V01 error message before loading the firmware in the
ath10k_qmi_host_cap_send_sync(). This error message is not fatal to the
firmware nor to the ath10k driver and we can still bring up the WiFi
services successfully if we just ignore it.

Hence introducing this device-tree quirk to skip host capability
QMI request for the devices with firmware versions which do not support
this feature.

Suggested-by: Bjorn Andersson <andersson@kernel.org>
Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
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

