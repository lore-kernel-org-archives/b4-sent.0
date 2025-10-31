From: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
Date: Fri, 31 Oct 2025 10:18:13 +0000
Subject: [PATCH v4 1/2] soc: qcom: smem: Register gunyah watchdog device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251031-gunyah_watchdog-v4-1-7abb1ee11315@oss.qualcomm.com>
References: <20251031-gunyah_watchdog-v4-0-7abb1ee11315@oss.qualcomm.com>
In-Reply-To: <20251031-gunyah_watchdog-v4-0-7abb1ee11315@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761906073; l=2298;
 i=hrishabh.rajput@oss.qualcomm.com; s=20250903; h=from:subject:message-id;
 bh=ScMyepfgPdrQal4O/t/gi35G4I+goW0FS6p9YVcPjOI=;
 b=1qWdIsujLdCX86SfLztCocP3MKWXDMGJ61+zTsF+4d3pVKhPs7YKa2/Vs2YB0neeANKcrpgSO
 NeAIuM25vKbDor3Hv7CG76ynpZX1CQvn2IW3WHgWs5R4P0+km84l3DH
X-Developer-Key: i=hrishabh.rajput@oss.qualcomm.com; a=ed25519;
 pk=syafMitrjr3b/OYAtA2Im06AUb3fxZY2vJ/t4iCPmgw=
X-Endpoint-Received: by B4 Relay for hrishabh.rajput@oss.qualcomm.com/20250903 with auth_id=509
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To restrict gunyah watchdog initialization to Qualcomm platforms,
register the watchdog device in the SMEM driver.

When Gunyah is not present or Gunyah emulates MMIO-based
watchdog, we expect Qualcomm watchdog or ARM SBSA watchdog device to be
present in the devicetree. If none of these device nodes are detected,
we register the SMC-based Gunyah watchdog device.

Signed-off-by: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
---
 drivers/soc/qcom/smem.c | 37 +++++++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/drivers/soc/qcom/smem.c b/drivers/soc/qcom/smem.c
index cf425930539e..40e4749fab02 100644
--- a/drivers/soc/qcom/smem.c
+++ b/drivers/soc/qcom/smem.c
@@ -1118,6 +1118,34 @@ static int qcom_smem_resolve_mem(struct qcom_smem *smem, const char *name,
 	return 0;
 }
 
+static int register_gunyah_wdt_device(void)
+{
+	struct platform_device *gunyah_wdt_dev;
+	struct device_node *np;
+
+	/*
+	 * When Gunyah is not present or Gunyah is emulating a memory-mapped
+	 * watchdog, either of Qualcomm watchdog or ARM SBSA watchdog will be
+	 * present. Skip initialization of SMC-based Gunyah watchdog if that is
+	 * the case.
+	 */
+	np = of_find_compatible_node(NULL, NULL, "qcom,kpss-wdt");
+	if (np) {
+		of_node_put(np);
+		return 0;
+	}
+
+	np = of_find_compatible_node(NULL, NULL, "arm,sbsa-gwdt");
+	if (np) {
+		of_node_put(np);
+		return 0;
+	}
+
+	gunyah_wdt_dev = platform_device_register_simple("gunyah-wdt", -1,
+							 NULL, 0);
+	return PTR_ERR_OR_ZERO(gunyah_wdt_dev);
+}
+
 static int qcom_smem_probe(struct platform_device *pdev)
 {
 	struct smem_header *header;
@@ -1236,11 +1264,20 @@ static int qcom_smem_probe(struct platform_device *pdev)
 	if (IS_ERR(smem->socinfo))
 		dev_dbg(&pdev->dev, "failed to register socinfo device\n");
 
+	ret = register_gunyah_wdt_device();
+	if (ret)
+		dev_dbg(&pdev->dev, "failed to register watchdog device\n");
+
 	return 0;
 }
 
 static void qcom_smem_remove(struct platform_device *pdev)
 {
+	/*
+	 * Gunyah watchdog is intended to be a persistent module. Hence, the
+	 * watchdog device is not unregistered.
+	 */
+
 	platform_device_unregister(__smem->socinfo);
 
 	hwspin_lock_free(__smem->hwlock);

-- 
2.43.0

