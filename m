From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Sat, 11 Jul 2026 14:07:16 +0200
Subject: [PATCH v7 5/5] can: isotp: fix state machine corruption on signal
 interruption
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-isotp-fixes-v7-5-f03af24d8397@hartkopp.net>
References: <20260711-isotp-fixes-v7-0-f03af24d8397@hartkopp.net>
In-Reply-To: <20260711-isotp-fixes-v7-0-f03af24d8397@hartkopp.net>
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783771634; l=1184;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=DD+TppSdrai1Iw0roPDDTFR1Usz3uK/bpVoyGPmzuq8=;
 b=jc7b3ezFetZsSxV17tdBKsIcC/KNxSgI3PMjVotmCc3AnrKh3pCWOgmD0EJEl5GxTlr5g31uu
 0PSPr8LD4qWC49zxlCIddVeU1cGiLkiveiCe4gyzRWJ9OH9arF+VOo7
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a thread blocked in isotp_sendmsg() waiting for a previous transfer
to finish is interrupted by a signal, jumping to the cleanup labels
incorrectly cancels active timers and forces 'so->tx.state' back to
ISOTP_IDLE. Since this thread never owned the active transmission, it
abruptly aborts another thread's legitimate transfer, so return the
interruption error directly.

Fixes: e057dd3fc20f ("can: add ISO 15765-2:2016 transport protocol")
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/can/isotp.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/can/isotp.c b/net/can/isotp.c
index fdb2109d7c27..c9cd78df3a6e 100644
--- a/net/can/isotp.c
+++ b/net/can/isotp.c
@@ -1017,11 +1017,11 @@ static int isotp_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 			return -EADDRNOTAVAIL;
 
 		/* wait for complete transmission of current pdu */
 		err = wait_event_interruptible(so->wait, so->tx.state == ISOTP_IDLE);
 		if (err)
-			goto err_event_drop;
+			return err;
 	}
 
 	/* new transfer: bump generation and drop any echo tag left behind
 	 * by a previously aborted transfer
 	 */

-- 
2.53.0

