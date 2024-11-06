From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 06 Nov 2024 18:10:16 +0000
Subject: [PATCH net 3/6] net/diag: Pre-allocate optional info only if
 requested
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241106-tcp-md5-diag-prep-v1-3-d62debf3dded@gmail.com>
References: <20241106-tcp-md5-diag-prep-v1-0-d62debf3dded@gmail.com>
In-Reply-To: <20241106-tcp-md5-diag-prep-v1-0-d62debf3dded@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 David Ahern <dsahern@kernel.org>, Ivan Delalande <colona@arista.com>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>, Boris Pismenny <borisp@nvidia.com>, 
 John Fastabend <john.fastabend@gmail.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mptcp@lists.linux.dev, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730918993; l=2351;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=fOCy3J49s/tDFSTizx6qbQKYeByBMBjOxYu/MDJO9nw=;
 b=2O5F1B9EZzEGVdrOCj2HomQpsZZzVQgWcK2OQNqsSIt8ApYIeTBk6eILHN1WF072Om+eeraJ5
 QUK9xiYVjVnArf7LvqgTk0a7p39cA3kBkwAxQ9IEe4ea6jHcrE1bJQi
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Those INET_DIAG_* flags from req->idiag_ext are provided by the
userspace, so they are not going to change during one socket dump.
This is going to save just nits and bits for typical netlink reply,
which I'm going to utilise in the very next patch by always allocating
tls_get_info_size().
It's possible to save even some more by checking the request in
inet_diag_msg_attrs_size(), but that's being on very stingy side.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 net/ipv4/inet_diag.c | 29 ++++++++++++++++++-----------
 1 file changed, 18 insertions(+), 11 deletions(-)

diff --git a/net/ipv4/inet_diag.c b/net/ipv4/inet_diag.c
index ca9a7e61d8d7de80cb234c45c41d6357fde50c11..2dd173a73bd1e2657957e5e4ecb70401cc85dfda 100644
--- a/net/ipv4/inet_diag.c
+++ b/net/ipv4/inet_diag.c
@@ -102,24 +102,31 @@ static size_t inet_sk_attr_size(struct sock *sk,
 				bool net_admin)
 {
 	const struct inet_diag_handler *handler;
-	size_t aux = 0;
+	int ext = req->idiag_ext;
+	size_t ret = 0;
 
 	rcu_read_lock();
 	handler = rcu_dereference(inet_diag_table[req->sdiag_protocol]);
 	DEBUG_NET_WARN_ON_ONCE(!handler);
 	if (handler && handler->idiag_get_aux_size)
-		aux = handler->idiag_get_aux_size(sk, net_admin);
+		ret += handler->idiag_get_aux_size(sk, net_admin);
 	rcu_read_unlock();
 
-	return	  nla_total_size(sizeof(struct tcp_info))
-		+ nla_total_size(sizeof(struct inet_diag_msg))
-		+ inet_diag_msg_attrs_size()
-		+ nla_total_size(sizeof(struct inet_diag_meminfo))
-		+ nla_total_size(SK_MEMINFO_VARS * sizeof(u32))
-		+ nla_total_size(TCP_CA_NAME_MAX)
-		+ nla_total_size(sizeof(struct tcpvegas_info))
-		+ aux
-		+ 64;
+	ret += nla_total_size(sizeof(struct tcp_info))
+	     + nla_total_size(sizeof(struct inet_diag_msg))
+	     + inet_diag_msg_attrs_size()
+	     + 64;
+
+	if (ext & (1 << (INET_DIAG_MEMINFO - 1)))
+		ret += nla_total_size(sizeof(struct inet_diag_meminfo));
+	if (ext & (1 << (INET_DIAG_SKMEMINFO - 1)))
+		ret += nla_total_size(SK_MEMINFO_VARS * sizeof(u32));
+	if (ext & (1 << (INET_DIAG_CONG - 1)))
+		ret += nla_total_size(TCP_CA_NAME_MAX);
+	if (ext & (1 << (INET_DIAG_VEGASINFO - 1)))
+		ret += nla_total_size(sizeof(struct tcpvegas_info));
+
+	return ret;
 }
 
 int inet_diag_msg_attrs_fill(struct sock *sk, struct sk_buff *skb,

-- 
2.42.2

