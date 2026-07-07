From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 07 Jul 2026 02:00:54 -0500
Subject: [PATCH net] net/iucv: fix use-after-free of a severed iucv_path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-b4-disp-783fedbb-v1-1-463b9dbda2ea@proton.me>
X-B4-Tracking: v=1; b=H4sIACWkTGoC/x3MQQqAIBBA0avErBtQi6yuEi0anWo2JhoRRHdPW
 r7F/w9kTsIZxuqBxJdkOUKBritw+xI2RvHFYJTplFUWqUUvOaLtm5U9ETYDOU00+JYVlCwmXuX
 +lxMEPmF+3w/87wdmZwAAAA==
To: Paolo Abeni <pabeni@redhat.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, Jakub Kicinski <kuba@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Eric Dumazet <edumazet@google.com>, "David S. Miller" <davem@davemloft.net>
Cc: linux-s390@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, Nagamani PV <nagamani@linux.ibm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783407653; l=2242;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=Vg8TCtIHTe8jw/nj6SI6vm1zcOrZY1kYN/Xv5b4uIJY=;
 b=yuG+VdpMhHEuqT4wu4JLiu4hiog3H9ZC0+OO7RR9aCidpeppZoRPBOOz3nDloMMxQ0y5X1gxy
 1nTouPPOxmWASwYR7y+IBROMpz4tx/Vwk2AjlWs3r/tXOFmGIj81LYg
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

af_iucv queues not-yet-received message notifications on iucv->message_q,
each holding a raw pointer to the connection's iucv_path.  When the peer
severs the connection, iucv_sever_path() frees that path with
iucv_path_free() but leaves the notifications queued.  A later recvmsg()
drains message_q via iucv_process_message_q() and hands the stale path to
message_receive() -- a use-after-free of the freed iucv_path.

Drop the queued notifications when the path is severed; once the path is
gone they can no longer be received.  This also frees the notifications
leaked when a socket is closed with messages still queued.

Fixes: f0703c80e515 ("[AF_IUCV]: postpone receival of iucv-packets")
Closes: https://sashiko.dev/#/patchset/20260705-b4-disp-fc79c0dc-v1-1-d2cdcb57afa9@proton.me?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/iucv/af_iucv.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index fed240b453bd..2869a103f7fa 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -337,6 +337,7 @@ static void iucv_sever_path(struct sock *sk, int with_user_data)
 	unsigned char user_data[16];
 	struct iucv_sock *iucv = iucv_sk(sk);
 	struct iucv_path *path = iucv->path;
+	struct sock_msg_q *p, *n;
 
 	/* Whoever resets the path pointer, must sever and free it. */
 	if (xchg(&iucv->path, NULL)) {
@@ -348,6 +349,19 @@ static void iucv_sever_path(struct sock *sk, int with_user_data)
 		} else
 			pr_iucv->path_sever(path, NULL);
 		iucv_path_free(path);
+
+		/*
+		 * Message notifications queued on message_q still reference
+		 * the now freed path; drop them, otherwise a later recvmsg()
+		 * would pass the freed iucv_path to message_receive() via
+		 * iucv_process_message_q().
+		 */
+		spin_lock_bh(&iucv->message_q.lock);
+		list_for_each_entry_safe(p, n, &iucv->message_q.list, list) {
+			list_del(&p->list);
+			kfree(p);
+		}
+		spin_unlock_bh(&iucv->message_q.lock);
 	}
 }
 

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260707-b4-disp-783fedbb-39bc1bb9d4e0

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

