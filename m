From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 06 Nov 2024 18:10:17 +0000
Subject: [PATCH net 4/6] net/diag: Always pre-allocate tcp_ulp info
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241106-tcp-md5-diag-prep-v1-4-d62debf3dded@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730918993; l=6868;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=FncH4oZGHPV39oeGv/CSy8io/OgtTSiJCBLPRkjA1HU=;
 b=g5fDzb3sXLqQkmiILRw2wIeXsPHRbv9pl2o1FAODv7/R2cKEKtTaeulkQdFRC6H1J0eo3NWzZ
 w6fmt7kcGjJBGgN4ED3rKvsYJQ9vFjVlvQuavd8SqNYBMhKpV2Kfub6
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently there is a theoretical race between netlink one-socket dump
and allocating icsk->icsk_ulp_ops.

Simplify the expectations by always allocating maximum tcp_ulp-info.
With the previous patch the typical netlink message allocation was
decreased for kernel replies on requests without idiag_ext flags,
so let's use it.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 include/net/tcp.h    |  1 -
 net/ipv4/inet_diag.c | 48 ++++++++++++++++++++++++++++++++++++++++++++++++
 net/ipv4/tcp_diag.c  | 13 -------------
 net/mptcp/diag.c     | 20 --------------------
 net/tls/tls_main.c   | 17 -----------------
 5 files changed, 48 insertions(+), 51 deletions(-)

diff --git a/include/net/tcp.h b/include/net/tcp.h
index d1948d357dade0842777265d3397842919f9eee0..757711aa5337ae7e6abee62d303eb66d37082e19 100644
--- a/include/net/tcp.h
+++ b/include/net/tcp.h
@@ -2568,7 +2568,6 @@ struct tcp_ulp_ops {
 	void (*release)(struct sock *sk);
 	/* diagnostic */
 	int (*get_info)(struct sock *sk, struct sk_buff *skb);
-	size_t (*get_info_size)(const struct sock *sk);
 	/* clone ulp */
 	void (*clone)(const struct request_sock *req, struct sock *newsk,
 		      const gfp_t priority);
diff --git a/net/ipv4/inet_diag.c b/net/ipv4/inet_diag.c
index 2dd173a73bd1e2657957e5e4ecb70401cc85dfda..97862971d552216e574cac3dd2a8fc8c893888d3 100644
--- a/net/ipv4/inet_diag.c
+++ b/net/ipv4/inet_diag.c
@@ -97,6 +97,53 @@ void inet_diag_msg_common_fill(struct inet_diag_msg *r, struct sock *sk)
 }
 EXPORT_SYMBOL_GPL(inet_diag_msg_common_fill);
 
+static size_t tls_get_info_size(void)
+{
+	size_t size = 0;
+
+#ifdef CONFIG_TLS
+	size += nla_total_size(0) +             /* INET_ULP_INFO_TLS */
+		nla_total_size(sizeof(u16)) +   /* TLS_INFO_VERSION */
+		nla_total_size(sizeof(u16)) +   /* TLS_INFO_CIPHER */
+		nla_total_size(sizeof(u16)) +   /* TLS_INFO_RXCONF */
+		nla_total_size(sizeof(u16)) +   /* TLS_INFO_TXCONF */
+		nla_total_size(0) +             /* TLS_INFO_ZC_RO_TX */
+		nla_total_size(0) +             /* TLS_INFO_RX_NO_PAD */
+		0;
+#endif
+
+	return size;
+}
+
+static size_t subflow_get_info_size(void)
+{
+	size_t size = 0;
+
+#ifdef CONFIG_MPTCP
+	size += nla_total_size(0) +     /* INET_ULP_INFO_MPTCP */
+		nla_total_size(4) +     /* MPTCP_SUBFLOW_ATTR_TOKEN_REM */
+		nla_total_size(4) +     /* MPTCP_SUBFLOW_ATTR_TOKEN_LOC */
+		nla_total_size(4) +     /* MPTCP_SUBFLOW_ATTR_RELWRITE_SEQ */
+		nla_total_size_64bit(8) +       /* MPTCP_SUBFLOW_ATTR_MAP_SEQ */
+		nla_total_size(4) +     /* MPTCP_SUBFLOW_ATTR_MAP_SFSEQ */
+		nla_total_size(4) +     /* MPTCP_SUBFLOW_ATTR_SSN_OFFSET */
+		nla_total_size(2) +     /* MPTCP_SUBFLOW_ATTR_MAP_DATALEN */
+		nla_total_size(4) +     /* MPTCP_SUBFLOW_ATTR_FLAGS */
+		nla_total_size(1) +     /* MPTCP_SUBFLOW_ATTR_ID_REM */
+		nla_total_size(1) +     /* MPTCP_SUBFLOW_ATTR_ID_LOC */
+		0;
+#endif
+
+	return size;
+}
+
+static size_t tcp_ulp_ops_size(void)
+{
+	size_t size = max(tls_get_info_size(), subflow_get_info_size());
+
+	return size + nla_total_size(0) + nla_total_size(TCP_ULP_NAME_MAX);
+}
+
 static size_t inet_sk_attr_size(struct sock *sk,
 				const struct inet_diag_req_v2 *req,
 				bool net_admin)
