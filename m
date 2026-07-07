From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v3 0/7] can: bcm: collected fixes
Date: Tue, 07 Jul 2026 12:16:07 +0200
Message-Id: <20260707-bcm_fixes-v3-0-84600ca6d889@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOfRTGoC/22NQQ7CIBBFr9KwFkOnLVhX3sMYAzhYNLYNINE0v
 btQFxrj8mfeezMRj86iJ9tiIg6j9Xbo06hWBdGd7M9I7SltAgw44yVQpW9HYx/o6aY2qpayraQ
 GkvjR4XJI+P7w3v6uLqhDDmSisz4M7rk8i2Xm/nVjSRnVEoxkAlEws+ukC9dhHNc9BpLTET6yY
 OJbhiS3nAPTTVUr0fzI8zy/ACbJo2n0AAAA
X-Change-ID: 20260612-bcm_fixes-84fb4aa93ac2
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, Lee Jones <lee@kernel.org>, 
 Ginger <ginger.jzllee@gmail.com>, 
 syzbot+75e5e4ae00c3b4bb544e@syzkaller.appspotmail.com, 
 sashiko-reviews@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783419375; l=1700;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=y2H9QtAl1+vBSs56o1KfjI/JrbU58kVjOgl4MWaQQAE=;
 b=CSfirpZaCUrg5h2n3eQ9Ka3Vpmiqc+gDhsROMlw1ui9v1/VjK4MfKGMVKvms5cYeLiQxrMBx6
 mUvbUWF2dO2A5IcMQj2u2Srw5Y+LCrypDCCVqYlEteyN34NPqBfH58E
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

 net/can/bcm.c | 416 ++++++++++++++++++++++++++++++++++++++++++++--------------
 1 file changed, 314 insertions(+), 102 deletions(-)
---
base-commit: 665159e246749578d4e4bfe106ee3b74edcdab18
change-id: 20260612-bcm_fixes-84fb4aa93ac2

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

