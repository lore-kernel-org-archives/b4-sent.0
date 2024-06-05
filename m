From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 05 Jun 2024 03:20:02 +0100
Subject: [PATCH net-next v2 1/6] net/tcp: Use static_branch_tcp_{md5,ao} to
 drop ifdefs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240605-tcp_ao-tracepoints-v2-1-e91e161282ef@gmail.com>
References: <20240605-tcp_ao-tracepoints-v2-0-e91e161282ef@gmail.com>
In-Reply-To: <20240605-tcp_ao-tracepoints-v2-0-e91e161282ef@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, David Ahern <dsahern@kernel.org>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, Simon Horman <horms@kernel.org>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717554029; l=2385;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=vprIUxoXS6O+nQsZYJ0TnN8AY1IxVix3tPSqfwEiZ4I=;
 b=vKqtpyxvZrc7sKLEyhxdDFQVM+OvC7W9pmwXl9I+h5yYG9H4K8nOFcJf4eG4CPPWPJUjb22sbl2L
 r/7fpIdMBtXDXjHKSj60A4AvgZtm6FrU5cpHi7h+DqBsCtSeg51M
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's possible to clean-up some ifdefs by hiding that
tcp_{md5,ao}_needed static branch is defined and compiled only
under related configs, since commit 4c8530dc7d7d ("net/tcp: Only produce
AO/MD5 logs if there are any keys").

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 include/net/tcp.h   | 14 ++++----------
 net/ipv4/tcp_ipv4.c |  8 ++------
 2 files changed, 6 insertions(+), 16 deletions(-)

diff --git a/include/net/tcp.h b/include/net/tcp.h
index 08c3b99501cf..f6dd035e0fa9 100644
--- a/include/net/tcp.h
+++ b/include/net/tcp.h
@@ -2386,21 +2386,15 @@ static inline void tcp_get_current_key(const struct sock *sk,
 
 static inline bool tcp_key_is_md5(const struct tcp_key *key)
 {
-#ifdef CONFIG_TCP_MD5SIG
-	if (static_branch_unlikely(&tcp_md5_needed.key) &&
-	    key->type == TCP_KEY_MD5)
-		return true;
-#endif
+	if (static_branch_tcp_md5())
+		return key->type == TCP_KEY_MD5;
 	return false;
 }
 
 static inline bool tcp_key_is_ao(const struct tcp_key *key)
 {
-#ifdef CONFIG_TCP_AO
-	if (static_branch_unlikely(&tcp_ao_needed.key) &&
-	    key->type == TCP_KEY_AO)
-		return true;
-#endif
+	if (static_branch_tcp_ao())
+		return key->type == TCP_KEY_AO;
 	return false;
 }
 
diff --git a/net/ipv4/tcp_ipv4.c b/net/ipv4/tcp_ipv4.c
index 04044605cadf..59c252b90b55 100644
--- a/net/ipv4/tcp_ipv4.c
+++ b/net/ipv4/tcp_ipv4.c
@@ -1052,12 +1052,10 @@ static void tcp_v4_timewait_ack(struct sock *sk, struct sk_buff *skb)
 #else
 	if (0) {
 #endif
-#ifdef CONFIG_TCP_MD5SIG
-	} else if (static_branch_unlikely(&tcp_md5_needed.key)) {
+	} else if (static_branch_tcp_md5()) {
 		key.md5_key = tcp_twsk_md5_key(tcptw);
 		if (key.md5_key)
 			key.type = TCP_KEY_MD5;
-#endif
 	}
 
 	tcp_v4_send_ack(sk, skb,
@@ -1126,8 +1124,7 @@ static void tcp_v4_reqsk_send_ack(const struct sock *sk, struct sk_buff *skb,
 #else
 	if (0) {
 #endif
-#ifdef CONFIG_TCP_MD5SIG
-	} else if (static_branch_unlikely(&tcp_md5_needed.key)) {
+	} else if (static_branch_tcp_md5()) {
 		const union tcp_md5_addr *addr;
 		int l3index;
 
@@ -1136,7 +1133,6 @@ static void tcp_v4_reqsk_send_ack(const struct sock *sk, struct sk_buff *skb,
 		key.md5_key = tcp_md5_do_lookup(sk, l3index, addr, AF_INET);
 		if (key.md5_key)
 			key.type = TCP_KEY_MD5;
-#endif
 	}
 
 	tcp_v4_send_ack(sk, skb, seq,

-- 
2.42.0

