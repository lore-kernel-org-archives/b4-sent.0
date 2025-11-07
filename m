From: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
Date: Fri, 07 Nov 2025 17:53:08 +0000
Subject: [PATCH v5 1/2] firmware: qcom: scm: Register gunyah watchdog
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251107-gunyah_watchdog-v5-1-4c6e3fb6eb17@oss.qualcomm.com>
References: <20251107-gunyah_watchdog-v5-0-4c6e3fb6eb17@oss.qualcomm.com>
In-Reply-To: <20251107-gunyah_watchdog-v5-0-4c6e3fb6eb17@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Pavan Kondeti <pavan.kondeti@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762538126; l=2893;
 i=hrishabh.rajput@oss.qualcomm.com; s=20250903; h=from:subject:message-id;
 bh=OYio7ePuF7bexipr2dub+KGV3Y4ePYnSIMFShkeEOjo=;
 b=6xL/aZMUQY3sM3z+pNWQpG9m+1hM5qk5f+fVqZdm2VIrnCKKGDUswvJbjb6hJZW3UO6bjB0Hc
 mMggNfA7XAICt0mpUMj7RdfP7y2eZoTqDc+d3ulDF18Ps1ss2bNDws9
X-Developer-Key: i=hrishabh.rajput@oss.qualcomm.com; a=ed25519;
 pk=syafMitrjr3b/OYAtA2Im06AUb3fxZY2vJ/t4iCPmgw=
X-Endpoint-Received: by B4 Relay for hrishabh.rajput@oss.qualcomm.com/20250903 with auth_id=509
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To restrict Gunyah watchdog initialization to Qualcomm platforms running
under the Gunyah Hypervisor, register the watchdog device in the QCOM
SCM driver.

When Gunyah is not present or Gunyah emulates MMIO-based watchdog, we
expect Qualcomm watchdog or ARM SBSA watchdog device to be present in
the devicetree. First, we make sure we're running under the Gunyah
Hypervisor. Then we move to check if any of the above mentioned
watchdog device nodes are present, if not then we proceed to register
the SMC-based Gunyah watchdog device.

Signed-off-by: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
---
 drivers/firmware/qcom/qcom_scm.c | 51 ++++++++++++++++++++++++++++++++++++++++
 1 file changed, 51 insertions(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index e777b7cb9b12..71b79c0229da 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -2182,6 +2182,54 @@ int qcom_scm_qtee_callback_response(phys_addr_t buf, size_t buf_size,
 }
 EXPORT_SYMBOL(qcom_scm_qtee_callback_response);
 
+static void qcom_scm_gunyah_wdt_free(void *data)
+{
+	struct platform_device *gunyah_wdt_dev = data;
+
+	platform_device_unregister(gunyah_wdt_dev);
+}
+
+static void qcom_scm_gunyah_wdt_init(struct qcom_scm *scm)
+{
+	struct platform_device *gunyah_wdt_dev;
+	struct device_node *np;
+	bool of_wdt_available;
+	int i;
+	uuid_t gunyah_uuid = UUID_INIT(0xc1d58fcd, 0xa453, 0x5fdb, 0x92, 0x65,
+				       0xce, 0x36, 0x67, 0x3d, 0x5f, 0x14);
+	static const char * const of_wdt_compatible[] = {
+		"qcom,kpss-wdt",
+		"arm,sbsa-gwdt",
+	};
+
+	/* Bail out if we are not running under Gunyah */
+	if (!arm_smccc_hypervisor_has_uuid(&gunyah_uuid))
+		return;
+
+	/*
+	 * Gunyah emulates either of Qualcomm watchdog or ARM SBSA watchdog on
+	 * newer platforms. Bail out if we find them in the devicetree.
+	 */
+	for (i = 0; i < ARRAY_SIZE(of_wdt_compatible); i++) {
+		np = of_find_compatible_node(NULL, NULL, of_wdt_compatible[i]);
+		of_wdt_available = of_device_is_available(np);
+		of_node_put(np);
+		if (of_wdt_available)
+			return;
+	}
+
+	gunyah_wdt_dev = platform_device_register_simple("gunyah-wdt", -1,
+							 NULL, 0);
+	if (IS_ERR(gunyah_wdt_dev)) {
+		dev_err(scm->dev, "Failed to register Gunyah watchdog device: %ld\n",
+			PTR_ERR(gunyah_wdt_dev));
+		return;
+	}
+
+	devm_add_action_or_reset(scm->dev, qcom_scm_gunyah_wdt_free,
+				 gunyah_wdt_dev);
+}
+
 static void qcom_scm_qtee_free(void *data)
 {
 	struct platform_device *qtee_dev = data;
@@ -2448,6 +2496,9 @@ static int qcom_scm_probe(struct platform_device *pdev)
 	/* Initialize the QTEE object interface. */
 	qcom_scm_qtee_init(scm);
 
+	/* Initialize the Gunyah watchdog platform device. */
+	qcom_scm_gunyah_wdt_init(scm);
+
 	return 0;
 }
 

-- 
2.43.0

