From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Fri, 10 Jul 2026 22:42:56 +0200
Subject: [PATCH v6 5/5] can: isotp: fix state machine corruption on signal
 interruption
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-isotp-fixes-v6-5-a13c2539093d@hartkopp.net>
References: <20260710-isotp-fixes-v6-0-a13c2539093d@hartkopp.net>
In-Reply-To: <20260710-isotp-fixes-v6-0-a13c2539093d@hartkopp.net>
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783716177; l=1200;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=2p7JZxAX2B/fsKZ/6/57Zl/38OVNATxgSBd43fNwAeE=;
 b=40+9Cshq2CIqBDmoXMPR0YAjTdoXcT2EUg9gERHLmmj0WPKXcYmAx7JLa5EdJtYFeVIG1FxRK
 lR3hj89F9nBB5T6YwzfKDWAkt57d3/10zCFVrl5lRsAAAlQh3zwhBI2
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
index 0826ae837246..b8562f8c6de0 100644
--- a/net/can/isotp.c
+++ b/net/can/isotp.c
@@ -1005,11 +1005,11 @@ static int isotp_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
 			return -EADDRNOTAVAIL;
 
 		/* wait for complete transmission of current pdu */
 		err = wait_event_interruptible(so->wait, so->tx.state == ISOTP_IDLE);
 		if (err)
-			goto err_event_drop;
+			return err;
 	}
 
 	/* so->bound is only checked once above - a wakeup may have
 	 * unbound/rebound the socket meanwhile, so re-validate it
 	 */

-- 
2.53.0

