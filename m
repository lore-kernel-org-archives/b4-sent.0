From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Sun, 12 Jul 2026 15:44:08 +0200
Subject: [PATCH v9 4/4] can: isotp: fix state machine corruption on signal
 interruption
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260712-isotp-fixes-v9-4-137840d7f0f4@hartkopp.net>
References: <20260712-isotp-fixes-v9-0-137840d7f0f4@hartkopp.net>
In-Reply-To: <20260712-isotp-fixes-v9-0-137840d7f0f4@hartkopp.net>
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783863845; l=1269;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=pr0FYrc5dBkkqbDmu8I+qeB4zl8MV6JSiRwmhz8cpRM=;
 b=F80SS06/98NmLno1nmfJXjWljKnI0nwa72BG8TZHWoGLtoW6HIu0L2lVNeQb3gQSzZjPAxK5u
 G+PmtB4mG7/B/tDCSIdxJm7xyJXEAyuGMHp1t88digrc7nBklDCW/6q
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
index c4ca8a64e7ce..56618ea1dae4 100644
--- a/net/can/isotp.c
+++ b/net/can/isotp.c
@@ -1045,11 +1045,11 @@ static int isotp_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 			return -EADDRNOTAVAIL;
 
 		/* wait for complete transmission of current pdu */
 		err = wait_event_interruptible(so->wait, so->tx.state == ISOTP_IDLE);
 		if (err)
-			goto err_event_drop;
+			return err;
 	}
 
 	/* new transfer: bump the generation (gen is used below and by
 	 * isotp_tx_timeout()/isotp_rcv_echo()) and drain the old one -
 	 * cancel its timers ourselves in case one is still concurrently

-- 
2.53.0

