From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 13 Nov 2024 18:46:40 +0000
Subject: [PATCH net v2 1/5] net/diag: Do not race on dumping MD5 keys with
 adding new MD5 keys
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241113-tcp-md5-diag-prep-v2-1-00a2a7feb1fa@gmail.com>
References: <20241113-tcp-md5-diag-prep-v2-0-00a2a7feb1fa@gmail.com>
In-Reply-To: <20241113-tcp-md5-diag-prep-v2-0-00a2a7feb1fa@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 David Ahern <dsahern@kernel.org>, Ivan Delalande <colona@arista.com>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>, Boris Pismenny <borisp@nvidia.com>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Davide Caratti <dcaratti@redhat.com>, Kuniyuki Iwashima <kuniyu@amazon.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mptcp@lists.linux.dev, Dmitry Safonov <0x7f454c46@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731523626; l=7962;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=U8sITNLHEQYHGDJjLLm7TVFLT0p4xM9cgVSE67g9KWU=;
 b=X+pUajfV2uxiu98GmQaUKHT+xArrbPSMbdFXGstwhYNeWIqPfDXwYnPcS32B3i4AZfZTOV48w
 rkTKvpRyXLqABPWvuprCO7bdX+pGFGyjUAb3aXQw2LZv8j/M533A3cy
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inet-diag has two modes: (1) dumping information for a specific socket,
for which kernel creates one netlink message with the information and
(2) dumping information for multiple sockets (possibly with a filter),
where for the reply kernel sends many messages, one for each matched
socket.

Currently those two modes work differently as the information about
a specific socket is never split between multiple messages. For (2),
multi-socket dump for the reply kernel allocates up to 32Kb skb and
fills that with as many socket dumps as possible. For (1), one-socket
dump kernel pre-calculates the required space for the reply, allocates
a new skb and nlmsg and only then starts filling the socket's details.

Preallocating the needed size quite makes sense as most of the details
are fix-sized and provided for each socket, see inet_sk_attr_size().
But there's an exception: .idiag_get_aux_size() which is optional for
a socket. This is provided only for TCP sockets by tcp_diag.

For TCP-MD5 it calculates the memory needed to fill an array of
(struct tcp_diag_md5sig). The issue here is that the amount of keys may
change in inet_diag_dump_one_icsk() between inet_sk_attr_size() and
sk_diag_fill() calls. As the code expects fix-sized information on any
socket, it considers sk_diag_fill() failures by -EMSGSIZE reason as
a bug, resulting in such WARN_ON():

[] ------------[ cut here ]------------
[] WARNING: CPU: 7 PID: 17420 at net/ipv4/inet_diag.c:586 inet_diag_dump_one_icsk+0x3c8/0x420
[] CPU: 7 UID: 0 PID: 17420 Comm: diag_ipv4 Tainted: G        W          6.11.0-rc6-00022-gc9fd7a9f9aca-dirty #2
[] pc : inet_diag_dump_one_icsk+0x3c8/0x420
[] lr : inet_diag_dump_one_icsk+0x1d4/0x420
[] sp : ffff8000aef87460
...
[] Call trace:
[]  inet_diag_dump_one_icsk+0x3c8/0x420
[]  tcp_diag_dump_one+0xa0/0xf0
[]  inet_diag_cmd_exact+0x234/0x278
[]  inet_diag_handler_cmd+0x16c/0x288
[]  sock_diag_rcv_msg+0x1a8/0x550
[]  netlink_rcv_skb+0x198/0x378
[]  sock_diag_rcv+0x20/0x48
[]  netlink_unicast+0x400/0x6a8
[]  netlink_sendmsg+0x654/0xa58
[]  __sys_sendto+0x1ec/0x330
[]  __arm64_sys_sendto+0xc8/0x168
...
[] ---[ end trace 0000000000000000 ]---

One way to solve it would be to grab lock_sock() in
inet_diag_dump_one_icsk(), but that may be costly and bring new lock
dependencies. The alternative is to call tcp_diag_put_md5sig() as
the last attribute of the netlink message and calculate how much space
left after all previous attributes filled and translate it into
(struct tcp_diag_md5sig)-sized units. If it turns out that there's not
enough space for all TCP-MD5 keys, mark the dump as inconsistent by
setting NLM_F_DUMP_INTR flag. Userspace may figure out that dumping
raced with the socket properties change and retry again.

Currently it may be unexpected by userspace that netlink message for one
socket may be inconsistent, but I believe we're on a safe side from
breaking userspace as previously dump would fail and an ugly WARN was
produced in dmesg. IOW, it is a clear improvement.

This is not a theoretical issue: I've written a test and that reproduces
the issue I suspected (the backtrace above).

Fixes: c03fa9bcacd9 ("tcp_diag: report TCP MD5 signing keys and addresses")
Cc: stable@vger.kernel.org
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 include/linux/inet_diag.h |  3 ++-
 net/ipv4/inet_diag.c      |  8 +++----
 net/ipv4/tcp_diag.c       | 55 ++++++++++++++++++++++++++++-------------------
 3 files changed, 39 insertions(+), 27 deletions(-)

diff --git a/include/linux/inet_diag.h b/include/linux/inet_diag.h
index a9033696b0aad36ab9abd47e4b68e272053019d7..cb2ba672eba131986d0432dd628fc42bbf800886 100644
--- a/include/linux/inet_diag.h
+++ b/include/linux/inet_diag.h
@@ -22,7 +22,8 @@ struct inet_diag_handler {
 
 	int		(*idiag_get_aux)(struct sock *sk,
 					 bool net_admin,
-					 struct sk_buff *skb);
+					 struct sk_buff *skb,
+					 struct nlmsghdr *nlh);
 
 	size_t		(*idiag_get_aux_size)(struct sock *sk,
 					      bool net_admin);
