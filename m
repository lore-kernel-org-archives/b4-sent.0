From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Thu, 06 Jun 2024 01:58:19 +0100
Subject: [PATCH net-next v3 2/6] net/tcp: Add a helper tcp_ao_hdr_maclen()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240606-tcp_ao-tracepoints-v3-2-13621988c09f@gmail.com>
References: <20240606-tcp_ao-tracepoints-v3-0-13621988c09f@gmail.com>
In-Reply-To: <20240606-tcp_ao-tracepoints-v3-0-13621988c09f@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717635508; l=1228;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=3r0GUti1sbRL2DmiJwhtJuQ4wZfREpceQasirqqFZEo=;
 b=CQ0LdFqzJrO1PgTov6mN9djdrLg5x4/LZXb466Qlyk6W8wybb7HWvhrWy3gUyCTv+g5jZQzDy/Ml
 mjcdbQsSDD66rdlUluNAiirWV6c98jWuyOKlRgWqRbMUdReXpkck
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's going to be used more in TCP-AO tracepoints.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 include/net/tcp_ao.h | 5 +++++
 net/ipv4/tcp_ao.c    | 2 +-
 2 files changed, 6 insertions(+), 1 deletion(-)

diff --git a/include/net/tcp_ao.h b/include/net/tcp_ao.h
index 471e177362b4..6501ed1dfa1e 100644
--- a/include/net/tcp_ao.h
+++ b/include/net/tcp_ao.h
@@ -19,6 +19,11 @@ struct tcp_ao_hdr {
 	u8	rnext_keyid;
 };
 
+static inline u8 tcp_ao_hdr_maclen(const struct tcp_ao_hdr *aoh)
+{
+	return aoh->length - sizeof(struct tcp_ao_hdr);
+}
+
 struct tcp_ao_counters {
 	atomic64_t	pkt_good;
 	atomic64_t	pkt_bad;
diff --git a/net/ipv4/tcp_ao.c b/net/ipv4/tcp_ao.c
index 781b67a52571..7c9e90e531e3 100644
--- a/net/ipv4/tcp_ao.c
+++ b/net/ipv4/tcp_ao.c
@@ -884,8 +884,8 @@ tcp_ao_verify_hash(const struct sock *sk, const struct sk_buff *skb,
 		   const struct tcp_ao_hdr *aoh, struct tcp_ao_key *key,
 		   u8 *traffic_key, u8 *phash, u32 sne, int l3index)
 {
-	u8 maclen = aoh->length - sizeof(struct tcp_ao_hdr);
 	const struct tcphdr *th = tcp_hdr(skb);
+	u8 maclen = tcp_ao_hdr_maclen(aoh);
 	void *hash_buf = NULL;
 
 	if (maclen != tcp_ao_maclen(key)) {

-- 
2.42.0

