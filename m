From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v4 0/7] can: bcm: collected fixes
Date: Tue, 07 Jul 2026 16:32:12 +0200
Message-Id: <20260707-bcm_fixes-v4-0-aa87b8b9d33f@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOwNTWoC/3WNQQ6CMBBFr0K6tmZoSwuuvIcxppRBqhFIW4mGc
 HcLLjQGlz/z3puReHQWPdklI3E4WG+7Ng6xSYhpdHtGaqu4CQMmQaaMluZ2qu0DPc1FXQqtC64
 NI5HvHS6HiB+O7+3v5QVNmAMz0VgfOvdcng3pzK11h5QCNZrVGhSignrfaBeuXd9vWwxkTg/sI
 ytQ3zKLciElA5NxUapsReZ/ZR7lXEgAo2WV58WPPE3TC/GXbv4xAQAA
X-Change-ID: 20260612-bcm_fixes-84fb4aa93ac2
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, Lee Jones <lee@kernel.org>, 
 Ginger <ginger.jzllee@gmail.com>, 
 syzbot+75e5e4ae00c3b4bb544e@syzkaller.appspotmail.com, 
 sashiko-reviews@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783434738; l=1970;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=Vjpwr5VdpdObXUwUCRoh45lw133i7AjD7OaH3UU+X3o=;
 b=qQb+yzlAKNTI/3ZZ0g4oYXO5HdFuQnB8M5ErdITjikhoXSO5QWCKV+fE9odZ1+N8Asyo/js90
 xZfdPAWTlYCAcMDFfPsLlTDxM9avozaQSpEPgEk9cBYjQ+lZVyXgrR2
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Marc,

as there were different patches flying arround to fix CAN_BCM issues and
AI assisted stuff pop's up again and again, I've created this collection
to be applied.

I'm not sure whether sashiko-bot takes the sequence of this series into
account when checking the last patches. So let's see.

Best regards,
Oliver

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
Changes in v4:
- incorporated more sashiko-bot concerns from v3
- patch 3: omit hrtimer_forward with zero interval
- patch 4: put bcm_update_stats() under bcm_rx_update_lock
- Link to v3: https://patch.msgid.link/20260707-bcm_fixes-v3-0-84600ca6d889@hartkopp.net

Changes in v3:
- incorporated more sashiko-bot concerns from v2
- patch 3: make snapshot of currframe
- patch 6: add error patch for memcpy_from_msg()
- patch 7: new RTR-reply validation in bcm_rx_setup() from bcm_tx_setup() 
- Link to v2: https://patch.msgid.link/20260707-bcm_fixes-v2-0-96620c534b75@hartkopp.net

Changes in v2:
- incorporated all sashiko-bot concerns from v1
- Link to v1: https://patch.msgid.link/20260612-bcm_fixes-v1-0-ca2fa07ee70f@hartkopp.net

---
Lee Jones (1):
      can: bcm: defer rx_op deallocation to workqueue to fix thrtimer UAF

Oliver Hartkopp (6):
      can: bcm: fix lockless bound/ifindex race and silent RX_SETUP failure
      can: bcm: add locking when updating filter and timer values
      can: bcm: fix CAN frame rx/tx statistics
      can: bcm: add missing rcu list annotations and operations
      can: bcm: extend bcm_tx_lock usage for data and timer updates
      can: bcm: validate frame length in bcm_rx_setup() for RTR replies

 net/can/bcm.c | 427 ++++++++++++++++++++++++++++++++++++++++++++--------------
 1 file changed, 323 insertions(+), 104 deletions(-)
---
base-commit: 0e35b9b6ec0ffcc5e23cbdec09f5c622ad532b53
change-id: 20260612-bcm_fixes-84fb4aa93ac2

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

