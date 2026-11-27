MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-unix-atmark2-v1-1-d164028cdae7@certik.com>
X-B4-Tracking: v=1; b=H4sIACToCWsC/yWMSw7CMAwFr1J5jaUmoiC4CmLhJC41nwTFKapU9
 e4ksJzRe7OCchZWOHcrZP6ISooVzK4DP1G8MUqoDLa3B2PsEecoC1J5UX5YtMEMPPT70dIJ6uW
 deZTll7tA5ALXv9TZ3dmXFmozR8roMkU/NaUcQ0npic3Dtn0BLmo985UAAAA=
X-Change-ID: 20261127-unix-atmark2-2d15e504f2a9
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 16:04:41 +0000
Subject: [PATCH net] af_unix: return 0 for SIOCATMARK on listeners
To: netdev@vger.kernel.org
Cc: Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Willem de Bruijn <willemb@google.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811364; l=2688;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=6FClBD8KxA1vZvrrT75+LOHaN5SjejVjVPoreOXqzTo=;
 b=XULMB6I44C976PZ/a15uKmebkiYhMf3vqE/y3H1mNhgz94oVsQLGr4AcromAFKhmPLQl5pCzo
 xHSoob5ok9cC9t/TC4gMx3KzkrL6FfCryIDMz7eu9YFi9D6ryxmuB+1
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

AF_UNIX listeners cannot receive out-of-band data, but SIOCATMARK
currently peeks at sk_receive_queue.  That queue contains connection
requests, and unix_accept() can dequeue and free its head under
sk_receive_queue.lock without taking u->iolock.  As a result, SIOCATMARK
can read the freed skb.

Take u->iolock and the state lock in stream receive order.  Return 0
for TCP_LISTEN, and keep both locks over the receive-queue inspection.
This prevents a concurrent listen() transition between the state check
and the queue access.

Fixes: e400cfa38bb0 ("af_unix: Fix wrong ioctl(SIOCATMARK) when consumed OOB skb is at the head.")
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This is the listener case left after d119775f2bad ("af_unix: Reject
SIOCATMARK on non-stream sockets"). The earlier queue-lock proposal
for the same lifetime problem was redirected toward rejecting
unsupported sockets:
https://lore.kernel.org/netdev/f6cbbc8da90e95584847b5ceb60aae830d1631c2.1775731983.git.wangjiexun2025@gmail.com/

net-next 387f48167305 ("af_unix: Remove MSG_OOB.") removes SIOCATMARK
along with AF_UNIX OOB, so this is only for net and stable.

Tested under UML with KASAN as uid 65534 with no capabilities: one
thread loops SIOCATMARK on a listener while others connect and accept.
Stock 7.3.6 and a mainline snapshot hit a slab-use-after-free in
unix_ioctl() (freed by unix_accept()) within 30-45 s, as does the patch
reverted. With the patch, 300 s runs (about 24M ioctls and 36k accepts
on 7.3.6) were clean. A second test races listen() against SIOCATMARK
on the same socket: 20/20 clean. tools/testing/selftests/net/af_unix
msg_oob passed 60/60. A reproducer is available if it helps.

This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

 net/unix/af_unix.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/net/unix/af_unix.c b/net/unix/af_unix.c
index 91c1d6cad497..1ba12617d55a 100644
--- a/net/unix/af_unix.c
+++ b/net/unix/af_unix.c
@@ -3344,6 +3344,10 @@ static int unix_ioctl(struct socket *sock, unsigned int cmd, unsigned long arg)
 				return -EOPNOTSUPP;
 
 			mutex_lock(&u->iolock);
+			unix_state_lock(sk);
+
+			if (sk->sk_state == TCP_LISTEN)
+				goto out_unlock;
 
 			skb = skb_peek(&sk->sk_receive_queue);
 			if (skb) {
@@ -3358,6 +3362,8 @@ static int unix_ioctl(struct socket *sock, unsigned int cmd, unsigned long arg)
 					answ = 1;
 			}
 
+out_unlock:
+			unix_state_unlock(sk);
 			mutex_unlock(&u->iolock);
 
 			err = put_user(answ, (int __user *)arg);
-- 
2.43.0

