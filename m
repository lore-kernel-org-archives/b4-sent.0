From: Quanye Yang <quanyeyang@proton.me>
Subject: [PATCH net-next v3 0/2] net: annotate remaining lockless
 sk->sk_err accesses
Date: Sat, 10 Oct 2026 07:46:27 -0700
Message-Id: <20261010-tls-fix-sk-kcsan-err-v3-0-e28aadeb31ad@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OQQ6CMBREr2K69pv2F2pw5T2MiwIfqWhL2kowh
 LtbcMNGl5OZeTMTC+QNBXbaTczTYIJxNgm537Gq1fZGYOqkGXJUgnOE+AjQmBFCB10VtAXyHlR
 DjcRjljUiZ6nae0qZFXthliJYGiO7fp3wKu9UxYW6ZFsTovPv9cEg1sb/sUEAh1JrXmqeK4ny3
 HsXnT08aZ0YcAuRPyCYIFTIQiOVdZ2rLWSe5w+q/XezGQEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791643590; l=2099;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=1+ZzSayVIBmhXvsoWcGH5TOxPUv9kk3pCN6x3PwkR9Q=;
 b=lccbEbihQ2wVzgOvHYkd02J3zLYLv5cyZfzpTp6Iwluf/u91B8gMd9+Yvj5p+koTJDZ5Ca9FI
 D5d63aaLSGrAXw+p5YXLcyTBExgWTLNOvVDzm9/YwDd838iBsYJ54xU
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
Changes in v3:
- rebase on net-next after the net merge
- refresh WRITE_ONCE() in strp_abort_strp() after the strparser
  refactor (Jakub Kicinski)
- Patch 2: carry Reviewed-by from Eric Dumazet
- Patch 1: unchanged
- Link to v2: https://patch.msgid.link/20261003-tls-fix-sk-kcsan-err-v2-0-e939a2ebdd56@proton.me

Changes in v2:
- tls_encrypt_done(): fold the three unmarked sk_err loads into one
  READ_ONCE()
- Link to v1: https://patch.msgid.link/20261002-tls-fix-sk-kcsan-err-v1-0-baa0ba056323@proton.me

---
Quanye Yang (2):
      tls: annotate lockless access to sk->sk_err
      net: annotate lockless writes to sk->sk_err

 include/linux/skmsg.h     |  2 +-
 net/core/skbuff.c         |  5 +++--
 net/strparser/strparser.c |  2 +-
 net/tls/tls_device.c      |  5 +++--
 net/tls/tls_sw.c          | 54 +++++++++++++++++++++++++++++++----------------
 5 files changed, 44 insertions(+), 24 deletions(-)
---
base-commit: d8674294aefef02266c4d47ad10131f1bffbe534
change-id: 20261002-tls-fix-sk-kcsan-err-6fef32744f15

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

