From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v9 00/10] can: bcm: collected fixes - final4 :-O
Date: Thu, 09 Jul 2026 10:16:02 +0200
Message-Id: <20260709-bcm_fixes-v9-0-6eebb78ccfb2@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMJYT2oC/3XPy07FIBAG4Fc5YW0NHSgzuPI9jDFAwaKxbUptN
 Cd9d+G4sDF0OZn/m8uVJb9En9jD5coWv8UUpzEX+u7C3GDGV9/EPtcMOCiuWmis+3gJ8cunhmS
 w0hgtjAOW8/Pib40cf3r+rdOnffNuLQNKYohpnZbv27KtLbna3K1teOMMBMPRe+ThcTDL+j7N8
 /3oV1ZGb/CHkeMRQ8ZaKeCuE9JiV8HiFIuMSSrOnVE9ka5geYplxsYQWrK6F6J2dneKu/KzcCg
 D9RQCVrA6YjpiVc7m2HID1glNFYynGMtmzM8qKyR4WcF0iqlsdhC6IKyDFv7hfd9/AKZWX4hiA
 gAA
X-Change-ID: 20260612-bcm_fixes-84fb4aa93ac2
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, Lee Jones <lee@kernel.org>, 
 Feng Xue <feng.xue@outlook.com>, Ginger <ginger.jzllee@gmail.com>, 
 syzbot+75e5e4ae00c3b4bb544e@syzkaller.appspotmail.com, 
 sashiko-reviews@lists.linux.dev, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783584967; l=4137;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=tBUThDu5CaTPWaHWJiu5cC0qeSJ7u/IUCg6a1W45sIU=;
 b=P4RxTpSA1mv+sfwOBVUW9c8Bx037viPFQyAY8+k9hs2KooqFg67RFRNI1GcYLOrtsQbOjjsNy
 m4+DLoCdZixBkc/lgD78qKmG4LfhJsjVtzmt+3PkNBYzC77OlIWxuaY
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Marc,

as there were different patches flying arround to fix CAN_BCM issues and
AI assisted stuff pop's up again and again, I've created this collection
to be applied.

Fixed the new issues in patch 4

- [Medium] `bcm_update_stats()` can be executed concurrently from
  different lock domains, contradicting the commit's claim of preventing
  races during counter reset.
- [Medium] TX operations incorrectly inherit the RX-specific statistics
  cap, causing premature zeroing of the TX frame counter.
  
Best regards,
Oliver

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
Changes in v9:
- patch 4: fixed two issues reported by sashiko-bot and mkl
  https://lore.kernel.org/linux-can/20260708173935.10D021F000E9@smtp.kernel.org/
  https://lore.kernel.org/linux-can/20260708-beige-tarsier-of-mastery-b73d0d-mkl@pengutronix.de/
- Link to v8: https://patch.msgid.link/20260708-bcm_fixes-v8-0-8c2f5f3bc212@hartkopp.net

Changes in v8:
- patch 9: fixed two issues reported by sashiko-bot:
  https://lore.kernel.org/linux-can/20260708154039.347ED1F000E9@smtp.kernel.org/
- Link to v7: https://patch.msgid.link/20260708-bcm_fixes-v7-0-c78896b342e4@hartkopp.net

Changes in v7:
- patch 9: new: fix stale rx/tx ops after device removal reported by
  sashiko-bot: https://lore.kernel.org/linux-can/20260708094536.DDF821F00A3A@smtp.kernel.org/
- patch 10: formerly patch 9 as new patch 8 & 9 belong together 
- Link to v6: https://patch.msgid.link/20260708-bcm_fixes-v6-0-80710a2bc398@hartkopp.net

Changes in v6:
- patch 1: added Tested-by: tags
- patch 3: changed commit message and comment regarding a wrong claim
  about synchronous delivery from dev_queue_xmit() as remarked by
  https://netdev-ai.bots.linux.dev/ai-review.html?id=6105ebab-87ef-43db-a085-7c190b9f119f
- patch 4: rebased patch 3 comment
- patch 9: new: fix data race on rx_stamp/rx_ifindex in bcm_rx_handler()
  reported by sashiko-bot: https://lore.kernel.org/linux-can/20260707145135.5BC831F00A3A@smtp.kernel.org/
- Link to v5: https://patch.msgid.link/20260707-bcm_fixes-v5-0-c3c74f8d8ff7@hartkopp.net

Changes in v5:
- patch 6: changed comment for bcm_op::bcm_tx_lock (mkl)
- patch 8: new: add missing device refcount for CAN filter removal
- Link to v4: https://patch.msgid.link/20260707-bcm_fixes-v4-0-aa87b8b9d33f@hartkopp.net

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

Oliver Hartkopp (9):
      can: bcm: fix lockless bound/ifindex race and silent RX_SETUP failure
      can: bcm: add locking when updating filter and timer values
      can: bcm: fix CAN frame rx/tx statistics
      can: bcm: add missing rcu list annotations and operations
      can: bcm: extend bcm_tx_lock usage for data and timer updates
      can: bcm: validate frame length in bcm_rx_setup() for RTR replies
      can: bcm: add missing device refcount for CAN filter removal
      can: bcm: fix stale rx/tx ops after device removal
      can: bcm: fix data race on rx_stamp/rx_ifindex in bcm_rx_handler()

 net/can/bcm.c | 536 +++++++++++++++++++++++++++++++++++++++++++---------------
 1 file changed, 400 insertions(+), 136 deletions(-)
---
base-commit: 0e35b9b6ec0ffcc5e23cbdec09f5c622ad532b53
change-id: 20260612-bcm_fixes-84fb4aa93ac2

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

