From: Albert Esteve <aesteve@redhat.com>
Date: Mon, 31 Aug 2026 10:14:37 +0200
Subject: [PATCH v2 1/2] firmware: qcom: scm: Introduce new locking
 mechanism for SCM driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-port-scm-patches-v2-1-bab5595e77b3@redhat.com>
References: <20260831-port-scm-patches-v2-0-bab5595e77b3@redhat.com>
In-Reply-To: <20260831-port-scm-patches-v2-0-bab5595e77b3@redhat.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Shivendra Pratap <shivendra.pratap@oss.qualcomm.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Unnathi Chalicheemala <unnathi.chalicheemala@oss.qualcomm.com>, 
 Mukesh Ojha <mukesh.ojha@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Albert Esteve <aesteve@redhat.com>, Ninad Naik <quic_ninanaik@quicinc.com>, 
 Murali Nalajala <quic_mnalajal@quicinc.com>, 
 Venkatakrishnaiah Pari <quic_vpari@quicinc.com>, 
 Jian Shu <quic_jianshu@quicinc.com>, Guru Das Srinagesh <linux@gurudas.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788164078; l=4918;
 i=aesteve@redhat.com; s=20260827; h=from:subject:message-id;
 bh=6/Qv9tRwdvX6/5mjo1VRSsiyGOM2ISs+NDMUgFQSqCE=;
 b=hGHwlQDrXvTtjSqaazdhYmRqHEyDLGncTVuGt1euoF2oU2dqfKse8q+csjE5qLKy2qi6Lastq
 U59VuctaE6xCAMz/wxxLbkkSJ3M9U9UN6DZgkuhKg+D+Z/6epu1Qw2/
X-Developer-Key: i=aesteve@redhat.com; a=ed25519;
 pk=zI2RBeZgocwYm3AkJW4CtjoJnKoDZrfBl1xe5Ed6h+U=
X-Endpoint-Received: by B4 Relay for aesteve@redhat.com/20260827 with auth_id=993
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ninad Naik <quic_ninanaik@quicinc.com>

qcom_scm holds its global mutex across WAITQ_SLEEP and
wait_for_completion(). Firmware waitqs allow multiple SMCs in
flight (wq_cnt). If one call is parked on a waitq while holding
the mutex, a second call (e.g., SMCInvoke) cannot enter firmware
and both stall on the waitq.

Replace the global mutex with a counting semaphore sized from wq_cnt,
with at least 1 wait queue.

Fixes: ccd207ec848e ("firmware: qcom_scm: Support multiple waitq contexts")
Signed-off-by: Murali Nalajala <quic_mnalajal@quicinc.com>
Co-developed-by: Guru Das Srinagesh <quic_gurus@quicinc.com>
Signed-off-by: Guru Das Srinagesh <quic_gurus@quicinc.com>
Signed-off-by: Venkatakrishnaiah Pari <quic_vpari@quicinc.com>
Signed-off-by: Jian Shu <quic_jianshu@quicinc.com>
Signed-off-by: Ninad Naik <quic_ninanaik@quicinc.com>
Signed-off-by: Albert Esteve <aesteve@redhat.com>
---
 drivers/firmware/qcom/qcom_scm-legacy.c | 8 ++------
 drivers/firmware/qcom/qcom_scm-smc.c    | 7 ++-----
 drivers/firmware/qcom/qcom_scm.c        | 6 +++++-
 drivers/firmware/qcom/qcom_scm.h        | 3 +++
 4 files changed, 12 insertions(+), 12 deletions(-)

diff --git a/drivers/firmware/qcom/qcom_scm-legacy.c b/drivers/firmware/qcom/qcom_scm-legacy.c
index 029e6d117cb8..6afcbe6f7e5e 100644
--- a/drivers/firmware/qcom/qcom_scm-legacy.c
+++ b/drivers/firmware/qcom/qcom_scm-legacy.c
@@ -6,7 +6,6 @@
 #include <linux/slab.h>
 #include <linux/io.h>
 #include <linux/module.h>
-#include <linux/mutex.h>
 #include <linux/errno.h>
 #include <linux/err.h>
 #include <linux/firmware/qcom/qcom_scm.h>
@@ -15,9 +14,6 @@
 
 #include "qcom_scm.h"
 
