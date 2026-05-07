From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 07 May 2026 21:36:16 +0530
Subject: [PATCH v2 8/9] power: sequencing: Add an API to return the pwrseq
 device's 'dev' pointer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260507-pwrseq-m2-bt-v2-8-1740bd478539@oss.qualcomm.com>
References: <20260507-pwrseq-m2-bt-v2-0-1740bd478539@oss.qualcomm.com>
In-Reply-To: <20260507-pwrseq-m2-bt-v2-0-1740bd478539@oss.qualcomm.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Shuai Zhang <quic_shuaz@quicinc.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1996;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=rxWzd4lr/8TaHGBWfbY6c8DXpO+mcIR8KKWvZPYGs/8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp/Lh3s0snxu5XC7qLccfWlPE3hKIzKV4GGi7e3
 8QeFiRRSwSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCafy4dwAKCRBVnxHm/pHO
 9V6sB/9dGLubTojDBWN2BmdXreaZ18o+YkI9g8c06570gHpIzSqGQwMHDpveuJBSustypNYCWL+
 zgdNYOwlUPKOGtggun8PmHXi4F9XwgiDQmOZaDJK7703pt37dT3CNBs6G3exxUzj1I7Wy3twwt0
 KLdqje33t3XIqFVNK999y6xSChc9VjFn6QGw0Lvm595kBD85xio0GKgc/DXeP31rBj167WnHuhj
 /r1Z2zyN/3nP1UGzcINgeBW0el+wh7cMnO/O2EbHTNG5VWhaBirrxaX7/5RRt5HeRltTlbvwcKs
 NsEJ/uo4ckZzOOH1mqre+ruIraL18RyYpmItzOniTQC5urk9
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
2.51.0

