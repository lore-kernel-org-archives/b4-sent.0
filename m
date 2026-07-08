From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Wed, 08 Jul 2026 17:21:20 +0200
Subject: [PATCH v7 10/10] can: bcm: fix data race on rx_stamp/rx_ifindex in
 bcm_rx_handler()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-bcm_fixes-v7-10-c78896b342e4@hartkopp.net>
References: <20260708-bcm_fixes-v7-0-c78896b342e4@hartkopp.net>
In-Reply-To: <20260708-bcm_fixes-v7-0-c78896b342e4@hartkopp.net>
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783524080; l=2476;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=sgVH96QIfOXVRa0hhaKMBTVl/5GH1ShINKeQ7Z6cI1o=;
 b=5JpWaAM+QXFXmNB6/Q1/BaLPzOyDPJkqFxl5gx2GTH2CA6yQzLJ7oV47n2OZI/Fft1CXNl8zy
 /HXhuxCuPyFBbzAv7mC/3tPBdKkTodzp51YW9YVb2GNVEL1fMv7wEyU
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For an rx op subscribed on all interfaces (ifindex == 0), the same op
is registered once in the shared per-netns wildcard filter list, so
bcm_rx_handler() can run concurrently on different CPUs for frames
arriving on different net devices.

op->rx_stamp and op->rx_ifindex were written before bcm_rx_update_lock was
taken, allowing concurrent writers to race each other - including a torn
store of the 64-bit rx_stamp on 32-bit platforms.

Beyond a torn store bcm_send_to_user() must report the timestamp/ifindex
of the very same frame whose content it is delivering. So the assignment
is placed in the same unbroken bcm_rx_update_lock section as the content
comparison.

As a side effect, the RTR-request frame feature (which never reach
bcm_send_to_user()) no longer updates rx_stamp/rx_ifindex, since only
the notification path needs them.

Fixes: ffd980f976e7 ("[CAN]: Add broadcast manager (bcm) protocol")
Reported-by: sashiko-bot@kernel.org
Link: https://lore.kernel.org/linux-can/20260707145135.5BC831F00A3A@smtp.kernel.org/
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/bcm.c | 13 ++++++++-----
 1 file changed, 8 insertions(+), 5 deletions(-)

diff --git a/net/can/bcm.c b/net/can/bcm.c
index 9d0193170808..5591a0aed152 100644
--- a/net/can/bcm.c
+++ b/net/can/bcm.c
@@ -768,15 +768,10 @@ static void bcm_rx_handler(struct sk_buff *skb, void *data)
 	}
 
 	/* disable timeout */
 	hrtimer_cancel(&op->timer);
 
-	/* save rx timestamp */
-	op->rx_stamp = skb->tstamp;
-	/* save originator for recvfrom() */
-	op->rx_ifindex = skb->dev->ifindex;
-
 	/* snapshot RTR content under lock: op->flags/op->frames may be
 	 * updated concurrently by bcm_rx_setup().
 	 */
 	spin_lock_bh(&op->bcm_rx_update_lock);
 
@@ -803,10 +798,18 @@ static void bcm_rx_handler(struct sk_buff *skb, void *data)
 			traffic_flags |= RX_OWN;
 	}
 
 	spin_lock_bh(&op->bcm_rx_update_lock);
 
+	/* save rx timestamp and originator for recvfrom() under lock.
+	 * For an op subscribed on all interfaces (ifindex == 0)
+	 * bcm_rx_handler() can run concurrently on different CPUs so
+	 * the CAN content and the meta data must be bundled correctly.
+	 */
+	op->rx_stamp = skb->tstamp;
+	op->rx_ifindex = skb->dev->ifindex;
+
 	if (op->flags & RX_FILTER_ID) {
 		/* the easiest case */
 		bcm_rx_update_and_send(op, op->last_frames, rxframe,
 				       traffic_flags);
 		goto rx_starttimer;

-- 
2.53.0

