From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v5 0/8] can: bcm: collected fixes
Date: Tue, 07 Jul 2026 20:00:36 +0200
Message-Id: <20260707-bcm_fixes-v5-0-c3c74f8d8ff7@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMQ+TWoC/3XOQW7DIBAF0KtErEs0Bgw4q9wjiqoBj2taxbbAs
 VJZvntwumgUOcuv+e/DzBLFQIkddjOLNIUU+i6H8mPHfIvdF/FQ58wECA26ENz5y2cTbpS4VY1
 TiJVEL1juD5Eeh1w/nf9yurpv8uM6sDbakMY+/j4em4q1t7U7FRy4R9EgGCIDzbHFOP70w7Dva
 GTr9CT+sQHzjEXGldYCfCmVM+UGlm+xzNgqDeBR19ZWG1i9xSpjRGucdVUt5eu3l2W5AwSSCwV
 uAQAA
X-Change-ID: 20260612-bcm_fixes-84fb4aa93ac2
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, Lee Jones <lee@kernel.org>, 
 Ginger <ginger.jzllee@gmail.com>, 
 syzbot+75e5e4ae00c3b4bb544e@syzkaller.appspotmail.com, 
 sashiko-reviews@lists.linux.dev, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783447246; l=2272;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=loo2OdcIs+xpNjMCDmWrUTELPSdUl6N1IWlt+SriCGQ=;
 b=tlCSoZLjbDzh56/Ka8aze7um56VYHf1qpKlVYR3MfbyCl+ffmXMbRo0+UahC8dN9J2lTG2skb
 DatPowdmWWzAlnic3doWJKiP6hN5f2uUor7+BBBfDzHzBm5HU9JRl75
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

Oliver Hartkopp (7):
      can: bcm: fix lockless bound/ifindex race and silent RX_SETUP failure
      can: bcm: add locking when updating filter and timer values
      can: bcm: fix CAN frame rx/tx statistics
      can: bcm: add missing rcu list annotations and operations
      can: bcm: extend bcm_tx_lock usage for data and timer updates
      can: bcm: validate frame length in bcm_rx_setup() for RTR replies
      can: bcm: add missing device refcount for CAN filter removal

 net/can/bcm.c | 476 +++++++++++++++++++++++++++++++++++++++++++---------------
 1 file changed, 351 insertions(+), 125 deletions(-)
---
base-commit: 0e35b9b6ec0ffcc5e23cbdec09f5c622ad532b53
change-id: 20260612-bcm_fixes-84fb4aa93ac2

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