@@ -115,6 +162,7 @@ static size_t inet_sk_attr_size(struct sock *sk,
 	ret += nla_total_size(sizeof(struct tcp_info))
 	     + nla_total_size(sizeof(struct inet_diag_msg))
 	     + inet_diag_msg_attrs_size()
+	     + tcp_ulp_ops_size()
 	     + 64;
 
 	if (ext & (1 << (INET_DIAG_MEMINFO - 1)))
diff --git a/net/ipv4/tcp_diag.c b/net/ipv4/tcp_diag.c
index 36606a19b451f059e32c58c0d76a878dc9be5ff0..722dbfd54d247b4def1e77b1674c5b207c5a939d 100644
--- a/net/ipv4/tcp_diag.c
+++ b/net/ipv4/tcp_diag.c
@@ -154,7 +154,6 @@ static int tcp_diag_get_aux(struct sock *sk, bool net_admin,
 
 static size_t tcp_diag_get_aux_size(struct sock *sk, bool net_admin)
 {
-	struct inet_connection_sock *icsk = inet_csk(sk);
 	size_t size = 0;
 
 #ifdef CONFIG_TCP_MD5SIG
@@ -174,18 +173,6 @@ static size_t tcp_diag_get_aux_size(struct sock *sk, bool net_admin)
 				       sizeof(struct tcp_diag_md5sig));
 	}
 #endif
-
-	if (net_admin && sk_fullsock(sk)) {
-		const struct tcp_ulp_ops *ulp_ops;
-
-		ulp_ops = icsk->icsk_ulp_ops;
-		if (ulp_ops) {
-			size += nla_total_size(0) +
-				nla_total_size(TCP_ULP_NAME_MAX);
-			if (ulp_ops->get_info_size)
-				size += ulp_ops->get_info_size(sk);
-		}
-	}
 	return size;
 }
 
diff --git a/net/mptcp/diag.c b/net/mptcp/diag.c
index 2d3efb405437d85c0bca70d7a92ca3a7363365e1..8b36867e4ddd5f45cebcf60e9093a061d5208756 100644
--- a/net/mptcp/diag.c
+++ b/net/mptcp/diag.c
@@ -84,27 +84,7 @@ static int subflow_get_info(struct sock *sk, struct sk_buff *skb)
 	return err;
 }
 
-static size_t subflow_get_info_size(const struct sock *sk)
-{
-	size_t size = 0;
-
-	size += nla_total_size(0) +	/* INET_ULP_INFO_MPTCP */
-		nla_total_size(4) +	/* MPTCP_SUBFLOW_ATTR_TOKEN_REM */
-		nla_total_size(4) +	/* MPTCP_SUBFLOW_ATTR_TOKEN_LOC */
-		nla_total_size(4) +	/* MPTCP_SUBFLOW_ATTR_RELWRITE_SEQ */
-		nla_total_size_64bit(8) +	/* MPTCP_SUBFLOW_ATTR_MAP_SEQ */
-		nla_total_size(4) +	/* MPTCP_SUBFLOW_ATTR_MAP_SFSEQ */
-		nla_total_size(4) +	/* MPTCP_SUBFLOW_ATTR_SSN_OFFSET */
-		nla_total_size(2) +	/* MPTCP_SUBFLOW_ATTR_MAP_DATALEN */
-		nla_total_size(4) +	/* MPTCP_SUBFLOW_ATTR_FLAGS */
-		nla_total_size(1) +	/* MPTCP_SUBFLOW_ATTR_ID_REM */
-		nla_total_size(1) +	/* MPTCP_SUBFLOW_ATTR_ID_LOC */
-		0;
-	return size;
-}
-
 void mptcp_diag_subflow_init(struct tcp_ulp_ops *ops)
 {
 	ops->get_info = subflow_get_info;
-	ops->get_info_size = subflow_get_info_size;
 }
diff --git a/net/tls/tls_main.c b/net/tls/tls_main.c
index 6b4b9f2749a6fd6de495940c5cb3f2154a5a451e..f3491c4e942e08dc882cb81eef071203384b2b37 100644
--- a/net/tls/tls_main.c
+++ b/net/tls/tls_main.c
@@ -1072,22 +1072,6 @@ static int tls_get_info(struct sock *sk, struct sk_buff *skb)
 	return err;
 }
 
-static size_t tls_get_info_size(const struct sock *sk)
-{
-	size_t size = 0;
-
-	size += nla_total_size(0) +		/* INET_ULP_INFO_TLS */
-		nla_total_size(sizeof(u16)) +	/* TLS_INFO_VERSION */
-		nla_total_size(sizeof(u16)) +	/* TLS_INFO_CIPHER */
-		nla_total_size(sizeof(u16)) +	/* TLS_INFO_RXCONF */
-		nla_total_size(sizeof(u16)) +	/* TLS_INFO_TXCONF */
-		nla_total_size(0) +		/* TLS_INFO_ZC_RO_TX */
-		nla_total_size(0) +		/* TLS_INFO_RX_NO_PAD */
-		0;
-
-	return size;
-}
-
 static int __net_init tls_init_net(struct net *net)
 {
 	int err;
@@ -1123,7 +1107,6 @@ static struct tcp_ulp_ops tcp_tls_ulp_ops __read_mostly = {
 	.init			= tls_init,
 	.update			= tls_update,
 	.get_info		= tls_get_info,
-	.get_info_size		= tls_get_info_size,
 };
 
 static int __init tls_register(void)

-- 
2.42.2

