From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v2 0/6] can: bcm: collected fixes
Date: Tue, 07 Jul 2026 09:27:10 +0200
Message-Id: <20260707-bcm_fixes-v2-0-96620c534b75@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE6qTGoC/22NwQ7CIBAFf6XZsxiKTaue/A/TmAUXQSNtAImm4
 d+FevU4eZN5CwTylgIcmwU8JRvs5AqITQPKoLsRs9fCILjoed8KJtXzou2bAtt3WnaIhx0qAcW
 fPa1D0c/jj8NL3knFGqiGsSFO/rOepbZ6/7qpZZwpFBr5QDRwfTLo42Oa562jCGPO+QtpNvbMt
 wAAAA==
X-Change-ID: 20260612-bcm_fixes-84fb4aa93ac2
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, Lee Jones <lee@kernel.org>, 
 Ginger <ginger.jzllee@gmail.com>, 
 syzbot+75e5e4ae00c3b4bb544e@syzkaller.appspotmail.com, 
 sashiko-reviews@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783409247; l=1303;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=OapFFK86guigjYAJG/QuZbSnA9Lh6LWNJ1C6zs/wHGA=;
 b=1d0siPwaXaqUGsWus+c4ZDZ7xevHl1xgzbSYsIFXUMXFHHD+FleSE7MHJDTW3nHCsgL5eLUSN
 ixVf8zPiZB5BHAvEC62++THljbhllEV5z11RL6qwYs3LG7pX5Lw7HEi
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
Changes in v2:
- incorporated all sashiko-bot concerns from v1
- Link to v1: https://patch.msgid.link/20260612-bcm_fixes-v1-0-ca2fa07ee70f@hartkopp.net

---
Lee Jones (1):
      can: bcm: defer rx_op deallocation to workqueue to fix thrtimer UAF

Oliver Hartkopp (5):
      can: bcm: fix lockless bound/ifindex race and silent RX_SETUP failure
      can: bcm: add locking when updating filter and timer values
      can: bcm: fix CAN frame rx/tx statistics
      can: bcm: add missing rcu list annotations and operations
      can: bcm: extend bcm_tx_lock usage for data and timer updates

 net/can/bcm.c | 370 +++++++++++++++++++++++++++++++++++++++++++---------------
 1 file changed, 276 insertions(+), 94 deletions(-)
---
base-commit: 665159e246749578d4e4bfe106ee3b74edcdab18
change-id: 20260612-bcm_fixes-84fb4aa93ac2

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

