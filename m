From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 23 Sep 2026 16:05:12 +0400
Subject: [PATCH ath-next 06/16] firmware: qcom: scm: Add support for
 setting internal WiFi power mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-6-86729521a75c@outlook.com>
References: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
In-Reply-To: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Vignesh Viswanathan <vignesh.viswanathan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=3732;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=S3tayyPPojcv8MgCJKPIjYb3bobuwrtC6mchI6StDhA=;
 b=yEeCFoFH8MkwAgM7jDcHmtMYntNrocu/jD5KcO5zp83+wJabLj9r+0QEamATBQeJh3sWOsb7U
 Gd89W0Ww3VbAn0Yd3d30H9ILQQwoC4ZLMpo77DHPMN3Ne66bDVp30YL
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SCM call to power up / down the SoC's internal WiFi radio.
The SoC's internal WiFi radio needs to be powered up/down through a SCM
call when MPD firmware is loaded by the rproc driver. Multi-PD firmware
only loads the root PD and provides services and resources to one or
multiple user PDs which are firmware segments required for each WiFi
radio (for ex. in the case of the MPD firmware for IPQ5018 which
contains the firmware binaries for the SoC's internal WiFi radio and one
or two IPQ5018-specific QCN6122 WiFi companion chips).

For non-MPD firmware, this call is not required.

Not all Trusted Execution Environment (QSEE) images support this call,
so first check if the call is available.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/firmware/qcom/qcom_scm.c       | 43 ++++++++++++++++++++++++++++++++++
 drivers/firmware/qcom/qcom_scm.h       |  2 ++
 include/linux/firmware/qcom/qcom_scm.h |  1 +
 3 files changed, 46 insertions(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 3eaa4c9ccf3c..8e5f5c235cb7 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -1084,6 +1084,49 @@ static bool qcom_scm_is_pas_available(void)
 	return true;
 }
 
+/**
+ * qcom_scm_pas_set_wifi_power_mode() - Power on/off internal wifi
+ * @peripheral:	peripheral id
+ * @enable:	true to power up, false to power down
+ *
+ * Return 0 on success.
+ */
+int qcom_scm_pas_set_wifi_power_mode(u32 peripheral, bool enable)
+{
+	struct qcom_scm_desc desc = {
+		.svc = QCOM_SCM_SVC_PIL,
+		.cmd = enable ? QCOM_SCM_PIL_PAS_WIFI_PWR_EN :
+		       QCOM_SCM_PIL_PAS_WIFI_PWR_DIS,
+		.arginfo = QCOM_SCM_ARGS(1),
+		.args[0] = peripheral,
+		.owner = ARM_SMCCC_OWNER_SIP,
+	};
+	struct qcom_scm_res res;
+	int ret;
+
+	if (!__qcom_scm_is_call_available(__scm->dev, QCOM_SCM_SVC_PIL,
+					  enable ? QCOM_SCM_PIL_PAS_WIFI_PWR_EN :
+					  QCOM_SCM_PIL_PAS_WIFI_PWR_DIS))
+		return -EOPNOTSUPP;
+
+	ret = qcom_scm_clk_enable();
+	if (ret)
+		return ret;
+
+	ret = qcom_scm_bw_enable();
+	if (ret)
+		goto disable_clk;
+
+	ret = qcom_scm_call(__scm->dev, &desc, &res);
+	qcom_scm_bw_disable();
+
+disable_clk:
+	qcom_scm_clk_disable();
+
+	return ret ? : res.result[0];
+}
+EXPORT_SYMBOL_GPL(qcom_scm_pas_set_wifi_power_mode);
+
 static int __qcom_scm_pas_mss_reset(struct device *dev, bool reset)
 {
 	struct qcom_scm_desc desc = {
diff --git a/drivers/firmware/qcom/qcom_scm.h b/drivers/firmware/qcom/qcom_scm.h
index cf90a565fdfb..e1554997ca08 100644
--- a/drivers/firmware/qcom/qcom_scm.h
+++ b/drivers/firmware/qcom/qcom_scm.h
@@ -105,6 +105,8 @@ int qcom_scm_shm_bridge_enable(struct device *scm_dev);
 #define QCOM_SCM_PIL_PAS_SHUTDOWN	0x06
 #define QCOM_SCM_PIL_PAS_IS_SUPPORTED	0x07
 #define QCOM_SCM_PIL_PAS_MSS_RESET	0x0a
+#define QCOM_SCM_PIL_PAS_WIFI_PWR_EN	0x17
+#define QCOM_SCM_PIL_PAS_WIFI_PWR_DIS	0x18
 #define QCOM_SCM_PIL_PAS_GET_RSCTABLE	0x21
 
 #define QCOM_SCM_SVC_IO			0x05
diff --git a/include/linux/firmware/qcom/qcom_scm.h b/include/linux/firmware/qcom/qcom_scm.h
index 5747bd191bf1..9258839ae746 100644
--- a/include/linux/firmware/qcom/qcom_scm.h
+++ b/include/linux/firmware/qcom/qcom_scm.h
@@ -93,6 +93,7 @@ struct resource_table *qcom_scm_pas_get_rsc_table(struct qcom_scm_pas_context *c
 						  size_t *output_rt_size);
 
 int qcom_scm_pas_prepare_and_auth_reset(struct qcom_scm_pas_context *ctx);
+int qcom_scm_pas_set_wifi_power_mode(u32 peripheral, bool enable);
 
 int qcom_scm_io_readl(phys_addr_t addr, unsigned int *val);
 int qcom_scm_io_writel(phys_addr_t addr, unsigned int val);

-- 
2.53.0

