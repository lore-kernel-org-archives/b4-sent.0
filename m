From: Quanye Yang <quanyeyang@proton.me>
Subject: [PATCH net-next v4 0/2] net: annotate remaining lockless
 sk->sk_err accesses
Date: Thu, 15 Oct 2026 20:31:35 -0700
Message-Id: <20261015-tls-fix-sk-kcsan-err-v4-0-391d788327f3@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33OSQ7CMAwF0KugrDFKnLYMK+6BWDiNC2FIURIqE
 OrdScumQoLll+33/RKRg+MoNrOXCNy56FqfQzGfifpI/sDgbM4CJVZKSoR0idC4B8QznOtIHjg
 EqBpuNC6LolGlyKe3wHlnZHfCcwLPjyT2n0m8mxPXaVCH3aOLqQ3P8YNOjRf/yzoFEgyRNCTLS
 qPe3kKbWr+48ljR4RTRPxDMCK/1mpCNtWX1jegJouQPRA8IrogsG63ITpG+798rrVNlXgEAAA=
 =
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792121497; l=2335;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=tJxl6szbEu/sixUPfjPjMWFV7t5uJftR95+/Px8Swc8=;
 b=rfObpSk8GQeJLi5fzl0oFdpqlw6AcSh1a0WtbkL3Jaya4s6iGA/Se9EulONiXZ2ocdERruI/b
 ZYC37w4PGurBqPVtHWjI/mSuQgpLWcZ7OLzMqAz0no38FoS41TIBVxr
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
Changes in v4:
- tls_rx_rec_wait() / bpf_exec_tx_verdict(): declare skerr at function
  scope (Jakub Kicinski)
- Patch 2: unchanged
- Link to v3: https://patch.msgid.link/20261010-tls-fix-sk-kcsan-err-v3-0-e28aadeb31ad@proton.me

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
 net/tls/tls_sw.c          | 51 ++++++++++++++++++++++++++++++-----------------
 5 files changed, 41 insertions(+), 24 deletions(-)
---
base-commit: d8674294aefef02266c4d47ad10131f1bffbe534
change-id: 20261002-tls-fix-sk-kcsan-err-6fef32744f15

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

