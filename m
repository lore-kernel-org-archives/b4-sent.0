From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Thu, 19 Feb 2026 17:51:17 +0100
Subject: [PATCH v3 1/3] can: bcm: fix locking for bcm_op runtime updates
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260219-bcm_spin_lock_init-v3-1-c61026740d7b@hartkopp.net>
References: <20260219-bcm_spin_lock_init-v3-0-c61026740d7b@hartkopp.net>
In-Reply-To: <20260219-bcm_spin_lock_init-v3-0-c61026740d7b@hartkopp.net>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 "David S. Miller" <davem@davemloft.net>, 
 Urs Thuermann <urs.thuermann@volkswagen.de>, 
 Vincent Mailhol <mailhol@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 syzbot+5b11eccc403dd1cea9f8@syzkaller.appspotmail.com
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771519907; l=1553;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=XQu0DK6j8SlJ077Pj9O4qw1EtV49i3xT6l7+T5PUHaM=;
 b=ZffYcnzmkUyzxhttrdkJTF2yjTZSj9Njia7OwlRQeUSeM3XgkMKXvfl1kgQyd2XB3IRSXsq1z
 wcmIzFCjZJ7DX2uQiXhgyyVgMamm1kMxu0OSplfq4H9e/hXa9QRtVAx
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
 

-- 
2.51.0

