From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v6 0/9] can: bcm: collected fixes - final
Date: Wed, 08 Jul 2026 11:22:26 +0200
Message-Id: <20260708-bcm_fixes-v6-0-80710a2bc398@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANIWTmoC/3XPwU7EIBQF0F+ZsBbzChSoK//DTMyDPiyaaRuoz
 ZhJ/10YFxrTLm+45wI3lilFyuzpdGOJ1pjjNJagH07MDzi+EY99yUyA0KAbwZ2/vIZ4pcytCk4
 hdhK9YKU/J7oflPrL+SfnT/dOfqkDtTHEvEzp637Z2tTe3u7acOAeRUAwRAbC84Bp+Zjm+XGkh
 dXpVfxiA+YvFgV3WgvwrVTOtDtYHmJZsFUawKPure12sDrEqmBEa5x1XS/l3rPbQ9zWP0tvVLC
 9DcH8w9u2fQNiuTKqqwEAAA==
X-Change-ID: 20260612-bcm_fixes-84fb4aa93ac2
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, Lee Jones <lee@kernel.org>, 
 Feng Xue <feng.xue@outlook.com>, Ginger <ginger.jzllee@gmail.com>, 
 syzbot+75e5e4ae00c3b4bb544e@syzkaller.appspotmail.com, 
 sashiko-reviews@lists.linux.dev, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783502567; l=3105;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=TmXFOBkgQXuh/lphxNg9YKyBFII+72JGehB0s3XF5Xw=;
 b=23CWX4DHykvgw75qMc60s1sFJPDihriJOeNuVUJfXAW/QWVq2HOd4tOhuUaiKRkNDD0HIWcSY
 xpJv04CR1g8CN3RYWDWNUG46f2kH58uS7varN/Pfj1EoH4KmYlJWG5X
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Marc,

as there were different patches flying arround to fix CAN_BCM issues and
AI assisted stuff pop's up again and again, I've created this collection
to be applied.

The patch series fixes ALL issues reported by ALL kind of AI bots involved
and the fixes were assisted by claude code and later rephrased and shortened
by myself.

So the potential new AI reports on this patch set report problems that are
solved later in the series. This can not be resolved.

Best regards,
Oliver

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
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

Oliver Hartkopp (8):
      can: bcm: fix lockless bound/ifindex race and silent RX_SETUP failure
      can: bcm: add locking when updating filter and timer values
      can: bcm: fix CAN frame rx/tx statistics
      can: bcm: add missing rcu list annotations and operations
      can: bcm: extend bcm_tx_lock usage for data and timer updates
      can: bcm: validate frame length in bcm_rx_setup() for RTR replies
      can: bcm: add missing device refcount for CAN filter removal
      can: bcm: fix data race on rx_stamp/rx_ifindex in bcm_rx_handler()

 net/can/bcm.c | 484 ++++++++++++++++++++++++++++++++++++++++++----------------
 1 file changed, 355 insertions(+), 129 deletions(-)
---
base-commit: 0e35b9b6ec0ffcc5e23cbdec09f5c622ad532b53
change-id: 20260612-bcm_fixes-84fb4aa93ac2

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

