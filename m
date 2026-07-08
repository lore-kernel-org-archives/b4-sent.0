From: Mattia Meleleo <mattia.meleleo@coralogix.com>
Date: Wed, 08 Jul 2026 18:55:00 +0200
Subject: [PATCH bpf v3 1/2] bpf, sockmap: Account for receive queue in
 FIONREAD without a verdict program
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-fionread-no-verdict-v3-1-b4ee31b3af53@coralogix.com>
References: <20260708-fionread-no-verdict-v3-0-b4ee31b3af53@coralogix.com>
In-Reply-To: <20260708-fionread-no-verdict-v3-0-b4ee31b3af53@coralogix.com>
To: bpf@vger.kernel.org
Cc: netdev@vger.kernel.org, John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Mattia Meleleo <mattia.meleleo@coralogix.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783529717; l=2719;
 i=mattia.meleleo@coralogix.com; s=20260707; h=from:subject:message-id;
 bh=D4N+tSAjoH5dTFG44WBAT8vqPF24z62Ilx+djNcKEFU=;
 b=kdQxIpc9JOu5p2KR8zM9Pg2YJWob7Jy1sjFSFyqmquvJCv+4EPgmvQPkP2n6yV9RP9v06wYUe
 2K66uyApw0mDoBFkuawFBayq6fDJIOfMZdFTKvgftik9hhcu8Ltb0AY
X-Developer-Key: i=mattia.meleleo@coralogix.com; a=ed25519;
 pk=cs1zLoe3YDm4bJ7bfbPaZH0lHnd871JyJLiSh2eEzLs=
X-Endpoint-Received: by B4 Relay for mattia.meleleo@coralogix.com/20260707 with auth_id=857
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tcp_bpf_ioctl() answers SIOCINQ from psock->msg_tot_len, which only
counts bytes in ingress_msg. Without a stream/skb verdict program
nothing is diverted there: data stays in sk_receive_queue, so FIONREAD
returns 0 even though read() returns data.

Add tcp_inq() to the reported value when the psock has no verdict
program. The two queues are disjoint, so bytes redirected into
ingress_msg from other sockets stay correctly accounted through
msg_tot_len.

Remove unused sk_psock_msg_inq().

Fixes: 929e30f93125 ("bpf, sockmap: Fix FIONREAD for sockmap")
Reviewed-by: Jiayuan Chen <jiayuan.chen@linux.dev>
Reviewed-by: Emil Tsalapatis <emil@etsalapatis.com>
Signed-off-by: Mattia Meleleo <mattia.meleleo@coralogix.com>
---
 include/linux/skmsg.h | 14 --------------
 net/ipv4/tcp_bpf.c    | 17 ++++++++++++++++-
 2 files changed, 16 insertions(+), 15 deletions(-)

diff --git a/include/linux/skmsg.h b/include/linux/skmsg.h
index a8553401b..d5e35f247 100644
--- a/include/linux/skmsg.h
+++ b/include/linux/skmsg.h
@@ -551,20 +551,6 @@ static inline void psock_progs_drop(struct sk_psock_progs *progs)
 	psock_set_prog(&progs->skb_verdict, NULL);
 }
 
-/* for tcp only, sk is locked */
-static inline ssize_t sk_psock_msg_inq(struct sock *sk)
-{
-	struct sk_psock *psock;
-	ssize_t inq = 0;
-
-	psock = sk_psock_get(sk);
-	if (likely(psock)) {
-		inq = sk_psock_get_msg_len_nolock(psock);
-		sk_psock_put(sk, psock);
-	}
-	return inq;
-}
-
 /* for udp only, sk is not locked */
 static inline ssize_t sk_msg_first_len(struct sock *sk)
 {
diff --git a/net/ipv4/tcp_bpf.c b/net/ipv4/tcp_bpf.c
index cc0bd73f3..8e905b50d 100644
--- a/net/ipv4/tcp_bpf.c
+++ b/net/ipv4/tcp_bpf.c
@@ -334,6 +334,7 @@ static int tcp_bpf_recvmsg_parser(struct sock *sk,
 
 static int tcp_bpf_ioctl(struct sock *sk, int cmd, int *karg)
 {
+	struct sk_psock *psock;
 	bool slow;
 
 	if (cmd != SIOCINQ)
@@ -344,7 +345,21 @@ static int tcp_bpf_ioctl(struct sock *sk, int cmd, int *karg)
 		return -EINVAL;
 
 	slow = lock_sock_fast(sk);
-	*karg = sk_psock_msg_inq(sk);
+	psock = sk_psock_get(sk);
+	if (unlikely(!psock)) {
+		unlock_sock_fast(sk, slow);
+		return tcp_ioctl(sk, cmd, karg);
+	}
+	*karg = sk_psock_get_msg_len_nolock(psock);
+	/* Without a verdict program, ingress data is never diverted to
+	 * ingress_msg: it stays in sk_receive_queue and is read through
+	 * the fallback to tcp_recvmsg(), so account for it like
+	 * tcp_ioctl() does.
+	 */
+	if (!READ_ONCE(psock->progs.stream_verdict) &&
+	    !READ_ONCE(psock->progs.skb_verdict))
+		*karg += tcp_inq(sk);
+	sk_psock_put(sk, psock);
 	unlock_sock_fast(sk, slow);
 
 	return 0;

-- 
Git-155)

