From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Wed, 18 Feb 2026 11:58:06 +0100
Subject: [PATCH] can: bcm: fix locking for bcm_op runtime updates
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260218-bcm_spin_lock_init-v1-1-592634c8a5b5@hartkopp.net>
X-B4-Tracking: v=1; b=H4sIAD2blWkC/yXMTQqDMBBA4avIrA0kQUvwKiLBxGk7/kTJqAji3
 Rvt8lu8dwJjJGSoshMi7sQ0hwSVZ+C/bfigoC4ZtNQvqZURzk+WFwp2nP1gKdAqdKkMOtMVpVS
 QwiXim45nWjd/8+Z69Ot9guv6Ad2nx7V2AAAA
X-Change-ID: 20260218-bcm_spin_lock_init-2518eb8d4501
To: Marc Kleine-Budde <mkl@pengutronix.de>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+5b11eccc403dd1cea9f8@syzkaller.appspotmail.com, 
 Oliver Hartkopp <socketcan@hartkopp.net>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771412303; l=1718;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=6cstQeyQgLIl4DE3G5AH+ISHLnxDQyJA9yrO83rD9qM=;
 b=tzCSZ60jq1WYEiVxpsmi1veCfJ/CplHayT7UuuFYty2KctMTPN3SsgsNyWsGXU8QNIF34qsJx
 fi821KxQBL2BlennaF+hUqmROr0q+v2Nrmb65iftXKlH5XEiy9Ydpte
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit c2aba69d0c36 ("can: bcm: add locking for bcm_op runtime updates")
added a locking for some variables that can be modified at runtime when
updating the sending bcm_op with a new TX_SETUP command in bcm_tx_setup().

Usually the RX_SETUP only handles and filters incoming traffic with one
exception: When the RX_RTR_FRAME flag is set a predefined CAN frame is
sent when a specific RTR frame is received. Therefore the rx bcm_op uses
bcm_can_tx() which uses the bcm_tx_lock that was only initialized in
bcm_tx_setup(). Add the missing spin_lock_init() when allocating the
bcm_op in bcm_rx_setup() to handle the RTR case properly.

Fixes: c2aba69d0c36 ("can: bcm: add locking for bcm_op runtime updates")
Reported-by: syzbot+5b11eccc403dd1cea9f8@syzkaller.appspotmail.com
Closes: https://lore.kernel.org/linux-can/699466e4.a70a0220.2c38d7.00ff.GAE@google.com/
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/bcm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/net/can/bcm.c b/net/can/bcm.c
index b7324e9c955b..fd9fa072881e 100644
--- a/net/can/bcm.c
+++ b/net/can/bcm.c
@@ -1174,10 +1174,11 @@ static int bcm_rx_setup(struct bcm_msg_head *msg_head, struct msghdr *msg,
 		/* insert new BCM operation for the given can_id */
 		op = kzalloc(OPSIZ, GFP_KERNEL);
 		if (!op)
 			return -ENOMEM;
 
+		spin_lock_init(&op->bcm_tx_lock);
 		op->can_id = msg_head->can_id;
 		op->nframes = msg_head->nframes;
 		op->cfsiz = CFSIZ(msg_head->flags);
 		op->flags = msg_head->flags;
 

---
base-commit: 2961f841b025fb234860bac26dfb7fa7cb0fb122
change-id: 20260218-bcm_spin_lock_init-2518eb8d4501

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

