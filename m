From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 06 Jul 2026 21:26:19 +0400
Subject: [PATCH v4 3/6] firmware: qcom: scm: Add support for setting
 Bluetooth power modes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260706-ipq5018-bluetooth-v4-3-350262a30959@outlook.com>
References: <20260706-ipq5018-bluetooth-v4-0-350262a30959@outlook.com>
In-Reply-To: <20260706-ipq5018-bluetooth-v4-0-350262a30959@outlook.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783358843; l=3620;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=Qj+6gLNuiFxZ5V9W/9CM6QIzGTmy18FGib36hJU2/GI=;
 b=pUq7K8MHEJlj+P/CE1vnR7mJ7GxcY6MFsnMe4ORaTPkbs5P5FRbbsuS1cp4gD1qRVYE54h1WF
 ueY8HJ8ucccAxUKOS+EuvKWpcMjEs3SaOCAQv4bAvVRXOaDEMxw7Eos
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Bluetooth subsystem (BTSS) on the IPQ5018 SoC supports setting power
modes which are required to be configured through a Secure Channel
Manager (SCM) call to TrustZone. However, not all Trusted Execution
Environment (QSEE) images support this call, so first check if the call
is available.

Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/firmware/qcom/qcom_scm.c       | 44 ++++++++++++++++++++++++++++++++++
 drivers/firmware/qcom/qcom_scm.h       |  1 +
 include/linux/firmware/qcom/qcom_scm.h |  1 +
 3 files changed, 46 insertions(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 6b601a4b89db..a34e0f75df3c 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -1094,6 +1094,50 @@ bool qcom_scm_pas_supported(u32 pas_id)
 }
 EXPORT_SYMBOL_GPL(qcom_scm_pas_supported);
 
+/**
+ * qcom_scm_pas_set_bluetooth_power_mode() - Configure power mode for the
+ *					     Bluetooth subsystem (BTSS)
+ * @pas_id:	peripheral authentication service id
+ * @eco_mode:	true for ECO mode, false for normal operation
+ *
+ * Return: 0 on success, negative errno on failure.
+ * Returns -EOPNOTSUPP if the firmware configuration call is unavailable.
+ */
+int qcom_scm_pas_set_bluetooth_power_mode(u32 pas_id, bool eco_mode)
+{
+	struct qcom_scm_desc desc = {
+		.svc = QCOM_SCM_SVC_PIL,
+		.cmd = QCOM_SCM_PIL_PAS_BT_PWR_MODE,
+		.arginfo = QCOM_SCM_ARGS(2),
+		.args[0] = pas_id,
+		.args[1] = eco_mode ? 0x4 : 0x0,
+		.owner = ARM_SMCCC_OWNER_SIP,
+	};
+	struct qcom_scm_res res;
+	int ret;
+
+	if (!__qcom_scm_is_call_available(__scm->dev, QCOM_SCM_SVC_PIL,
+					  QCOM_SCM_PIL_PAS_BT_PWR_MODE))
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
+EXPORT_SYMBOL_GPL(qcom_scm_pas_set_bluetooth_power_mode);
+
 static int __qcom_scm_pas_mss_reset(struct device *dev, bool reset)
 {
 	struct qcom_scm_desc desc = {
diff --git a/drivers/firmware/qcom/qcom_scm.h b/drivers/firmware/qcom/qcom_scm.h
index caab80a73e17..5579df5a2aca 100644
--- a/drivers/firmware/qcom/qcom_scm.h
+++ b/drivers/firmware/qcom/qcom_scm.h
@@ -105,6 +105,7 @@ int qcom_scm_shm_bridge_enable(struct device *scm_dev);
 #define QCOM_SCM_PIL_PAS_SHUTDOWN	0x06
 #define QCOM_SCM_PIL_PAS_IS_SUPPORTED	0x07
 #define QCOM_SCM_PIL_PAS_MSS_RESET	0x0a
+#define QCOM_SCM_PIL_PAS_BT_PWR_MODE	0x21
 #define QCOM_SCM_PIL_PAS_GET_RSCTABLE	0x21
 
 #define QCOM_SCM_SVC_IO			0x05
diff --git a/include/linux/firmware/qcom/qcom_scm.h b/include/linux/firmware/qcom/qcom_scm.h
index 5747bd191bf1..aca937ac8ddd 100644
--- a/include/linux/firmware/qcom/qcom_scm.h
+++ b/include/linux/firmware/qcom/qcom_scm.h
@@ -93,6 +93,7 @@ struct resource_table *qcom_scm_pas_get_rsc_table(struct qcom_scm_pas_context *c
 						  size_t *output_rt_size);
 
 int qcom_scm_pas_prepare_and_auth_reset(struct qcom_scm_pas_context *ctx);
+int qcom_scm_pas_set_bluetooth_power_mode(u32 pas_id, bool eco_mode);
 
 int qcom_scm_io_readl(phys_addr_t addr, unsigned int *val);
 int qcom_scm_io_writel(phys_addr_t addr, unsigned int val);

-- 
2.53.0

