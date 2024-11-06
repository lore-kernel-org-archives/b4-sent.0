From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 06 Nov 2024 18:10:15 +0000
Subject: [PATCH net 2/6] net/diag: Warn only once on EMSGSIZE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241106-tcp-md5-diag-prep-v1-2-d62debf3dded@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730918993; l=1040;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=yIywEl4vHF1DrEzww1U5WkkGaZ14BAMY3GjreNIr5EA=;
 b=bEe3Nj9Ft2qwDiKOg6KHN8UOZdyHHL7bHoshX5SjL0EAZKvZYSRS+mbNynLT6KyczIi/0eUzz
 85bYlJhVu7LDv+U41rm8yFwML1IPrO7jppiwuqrOGVdv3zmyeZetppD
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The code clearly expects that the pre-allocated skb will be enough for
the netlink reply message. But if in an unbelievable situation there is
a kernel issue and sk_diag_fill() fails with -EMSGSIZE, this WARN_ON()
can be triggered from userspace. That aggravates the issue from KASLR
leak into possible DOS vector. Use WARN_ON_ONCE() which is clearly
enough to provide an information on a kernel issue.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 net/ipv4/inet_diag.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/ipv4/inet_diag.c b/net/ipv4/inet_diag.c
index 67b9cc4c0e47a596a4d588e793b7f13ee040a1e3..ca9a7e61d8d7de80cb234c45c41d6357fde50c11 100644
--- a/net/ipv4/inet_diag.c
+++ b/net/ipv4/inet_diag.c
@@ -583,7 +583,7 @@ int inet_diag_dump_one_icsk(struct inet_hashinfo *hashinfo,
 
 	err = sk_diag_fill(sk, rep, cb, req, 0, net_admin);
 	if (err < 0) {
-		WARN_ON(err == -EMSGSIZE);
+		WARN_ON_ONCE(err == -EMSGSIZE);
 		nlmsg_free(rep);
 		goto out;
 	}

-- 
2.42.2

