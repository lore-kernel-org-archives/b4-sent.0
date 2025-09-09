From: Dmitry Safonov <dima@arista.com>
Date: Tue, 09 Sep 2025 02:18:50 +0100
Subject: [PATCH net-next v5 1/2] tcp: Destroy TCP-AO, TCP-MD5 keys in
 .sk_destruct()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250909-b4-tcp-ao-md5-rst-finwait2-v5-1-9ffaaaf8b236@arista.com>
References: <20250909-b4-tcp-ao-md5-rst-finwait2-v5-0-9ffaaaf8b236@arista.com>
In-Reply-To: <20250909-b4-tcp-ao-md5-rst-finwait2-v5-0-9ffaaaf8b236@arista.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: Bob Gilligan <gilligan@arista.com>, 
 Salam Noureddine <noureddine@arista.com>, 
 Dmitry Safonov <0x7f454c46@gmail.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <dima@arista.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757380735; l=8638;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=hWpwcRqjOY2zJ4x0Cam0b3UkQlunGYPFXIDNlSMUmzM=;
 b=KjLb3wjGjYg2qlb8jwR1G3zIaCny19aAKcxEu2ql+tUrM2vk37cLCiQ1EDFa+4PHi2d/HsLPI
 kARV6D3oTueBck6ZbtyCP6IQiFB4vOfU4AZ07PTIxoWF6IIcBw9+Qz3
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently there are a couple of minor issues with destroying the keys
tcp_v4_destroy_sock():

1. The socket is yet in TCP bind buckets, making it reachable for
   incoming segments [on another CPU core], potentially available to send
   late FIN/ACK/RST replies.

2. There is at least one code path, where tcp_done() is called before
   sending RST [kudos to Bob for investigation]. This is a case of
   a server, that finished sending its data and just called close().

   The socket is in TCP_FIN_WAIT2 and has RCV_SHUTDOWN (set by
   __tcp_close())

   tcp_v4_do_rcv()/tcp_v6_do_rcv()
     tcp_rcv_state_process()            /* LINUX_MIB_TCPABORTONDATA */
       tcp_reset()
         tcp_done_with_error()
           tcp_done()
             inet_csk_destroy_sock()    /* Destroys AO/MD5 keys */
     /* tcp_rcv_state_process() returns SKB_DROP_REASON_TCP_ABORT_ON_DATA */
   tcp_v4_send_reset()                  /* Sends an unsigned RST segment */

   tcpdump:
> 22:53:15.399377 00:00:b2:1f:00:00 > 00:00:01:01:00:00, ethertype IPv4 (0x0800), length 74: (tos 0x0, ttl 64, id 33929, offset 0, flags [DF], proto TCP (6), length 60)
>     1.0.0.1.34567 > 1.0.0.2.49848: Flags [F.], seq 2185658590, ack 3969644355, win 502, options [nop,nop,md5 valid], length 0
> 22:53:15.399396 00:00:01:01:00:00 > 00:00:b2:1f:00:00, ethertype IPv4 (0x0800), length 86: (tos 0x0, ttl 64, id 51951, offset 0, flags [DF], proto TCP (6), length 72)
>     1.0.0.2.49848 > 1.0.0.1.34567: Flags [.], seq 3969644375, ack 2185658591, win 128, options [nop,nop,md5 valid,nop,nop,sack 1 {2185658590:2185658591}], length 0
> 22:53:16.429588 00:00:b2:1f:00:00 > 00:00:01:01:00:00, ethertype IPv4 (0x0800), length 60: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto TCP (6), length 40)
>     1.0.0.1.34567 > 1.0.0.2.49848: Flags [R], seq 2185658590, win 0, length 0
> 22:53:16.664725 00:00:b2:1f:00:00 > 00:00:01:01:00:00, ethertype IPv4 (0x0800), length 74: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto TCP (6), length 60)
>     1.0.0.1.34567 > 1.0.0.2.49848: Flags [R], seq 2185658591, win 0, options [nop,nop,md5 valid], length 0
> 22:53:17.289832 00:00:b2:1f:00:00 > 00:00:01:01:00:00, ethertype IPv4 (0x0800), length 74: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto TCP (6), length 60)
>     1.0.0.1.34567 > 1.0.0.2.49848: Flags [R], seq 2185658591, win 0, options [nop,nop,md5 valid], length 0

  Note the signed RSTs later in the dump - those are sent by the server
  when the fin-wait socket gets removed from hash buckets, by
  the listener socket.

