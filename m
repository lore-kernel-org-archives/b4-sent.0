From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 May 2026 14:26:01 +0530
Subject: [PATCH v3 6/9] power: sequencing: Add an API to return the pwrseq
 device's 'dev' pointer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-pwrseq-m2-bt-v3-6-b39dc2ae3966@oss.qualcomm.com>
References: <20260519-pwrseq-m2-bt-v3-0-b39dc2ae3966@oss.qualcomm.com>
In-Reply-To: <20260519-pwrseq-m2-bt-v3-0-b39dc2ae3966@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-pci@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2045;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=zADSByazZrrmfWmx+ulwGuogrsAOGSim5Z5uII1xUr4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDCWfDRV7LdUoFWUtrVGtOhWtrgun+hmgmkALV
 BI78o07556JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwlnwAKCRBVnxHm/pHO
 9Q4VB/98OOJrEzs8nK5BnEwlQYPWPS0WHYJegif8o0X9ZYToRMTcvL6miALMbQtqz7yU9gTxq99
 8ceA2jp50JMMBTF4wBcFSDM6O8/xCZ0e6jUx90XfPMLjN9Xa+OC433UOQGh5qGALsf9IxoT5XmT
 FxbjmEB0OO+BSGjPEpzgUJYxd+dp5GVJEfQyWgMqwCew94cngjbKg4DYHABRmco5pApJZZNIITE
 /gSG4HFkfVzMFo5hcvHvhMWYmst2eu6wksQz8J59kcXbMRVlqiIPz7diSAQnTN+GPb0z9Hs98ZQ
 BR9OR/NJ3kstNajR5vsY30zqt8j632S9hSrpPpCc8TrV4gbA
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The consumer drivers can make use of the pwrseq device's 'dev' pointer to
query the pwrseq provider's DT node to check for existence of specific
properties.

Hence, add an API to return the pwrseq device's 'dev' pointer to consumers.

Note that since pwrseq_get() would've increased the pwrseq refcount, there
is no need to increase the refcount in this API again.

Tested-by: Wei Deng <wei.deng@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/core.c | 9 +++++++++
 include/linux/pwrseq/consumer.h | 7 +++++++
 2 files changed, 16 insertions(+)

diff --git a/drivers/power/sequencing/core.c b/drivers/power/sequencing/core.c
index 4dff71be11b6..96ad557297f5 100644
--- a/drivers/power/sequencing/core.c
+++ b/drivers/power/sequencing/core.c
@@ -965,6 +965,15 @@ int pwrseq_power_off(struct pwrseq_desc *desc)
 }
 EXPORT_SYMBOL_GPL(pwrseq_power_off);
 
+struct device *pwrseq_to_device(struct pwrseq_desc *desc)
+{
+	if (!desc)
+		return NULL;
+
+	return &desc->pwrseq->dev;
+}
+EXPORT_SYMBOL_GPL(pwrseq_to_device);
+
 #if IS_ENABLED(CONFIG_DEBUG_FS)
 
 struct pwrseq_debugfs_count_ctx {
diff --git a/include/linux/pwrseq/consumer.h b/include/linux/pwrseq/consumer.h
index 7d583b4f266e..3c907c9e1885 100644
--- a/include/linux/pwrseq/consumer.h
+++ b/include/linux/pwrseq/consumer.h
@@ -23,6 +23,8 @@ devm_pwrseq_get(struct device *dev, const char *target);
 int pwrseq_power_on(struct pwrseq_desc *desc);
 int pwrseq_power_off(struct pwrseq_desc *desc);
 
+struct device *pwrseq_to_device(struct pwrseq_desc *desc);
+
 #else /* CONFIG_POWER_SEQUENCING */
 
 static inline struct pwrseq_desc * __must_check
@@ -51,6 +53,11 @@ static inline int pwrseq_power_off(struct pwrseq_desc *desc)
 	return -ENOSYS;
 }
 
+static inline struct device *pwrseq_to_device(struct pwrseq_desc *desc)
+{
+	return NULL;
+}
+
 #endif /* CONFIG_POWER_SEQUENCING */
 
 #endif /* __POWER_SEQUENCING_CONSUMER_H__ */

-- 
2.48.1

