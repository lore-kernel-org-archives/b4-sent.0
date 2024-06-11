From: Unnathi Chalicheemala <quic_uchalich@quicinc.com>
Date: Tue, 11 Jun 2024 11:27:58 -0700
Subject: [PATCH] firmware: qcom_scm: Mark get_wq_ctx() as atomic call
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-get_wq_ctx_atomic-v1-1-9189a0a7d1ba@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAC2XaGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDM0ND3fTUkvjywvjkkor4xJL83Mxk3TTTVMu0lOQkI4NkcyWgvoKi1LT
 MCrCZ0bG1tQDA9q9DYwAAAA==
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Sibi Sankar <quic_sibis@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 kernel@quicinc.com, Murali Nalajala <quic_mnalajal@quicinc.com>, 
 stable@vger.kernel.org, Unnathi Chalicheemala <quic_uchalich@quicinc.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718130490; l=1410;
 i=quic_uchalich@quicinc.com; s=20240514; h=from:subject:message-id;
 bh=QPM5gffihWkOaIL9zSFsTYRKxIFHPtphhyZkYhX+Ffs=;
 b=9hQjvBsx/jp6tQrA7LLONkGrRz5JN4p4i4TRAzp626wY+PYtyQ1cy8k/VgK2zuXm+gooVO8X+
 4hFy51H4Y/5AqzFlJ0xAJxBiDj6Q9FbpYxoBNjBKULN4RyFKTNSqWeF
X-Developer-Key: i=quic_uchalich@quicinc.com; a=ed25519;
 pk=o+hVng49r5k2Gc/f9xiwzvR3y1q4kwLOASwo+cFowXI=
X-Endpoint-Received: by B4 Relay for quic_uchalich@quicinc.com/20240514 with auth_id=162
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Murali Nalajala <quic_mnalajal@quicinc.com>

Currently get_wq_ctx() is wrongly configured as a standard call.
Here get_wq_ctx() must be an atomic call and can't be a standard
SMC call because get_wq_ctx() should not sleep again. This
situation lead to a deadlock. Hence mark get_wq_ctx() as
atomic call.

Fixes: 6bf325992236 ("firmware: qcom: scm: Add wait-queue handling logic")
Cc: stable@vger.kernel.org
Signed-off-by: Murali Nalajala <quic_mnalajal@quicinc.com>
Signed-off-by: Unnathi Chalicheemala <quic_uchalich@quicinc.com>
---
 drivers/firmware/qcom/qcom_scm-smc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/firmware/qcom/qcom_scm-smc.c b/drivers/firmware/qcom/qcom_scm-smc.c
index 16cf88acfa8e..0a2a2c794d0e 100644
--- a/drivers/firmware/qcom/qcom_scm-smc.c
+++ b/drivers/firmware/qcom/qcom_scm-smc.c
@@ -71,7 +71,7 @@ int scm_get_wq_ctx(u32 *wq_ctx, u32 *flags, u32 *more_pending)
 	struct arm_smccc_res get_wq_res;
 	struct arm_smccc_args get_wq_ctx = {0};
 
-	get_wq_ctx.args[0] = ARM_SMCCC_CALL_VAL(ARM_SMCCC_STD_CALL,
+	get_wq_ctx.args[0] = ARM_SMCCC_CALL_VAL(ARM_SMCCC_FAST_CALL,
 				ARM_SMCCC_SMC_64, ARM_SMCCC_OWNER_SIP,
 				SCM_SMC_FNID(QCOM_SCM_SVC_WAITQ, QCOM_SCM_WAITQ_GET_WQ_CTX));
 

---
base-commit: 83a7eefedc9b56fe7bfeff13b6c7356688ffa670
change-id: 20240611-get_wq_ctx_atomic-f5e9fdcb20c7

Best regards,
-- 
Unnathi Chalicheemala <quic_uchalich@quicinc.com>

