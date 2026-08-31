From: Albert Esteve <aesteve@redhat.com>
Subject: [PATCH v2 0/2] firmware: qcom: scm locking improvements
Date: Mon, 31 Aug 2026 10:14:36 +0200
Message-Id: <20260831-port-scm-patches-v2-0-bab5595e77b3@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNwQ7CIBAFf6XZs2sAodae/A/TA4WtcGghQBpN0
 38Xm3jyOJO8eRtkSp4y9M0GiVaffVgqiFMDxunlSehtZRBMtKwTDGNIBbOZMepiHGUcJ9Vppfm
 oWoI6i4km/zqSj6Gy87mE9D4eVv61v5j8j60cGXI72fZ2uUrJxD2RdbqcTZhh2Pf9A+fI2kyxA
 AAA
X-Change-ID: 20260820-port-scm-patches-bf58a5a1b56e
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
 Jian Shu <quic_jianshu@quicinc.com>, 
 Yuvaraj Ranganathan <yrangana@qti.qualcomm.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788164078; l=2154;
 i=aesteve@redhat.com; s=20260827; h=from:subject:message-id;
 bh=2a87YwvXlbK2p5RobK9rOCcZ6p7tvvq6KtrWsDK4bek=;
 b=CoG55PZNb0t2NHZ9uWFZIHzRaa7khHTbihcIAi//QUKeM+vlPz730X+rEF3lsBaE+PV88h6+c
 tVT2HbM+qy8C/ix7kTzMTo9T8LuOi+MmR7N58An7EDNuc3ztAgsJrh7
X-Developer-Key: i=aesteve@redhat.com; a=ed25519;
 pk=zI2RBeZgocwYm3AkJW4CtjoJnKoDZrfBl1xe5Ed6h+U=
X-Endpoint-Received: by B4 Relay for aesteve@redhat.com/20260827 with auth_id=993
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The qcom_scm driver serializes Secure Channel Manager calls
to Qualcomm firmware. This series ports two related fixes from
Qualcomm's kernel trees [1][2] adapted for the current upstream
driver.

Series summary:

 Patch 1: Replace SCM global mutex with a counting semaphore.
 Patch 2: Allow SCM waitqueue completions to freeze and be killed
 cleanly on suspend and shutdown.

Adaptations:

- Size the semaphore from scm->wq_cnt (already queried via
  WAITQ_GET_INFO during probe) rather than adding call_ctx_cnt
  and extending skip_mutex helper
- Do not port skip_mutex unlock/relock around WAITQ_SLEEP; that
  path does not exist in master
- Initialize the semaphore before publishing __scm

Tested on Qualcomm's SA8775P Ride V3, kernel 7.2:
- qcom_scm probes successfully
- qcomtee platform device registered
- SMC calls complete without error

[1] https://git.codelinaro.org/clo/le/meta-qti-auto-kernel/-/raw/LY.AU.0.1.0.r1-16800-gen4meta.0/recipes-kernel/linux/files/scm_adci/0008-PENDING-firmware-qcom-scm-Introduce-new-locking-mech.patch
[2] https://git.codelinaro.org/clo/le/meta-qti-auto-kernel/-/commit/9319960e593c88e6d88bfaf0f6ed3e1235926ea3

Signed-off-by: Albert Esteve <aesteve@redhat.com>
---
Changes in v2:
- Improved issue explanation in commit bodies
  and added Fixes: tags
- Treat 0 wq_cnt responses as invalid
- Forward wait_for_completion_state() return value
- Link to v1: https://lore.kernel.org/r/20260824-port-scm-patches-v1-0-1dfd69374402@redhat.com

---
Ninad Naik (1):
      firmware: qcom: scm: Introduce new locking mechanism for SCM driver

Yuvaraj Ranganathan (1):
      firmware: qcom: scm: Allow the SMC request to freeze and kill

 drivers/firmware/qcom/qcom_scm-legacy.c |  8 ++------
 drivers/firmware/qcom/qcom_scm-smc.c    |  7 ++-----
 drivers/firmware/qcom/qcom_scm.c        | 10 ++++++----
 drivers/firmware/qcom/qcom_scm.h        |  3 +++
 4 files changed, 13 insertions(+), 15 deletions(-)
---
base-commit: 818bebeb63dd6bf5f4e07e145f6cdbace520a34c
change-id: 20260820-port-scm-patches-bf58a5a1b56e

Best regards,
-- 
Albert Esteve <aesteve@redhat.com>