Instead of destroying AO/MD5 info and their keys in inet_csk_destroy_sock(),
slightly delay it until the actual socket .sk_destruct(). As shutdown'ed
socket can yet send non-data replies, they should be signed in order for
the peer to process them. Now it also matches how AO/MD5 gets destructed
for TIME-WAIT sockets (in tcp_twsk_destructor()).

This seems optimal for TCP-MD5, while for TCP-AO it seems to have an
open problem: once RST get sent and socket gets actually destructed,
there is no information on the initial sequence numbers. So, in case
this last RST gets lost in the network, the server's listener socket
won't be able to properly sign another RST. Nothing in RFC 1122
prescribes keeping any local state after non-graceful reset.
Luckily, BGP are known to use keep alive(s).

While the issue is quite minor/cosmetic, these days monitoring network
counters is a common practice and getting invalid signed segments from
a trusted BGP peer can get customers worried.

Investigated-by: Bob Gilligan <gilligan@arista.com>
Reviewed-by: Eric Dumazet <edumazet@google.com>
Reviewed-by: Kuniyuki Iwashima <kuniyu@google.com>
Signed-off-by: Dmitry Safonov <dima@arista.com>
---
 include/net/tcp.h   |  4 ++++
 net/ipv4/tcp.c      | 27 +++++++++++++++++++++++++++
 net/ipv4/tcp_ipv4.c | 33 ++++++++-------------------------
 net/ipv6/tcp_ipv6.c |  8 ++++++++
 4 files changed, 47 insertions(+), 25 deletions(-)

diff --git a/include/net/tcp.h b/include/net/tcp.h
index 0fb7923b8367d7733f22bdb48add75a81dccc2ea..277914c4d067a83c958af00028cccb46956c693e 100644
--- a/include/net/tcp.h
+++ b/include/net/tcp.h
@@ -1941,6 +1941,7 @@ tcp_md5_do_lookup_any_l3index(const struct sock *sk,
 }
 
 #define tcp_twsk_md5_key(twsk)	((twsk)->tw_md5_key)
+void tcp_md5_destruct_sock(struct sock *sk);
 #else
 static inline struct tcp_md5sig_key *
 tcp_md5_do_lookup(const struct sock *sk, int l3index,
@@ -1957,6 +1958,9 @@ tcp_md5_do_lookup_any_l3index(const struct sock *sk,
 }
 
 #define tcp_twsk_md5_key(twsk)	NULL
+static inline void tcp_md5_destruct_sock(struct sock *sk)
+{
+}
 #endif
 
 int tcp_md5_alloc_sigpool(void);
diff --git a/net/ipv4/tcp.c b/net/ipv4/tcp.c
index 588932c3cf1d549973ccfa095a8de1be87421a63..adf5e1e8ffef69391318f2af0b3ea221eaa4afab 100644
--- a/net/ipv4/tcp.c
+++ b/net/ipv4/tcp.c
@@ -412,6 +412,33 @@ static u64 tcp_compute_delivery_rate(const struct tcp_sock *tp)
 	return rate64;
 }
 
