From: Yongjian Wang <echoowall@gmail.com>
Date: Tue, 10 Nov 2026 00:44:35 +0800
Subject: [PATCH net-next v3 1/4] tcp: initialize MTU probing before syncing
 MSS at connection setup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-mtu-probing-series-v3-1-dedfab25d641@gmail.com>
References: <20261110-mtu-probing-series-v3-0-dedfab25d641@gmail.com>
In-Reply-To: <20261110-mtu-probing-series-v3-0-dedfab25d641@gmail.com>
To: davem@davemloft.net, edumazet@kernel.org, pabeni@redhat.com, 
 shuah@kernel.org, kuniyu@google.com, horms@kernel.org, ncardwell@google.com, 
 kuba@kernel.org
Cc: netdev@vger.kernel.org, panweiping3@gmail.com, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794242675; l=3191;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=dheRlUn7XAqkq1CdSHyUrNsJDtsi4JPPCVAWaWCPNZs=;
 b=vA4c2zdS27JqROPN10pJMy5VSqbgq2gP+93UQGmEPJfvwSqis580F4ytRmOMhK6iMVnhku4yU
 JMiQKa2HeG7C+FUTBHRK4SPirJqHg2OLNQUmqG6Lg4LaQkV7SyyysTf
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With tcp_mtu_probing=2, a passive connection starts at the full MSS
rather than tcp_base_mss. The IPv4 and IPv6 syn_recv_sock() paths
call tcp_sync_mss() before tcp_init_transfer() enables MTU probing.
With tcp_base_mss=1024, the first successful probe can therefore lower
the MSS from 1460 to 1242. On a black hole path, the first reduction
skips 1024 and goes straight to 512.

The issue surfaced while developing packetdrill coverage for MTU
probing and comparing the initial send MSS on active and passive
IPv4 connections.

Commit 4d83e1773031 ("tcp: delete redundant calls of tcp_mtup_init()")
removed tcp_mtup_init() from the passive setup paths.
Commit 27204aaa9dc6
("tcp: uniform the set up of sockets after successful connection")
later moved MTU probing initialization into tcp_init_transfer(),
away from tcp_sync_mss().

Initialize MTU probing immediately before the existing tcp_sync_mss()
calls in the IPv4 and IPv6 passive setup paths and when processing
a SYN-ACK for an active connection. Remove the late initialization
from tcp_init_transfer(). This lets tcp_sync_mss() apply tcp_base_mss
without adding another MSS calculation to connection setup. The
crossed-SYN path already uses this order.

Fixes: 4d83e1773031 ("tcp: delete redundant calls of tcp_mtup_init()")
Suggested-by: Kuniyuki Iwashima <kuniyu@google.com>
Suggested-by: Neal Cardwell <ncardwell@google.com>
Signed-off-by: Yongjian Wang <echoowall@gmail.com>
---
 net/ipv4/tcp_input.c | 2 +-
 net/ipv4/tcp_ipv4.c  | 1 +
 net/ipv6/tcp_ipv6.c  | 1 +
 3 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/net/ipv4/tcp_input.c b/net/ipv4/tcp_input.c
index 3fd0e215324d..2b54b99f1f45 100644
--- a/net/ipv4/tcp_input.c
+++ b/net/ipv4/tcp_input.c
@@ -6763,7 +6763,6 @@ void tcp_init_transfer(struct sock *sk, int bpf_op, struct sk_buff *skb)
 	struct inet_connection_sock *icsk = inet_csk(sk);
 	struct tcp_sock *tp = tcp_sk(sk);
 
-	tcp_mtup_init(sk);
 	icsk->icsk_af_ops->rebuild_header(sk);
 	tcp_init_metrics(sk);
 
@@ -7020,6 +7019,7 @@ static int tcp_rcv_synsent_state_process(struct sock *sk, struct sk_buff *skb,
 			tp->tcp_header_len = sizeof(struct tcphdr);
 		}
 
+		tcp_mtup_init(sk);
 		tcp_sync_mss(sk, icsk->icsk_pmtu_cookie);
 		tcp_initialize_rcv_mss(sk);
 
diff --git a/net/ipv4/tcp_ipv4.c b/net/ipv4/tcp_ipv4.c
index 0dc3b087665d..fb968798be36 100644
--- a/net/ipv4/tcp_ipv4.c
+++ b/net/ipv4/tcp_ipv4.c
@@ -1740,6 +1740,7 @@ struct sock *tcp_v4_syn_recv_sock(const struct sock *sk, struct sk_buff *skb,
 
 	tcp_ca_openreq_child(newsk, dst);
 
+	tcp_mtup_init(newsk);
 	tcp_sync_mss(newsk, dst4_mtu(dst));
 	newtp->advmss = tcp_mss_clamp(tcp_sk(sk), tcp_dst_advmss(dst));
 
diff --git a/net/ipv6/tcp_ipv6.c b/net/ipv6/tcp_ipv6.c
index b1dec5d86d63..8ea1ae1ad2b2 100644
--- a/net/ipv6/tcp_ipv6.c
+++ b/net/ipv6/tcp_ipv6.c
@@ -1490,6 +1490,7 @@ static struct sock *tcp_v6_syn_recv_sock(const struct sock *sk, struct sk_buff *
 
 	tcp_ca_openreq_child(newsk, dst);
 
+	tcp_mtup_init(newsk);
 	tcp_sync_mss(newsk, dst6_mtu(dst));
 	newtp->advmss = tcp_mss_clamp(tcp_sk(sk), tcp_dst_advmss(dst));
 

-- 
Git-157)