diff --git a/net/ipv4/inet_diag.c b/net/ipv4/inet_diag.c
index 67639309163d05c034fad80fc9a6096c3b79d42f..67b9cc4c0e47a596a4d588e793b7f13ee040a1e3 100644
--- a/net/ipv4/inet_diag.c
+++ b/net/ipv4/inet_diag.c
@@ -350,10 +350,6 @@ int inet_sk_diag_fill(struct sock *sk, struct inet_connection_sock *icsk,
 
 	handler->idiag_get_info(sk, r, info);
 
-	if (ext & (1 << (INET_DIAG_INFO - 1)) && handler->idiag_get_aux)
-		if (handler->idiag_get_aux(sk, net_admin, skb) < 0)
-			goto errout;
-
 	if (sk->sk_state < TCP_TIME_WAIT) {
 		union tcp_cc_info info;
 		size_t sz = 0;
@@ -368,6 +364,10 @@ int inet_sk_diag_fill(struct sock *sk, struct inet_connection_sock *icsk,
 			goto errout;
 	}
 
+	if (ext & (1 << (INET_DIAG_INFO - 1)) && handler->idiag_get_aux)
+		if (handler->idiag_get_aux(sk, net_admin, skb, nlh) < 0)
+			goto errout;
+
 	/* Keep it at the end for potential retry with a larger skb,
 	 * or else do best-effort fitting, which is only done for the
 	 * first_nlmsg.
diff --git a/net/ipv4/tcp_diag.c b/net/ipv4/tcp_diag.c
index f428ecf9120f2f596e1d67db2b2a0d0d0e211905..d752dc5de3536303aeb075c10fbdc2c9fc417cd5 100644
--- a/net/ipv4/tcp_diag.c
+++ b/net/ipv4/tcp_diag.c
@@ -53,29 +53,39 @@ static void tcp_diag_md5sig_fill(struct tcp_diag_md5sig *info,
 }
 
 static int tcp_diag_put_md5sig(struct sk_buff *skb,
-			       const struct tcp_md5sig_info *md5sig)
+			       const struct tcp_md5sig_info *md5sig,
+			       struct nlmsghdr *nlh)
 {
+	size_t key_size = sizeof(struct tcp_diag_md5sig);
+	unsigned int attrlen, md5sig_count = 0;
 	const struct tcp_md5sig_key *key;
 	struct tcp_diag_md5sig *info;
 	struct nlattr *attr;
-	int md5sig_count = 0;
 
+	/*
+	 * Userspace doesn't like to see zero-filled key-values, so
+	 * allocating too large attribute is bad.
+	 */
 	hlist_for_each_entry_rcu(key, &md5sig->head, node)
 		md5sig_count++;
 	if (md5sig_count == 0)
 		return 0;
 
-	attr = nla_reserve(skb, INET_DIAG_MD5SIG,
-			   md5sig_count * sizeof(struct tcp_diag_md5sig));
+	attrlen = skb_availroom(skb) - NLA_HDRLEN;
+	md5sig_count = min(md5sig_count, attrlen / key_size);
+	attr = nla_reserve(skb, INET_DIAG_MD5SIG, md5sig_count * key_size);
 	if (!attr)
 		return -EMSGSIZE;
 
 	info = nla_data(attr);
-	memset(info, 0, md5sig_count * sizeof(struct tcp_diag_md5sig));
+	memset(info, 0, md5sig_count * key_size);
 	hlist_for_each_entry_rcu(key, &md5sig->head, node) {
-		tcp_diag_md5sig_fill(info++, key);
-		if (--md5sig_count == 0)
+		/* More keys on a socket than pre-allocated space available */
+		if (md5sig_count-- == 0) {
+			nlh->nlmsg_flags |= NLM_F_DUMP_INTR;
 			break;
+		}
+		tcp_diag_md5sig_fill(info++, key);
 	}
 
 	return 0;
@@ -110,25 +120,11 @@ static int tcp_diag_put_ulp(struct sk_buff *skb, struct sock *sk,
 }
 
 static int tcp_diag_get_aux(struct sock *sk, bool net_admin,
-			    struct sk_buff *skb)
+			    struct sk_buff *skb, struct nlmsghdr *nlh)
 {
 	struct inet_connection_sock *icsk = inet_csk(sk);
 	int err = 0;
 
-#ifdef CONFIG_TCP_MD5SIG
-	if (net_admin) {
-		struct tcp_md5sig_info *md5sig;
-
-		rcu_read_lock();
-		md5sig = rcu_dereference(tcp_sk(sk)->md5sig_info);
-		if (md5sig)
-			err = tcp_diag_put_md5sig(skb, md5sig);
-		rcu_read_unlock();
-		if (err < 0)
-			return err;
-	}
-#endif
-
 	if (net_admin) {
 		const struct tcp_ulp_ops *ulp_ops;
 
@@ -138,6 +134,21 @@ static int tcp_diag_get_aux(struct sock *sk, bool net_admin,
 		if (err)
 			return err;
 	}
+
+#ifdef CONFIG_TCP_MD5SIG
+	if (net_admin) {
+		struct tcp_md5sig_info *md5sig;
+
+		rcu_read_lock();
+		md5sig = rcu_dereference(tcp_sk(sk)->md5sig_info);
+		if (md5sig)
+			err = tcp_diag_put_md5sig(skb, md5sig, nlh);
+		rcu_read_unlock();
+		if (err < 0)
+			return err;
+	}
+#endif
+
 	return 0;
 }
 

-- 
2.42.2

