From: Albert Esteve <aesteve@redhat.com>
Date: Mon, 31 Aug 2026 10:14:38 +0200
Subject: [PATCH v2 2/2] firmware: qcom: scm: Allow the SMC request to
 freeze and kill
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-port-scm-patches-v2-2-bab5595e77b3@redhat.com>
References: <20260831-port-scm-patches-v2-0-bab5595e77b3@redhat.com>
In-Reply-To: <20260831-port-scm-patches-v2-0-bab5595e77b3@redhat.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Shivendra Pratap <shivendra.pratap@oss.qualcomm.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Unnathi Chalicheemala <unnathi.chalicheemala@oss.qualcomm.com>, 
 Mukesh Ojha <mukesh.ojha@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Albert Esteve <aesteve@redhat.com>, 
 Yuvaraj Ranganathan <yrangana@qti.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788164078; l=1339;
 i=aesteve@redhat.com; s=20260827; h=from:subject:message-id;
 bh=Tm4UTIwoxQT5KHbYSrQ/GqM30LVTWUwE87PSxfkz9NU=;
 b=oNQQpiWcgeyV0r3wh52GzmqOnGF3Nsk7qtYxhw3PxFjha2ulbeEpp+NVUy/Pqvm7ho6h2o6vS
 Ne0d0i/PKa7BZnJ+NFIPVZMc9puwT+5Dz9z3qUXiQ7RKX6ZnKvnDD9Y
X-Developer-Key: i=aesteve@redhat.com; a=ed25519;
 pk=zI2RBeZgocwYm3AkJW4CtjoJnKoDZrfBl1xe5Ed6h+U=
X-Endpoint-Received: by B4 Relay for aesteve@redhat.com/20260827 with auth_id=993
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Yuvaraj Ranganathan <yrangana@qti.qualcomm.com>

qcom_scm_wait_for_wq_completion() waits in TASK_IDLE. That is
uninterruptible, so a thread parked on a firmware waitq cannot be
frozen or killed. A long wait then blocks suspend, and shutdown
cannot tear the task down.

Wait with TASK_IDLE | TASK_FREEZABLE | TASK_KILLABLE so the freezer
can freeze the waiter during suspend; after resume it is still waiting
for the same waitq completion, and a fatal signal can abort it on shutdown.

Fixes: 366f05e348b2 ("firmware: qcom_scm: Use TASK_IDLE state in wait_for_wq_completion()")
Signed-off-by: Yuvaraj Ranganathan <yrangana@qti.qualcomm.com>
Signed-off-by: Albert Esteve <aesteve@redhat.com>
---
 drivers/firmware/qcom/qcom_scm.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index ea4481385412..3e12258d0da7 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -2664,9 +2664,7 @@ int qcom_scm_wait_for_wq_completion(struct device *dev, u32 wq_ctx)
 	if (IS_ERR(wq))
 		return PTR_ERR(wq);
 
-	wait_for_completion_state(wq, TASK_IDLE);
-
-	return 0;
+	return wait_for_completion_state(wq, TASK_IDLE | TASK_FREEZABLE | TASK_KILLABLE);
 }
 
 static int qcom_scm_waitq_wakeup(struct qcom_scm *scm, unsigned int wq_ctx)

-- 
2.55.0

