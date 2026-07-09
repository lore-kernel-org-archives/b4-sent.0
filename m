From: Esteban Urrutia <esteuwu@proton.me>
Date: Wed, 08 Jul 2026 23:27:19 -0400
Subject: [PATCH RFC] remoteproc: qcom: q6v5: Only print handover error once
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-q6v5-handover-v1-1-be0e6cba0b13@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcwML3UKzMlNdoExKfllqka5ZWkqyWVKKSbKRmakSUE9BUWpaZgXYvGi
 lIDdnpViIYHFpUlZqcgnIJKXaWgCo/mfAdgAAAA==
X-Change-ID: 20260708-q6v5-handover-6fdc6bd4c265
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783567638; l=3032;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=WRlfOb7BJH4o0RSa6fkA/yjtgThVqiPMGxbi8obWNd8=;
 b=JVR7n/XYUHkKIyj/tQfYG1a6mCkyNlzGhoLwffr/0okHdWF1GdMkjmjJ5soa6tdsKHxUl/+p3
 SU5Xed8HCi0ApqYqxWzSG7XSGsfKB4cvRAuY6T2bEIildFd4qYKfObC
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some devices, firmware for the remote processors can signal a handover
more than once.
In the worst case, the kernel buffer will be spammed with this error
message, leading to the kernel buffer consisting of just this:

[  106.305033] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened
[  106.506070] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened
[  106.707103] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened
[  106.908612] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened
[  107.108158] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened
[  107.309944] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened
[  107.510795] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened
[  107.712183] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened
[  107.912834] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened
[  108.114217] qcom_q6v5_pas 2400000.remoteproc: Handover signaled, but it already happened

Instead of printing an error every time a processor signals a handover more
than once, only print an error once.
This way, the error is still present, but it won't fill up the kernel
buffer.

Fixes: 54898664e1eb ("remoteproc: qcom: q6v5: Avoid handling handover twice")
Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
I've been using the mainline kernel for a while now on motorola-bronco,
which is an SM8475 based device.
This device's firmware for the remoteprocs, specially for the SLPI,
seems to signal handovers way too frequently.
As of now, the Q6V5 driver will print an error each time a remoteproc
signals a handover twice, which leads to the kernel buffer filling up
pretty quickly.
I would like to suggest replacing the call to dev_err() with
dev_err_once() and would like feedback as to whether this is the proper
way of handling firmwares with this behavior.
This way, the error would still be printed, but only once, and this
issue would become much less of an annoyance for devices with buggy
firmware like this.

Regards,
Esteban
---
 drivers/remoteproc/qcom_q6v5.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/remoteproc/qcom_q6v5.c b/drivers/remoteproc/qcom_q6v5.c
index 58d5b85e58cd..81e894cc8634 100644
--- a/drivers/remoteproc/qcom_q6v5.c
+++ b/drivers/remoteproc/qcom_q6v5.c
@@ -165,7 +165,7 @@ static irqreturn_t q6v5_handover_interrupt(int irq, void *data)
 	struct qcom_q6v5 *q6v5 = data;
 
 	if (q6v5->handover_issued) {
-		dev_err(q6v5->dev, "Handover signaled, but it already happened\n");
+		dev_err_once(q6v5->dev, "Handover signaled, but it already happened\n");
 		return IRQ_HANDLED;
 	}
 

---
base-commit: 3d5670d672ae08b8c534b7beed6f57c8b44e7b43
change-id: 20260708-q6v5-handover-6fdc6bd4c265

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

