From: Quanye Yang <quanyeyang@proton.me>
Subject: [PATCH net-next 0/2] net: annotate remaining lockless sk->sk_err
 accesses
Date: Fri, 02 Oct 2026 00:29:25 -0700
Message-Id: <20261002-tls-fix-sk-kcsan-err-v1-0-baa0ba056323@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QrCMBAEf6XcswdJWiv4K+JDjRuNlVPuUimU/
 nujPg67MwsZNMPo2Cyk+GTLL6ngdw3F+yA3cL5WpuBC750LXJ7GKc9sI4/RBmGocp+Q2nDouuT
 3VNW3on5+2RMJCgvmQuf/YtPlgVi+VVrXDQ+kfdyCAAAA
X-Change-ID: 20261002-tls-fix-sk-kcsan-err-6fef32744f15
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 bpf@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790926169; l=1570;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=bWyQfeX71ilQHixe/9sqba14iFwH0RQ1faMsz8q6KyA=;
 b=n7AbEmcF849oLECZ/6IMFaBiEcWOo2t8+xKvvUBfrCxj29n/qy0t9wSEJXIjepbJf5aydqgjT
 BDf57TJc/dBA5LmO1hPA9KJtq2KDfdb7BBcRtKT3AfcCe9nAX04277X
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TCP/MPTCP series that annotated lockless sk_err peeks and
consumes is in net-next. Paolo asked for the same treatment on
kTLS and on the unmarked writers that still race those readers.

do_recvmmsg() and getsockopt(SO_ERROR) still call sock_error()
without the socket lock. kTLS is a ULP on that same struct sock,
so tls_rx_rec_wait() has the same peek-versus-consume split, and
the send path still does a double unmarked load.

sock_dequeue_err_skb() can store sk_err from MSG_ERRQUEUE before
lock_sock(). strp_abort_strp() and sk_psock_report_error() write
the same field on the TCP/TLS and sockmap paths.

Patch 1 annotates the TLS readers and consumes sk_err once on the
no-data path. Patch 2 pairs the remaining writers with WRITE_ONCE().
No extra ordering is added; ICMP error-queue overwrite semantics
are unchanged.

Link: https://lore.kernel.org/netdev/3d9d442f-f168-43da-87b0-010ad5a78365@redhat.com/

Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
Quanye Yang (2):
      tls: annotate lockless access to sk->sk_err
      net: annotate lockless writes to sk->sk_err

 include/linux/skmsg.h     |  2 +-
 net/core/skbuff.c         |  5 +++--
 net/strparser/strparser.c |  2 +-
 net/tls/tls_device.c      |  5 +++--
 net/tls/tls_sw.c          | 45 ++++++++++++++++++++++++++++++---------------
 5 files changed, 38 insertions(+), 21 deletions(-)
---
base-commit: 071876fd50482a68603a9460d80dd6dd58827ee1
change-id: 20261002-tls-fix-sk-kcsan-err-6fef32744f15

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