+#ifdef CONFIG_TCP_MD5SIG
+static void tcp_md5sig_info_free_rcu(struct rcu_head *head)
+{
+	struct tcp_md5sig_info *md5sig;
+
+	md5sig = container_of(head, struct tcp_md5sig_info, rcu);
+	kfree(md5sig);
+	static_branch_slow_dec_deferred(&tcp_md5_needed);
+	tcp_md5_release_sigpool();
+}
+
+void tcp_md5_destruct_sock(struct sock *sk)
+{
+	struct tcp_sock *tp = tcp_sk(sk);
+
+	if (tp->md5sig_info) {
+		struct tcp_md5sig_info *md5sig;
+
+		md5sig = rcu_dereference_protected(tp->md5sig_info, 1);
+		tcp_clear_md5_list(sk);
+		rcu_assign_pointer(tp->md5sig_info, NULL);
+		call_rcu(&md5sig->rcu, tcp_md5sig_info_free_rcu);
+	}
+}
+EXPORT_IPV6_MOD_GPL(tcp_md5_destruct_sock);
+#endif
+
 /* Address-family independent initialization for a tcp_sock.
  *
  * NOTE: A lot of things set to zero explicitly by call to
diff --git a/net/ipv4/tcp_ipv4.c b/net/ipv4/tcp_ipv4.c
index 1e58a8a9ff7ae373c1e5ff11d3ec687f0fa744dc..17176a5d8638d5850898000db41bb123eff86857 100644
--- a/net/ipv4/tcp_ipv4.c
+++ b/net/ipv4/tcp_ipv4.c
@@ -2494,6 +2494,13 @@ static const struct tcp_sock_af_ops tcp_sock_ipv4_specific = {
 	.ao_calc_key_sk		= tcp_v4_ao_calc_key_sk,
 #endif
 };
+
+static void tcp4_destruct_sock(struct sock *sk)
+{
+	tcp_md5_destruct_sock(sk);
+	tcp_ao_destroy_sock(sk, false);
+	inet_sock_destruct(sk);
+}
 #endif
 
 /* NOTE: A lot of things set to zero explicitly by call to
@@ -2509,23 +2516,12 @@ static int tcp_v4_init_sock(struct sock *sk)
 
 #if defined(CONFIG_TCP_MD5SIG) || defined(CONFIG_TCP_AO)
 	tcp_sk(sk)->af_specific = &tcp_sock_ipv4_specific;
+	sk->sk_destruct = tcp4_destruct_sock;
 #endif
 
 	return 0;
 }
 
-#ifdef CONFIG_TCP_MD5SIG
-static void tcp_md5sig_info_free_rcu(struct rcu_head *head)
-{
-	struct tcp_md5sig_info *md5sig;
-
-	md5sig = container_of(head, struct tcp_md5sig_info, rcu);
-	kfree(md5sig);
-	static_branch_slow_dec_deferred(&tcp_md5_needed);
-	tcp_md5_release_sigpool();
-}
-#endif
-
 static void tcp_release_user_frags(struct sock *sk)
 {
 #ifdef CONFIG_PAGE_POOL
@@ -2562,19 +2558,6 @@ void tcp_v4_destroy_sock(struct sock *sk)
 	/* Cleans up our, hopefully empty, out_of_order_queue. */
 	skb_rbtree_purge(&tp->out_of_order_queue);
 
-#ifdef CONFIG_TCP_MD5SIG
-	/* Clean up the MD5 key list, if any */
-	if (tp->md5sig_info) {
-		struct tcp_md5sig_info *md5sig;
-
-		md5sig = rcu_dereference_protected(tp->md5sig_info, 1);
-		tcp_clear_md5_list(sk);
-		call_rcu(&md5sig->rcu, tcp_md5sig_info_free_rcu);
-		rcu_assign_pointer(tp->md5sig_info, NULL);
-	}
-#endif
-	tcp_ao_destroy_sock(sk, false);
-
 	/* Clean up a referenced TCP bind bucket. */
 	if (inet_csk(sk)->icsk_bind_hash)
 		inet_put_port(sk);
diff --git a/net/ipv6/tcp_ipv6.c b/net/ipv6/tcp_ipv6.c
index 0562e939b2e316711004ce7d0da34ca249888746..08dabc47a6e7334b89b306af3a1e1c89c9935bb6 100644
--- a/net/ipv6/tcp_ipv6.c
+++ b/net/ipv6/tcp_ipv6.c
@@ -2110,6 +2110,13 @@ static const struct tcp_sock_af_ops tcp_sock_ipv6_mapped_specific = {
 	.ao_calc_key_sk	=	tcp_v4_ao_calc_key_sk,
 #endif
 };
+
+static void tcp6_destruct_sock(struct sock *sk)
+{
+	tcp_md5_destruct_sock(sk);
+	tcp_ao_destroy_sock(sk, false);
+	inet6_sock_destruct(sk);
+}
 #endif
 
 /* NOTE: A lot of things set to zero explicitly by call to
@@ -2125,6 +2132,7 @@ static int tcp_v6_init_sock(struct sock *sk)
 
 #if defined(CONFIG_TCP_MD5SIG) || defined(CONFIG_TCP_AO)
 	tcp_sk(sk)->af_specific = &tcp_sock_ipv6_specific;
+	sk->sk_destruct = tcp6_destruct_sock;
 #endif
 
 	return 0;

-- 
2.42.2