-static DEFINE_MUTEX(qcom_scm_lock);
-
-
 /**
  * struct arm_smccc_args
  * @args:	The array of values used in registers in smc instruction
@@ -173,11 +169,11 @@ int scm_legacy_call(struct device *dev, const struct qcom_scm_desc *desc,
 	smc.args[1] = (unsigned long)&context_id;
 	smc.args[2] = cmd_phys;
 
-	mutex_lock(&qcom_scm_lock);
+	down(&qcom_scm_sem_lock);
 	__scm_legacy_do(&smc, &smc_res);
 	if (smc_res.a0)
 		ret = qcom_scm_remap_error(smc_res.a0);
-	mutex_unlock(&qcom_scm_lock);
+	up(&qcom_scm_sem_lock);
 	if (ret)
 		goto out;
 
diff --git a/drivers/firmware/qcom/qcom_scm-smc.c b/drivers/firmware/qcom/qcom_scm-smc.c
index 127365ab11fc..1b51e0fb8292 100644
--- a/drivers/firmware/qcom/qcom_scm-smc.c
+++ b/drivers/firmware/qcom/qcom_scm-smc.c
@@ -6,7 +6,6 @@
 #include <linux/io.h>
 #include <linux/errno.h>
 #include <linux/delay.h>
-#include <linux/mutex.h>
 #include <linux/slab.h>
 #include <linux/types.h>
 #include <linux/firmware/qcom/qcom_scm.h>
@@ -27,8 +26,6 @@ struct arm_smccc_args {
 #define CREATE_TRACE_POINTS
 #include "qcom_scm_trace.h"
 
-static DEFINE_MUTEX(qcom_scm_lock);
-
 #define QCOM_SCM_EBUSY_WAIT_MS 30
 #define QCOM_SCM_EBUSY_MAX_RETRY 20
 
@@ -135,11 +132,11 @@ static int __scm_smc_do(struct device *dev, struct arm_smccc_args *smc,
 	}
 
 	do {
-		mutex_lock(&qcom_scm_lock);
+		down(&qcom_scm_sem_lock);
 
 		ret = __scm_smc_do_quirk_handle_waitq(dev, smc, res);
 
-		mutex_unlock(&qcom_scm_lock);
+		up(&qcom_scm_sem_lock);
 
 		if (ret)
 			return ret;
diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 3eaa4c9ccf3c..ea4481385412 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -78,6 +78,8 @@ struct qcom_scm_mem_map_info {
 	__le64 mem_size;
 };
 
+DEFINE_SEMAPHORE(qcom_scm_sem_lock, 1);
+
 /**
  * struct qcom_scm_qseecom_resp - QSEECOM SCM call response.
  * @result:    Result or status of the SCM call. See &enum qcom_scm_qseecom_result.
@@ -2869,7 +2871,7 @@ static int qcom_scm_probe(struct platform_device *pdev)
 	}
 
 	ret = qcom_scm_query_waitq_count(scm);
-	scm->wq_cnt = ret < 0 ? QCOM_SCM_DEFAULT_WAITQ_COUNT : ret;
+	scm->wq_cnt = ret <= 0 ? QCOM_SCM_DEFAULT_WAITQ_COUNT : ret;
 	scm->waitq_comps = devm_kcalloc(&pdev->dev, scm->wq_cnt, sizeof(*scm->waitq_comps),
 					GFP_KERNEL);
 	if (!scm->waitq_comps)
@@ -2893,6 +2895,8 @@ static int qcom_scm_probe(struct platform_device *pdev)
 					     "Failed to request qcom-scm irq\n");
 	}
 
+	sema_init(&qcom_scm_sem_lock, scm->wq_cnt);
+
 	/*
 	 * Paired with smp_load_acquire() in qcom_scm_is_available().
 	 *
diff --git a/drivers/firmware/qcom/qcom_scm.h b/drivers/firmware/qcom/qcom_scm.h
index cf90a565fdfb..06fdc5e56bea 100644
--- a/drivers/firmware/qcom/qcom_scm.h
+++ b/drivers/firmware/qcom/qcom_scm.h
@@ -4,6 +4,8 @@
 #ifndef __QCOM_SCM_INT_H
 #define __QCOM_SCM_INT_H
 
+#include <linux/semaphore.h>
+
 struct device;
 struct qcom_tzmem_pool;
 
@@ -15,6 +17,7 @@ enum qcom_scm_convention {
 };
 
 extern enum qcom_scm_convention qcom_scm_convention;
+extern struct semaphore qcom_scm_sem_lock;
 
 #define MAX_QCOM_SCM_ARGS 10
 #define MAX_QCOM_SCM_RETS 3

-- 
2.55.0

