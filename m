From: Quanye Yang <quanyeyang@proton.me>
Subject: [PATCH net-next v4 0/2] tcp: annotate lockless access to
 sk->sk_err
Date: Thu, 17 Sep 2026 06:41:21 -0700
Message-Id: <20260917-mptcp-sk-err-net-v4-0-1f04f52f2561@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XOTQ6CMBAF4KuQrq3pD0px5T2Mi1KmUo2FtLXBE
 O5uixticPkyM9+bCXlwBjw6FRNyEI03vU2h3BVIddLeAJs2ZcQIO5KaCPwcghqwf2BwDlsIuNJ
 aCNDkQMoSpbPBgTbjQl5QXrAwBnT9TvyruYMKWcy7nfGhd++lPdLl4n9RpJjiVlZUSlC11O15c
 H3o7f4JCx/ZGqg3AJaA/KZsQElVk1+ArwDKNgCeAFVSLrioRNPCGpjn+QOpj8leTgEAAA==
X-Change-ID: 20260908-mptcp-sk-err-net-7ff88ef05044
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 "Matthieu Baerts (NGI0)" <matttbe@kernel.org>, 
 Geliang Tang <geliang@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789652484; l=1644;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=HST9EaucmkFhUHvdO3KRl/gCm8AxlEQ93kW9f+QlSbg=;
 b=Wu3a89wukqLv07lr32vRc6ZT8eJkrZgIyh1uRSesnCrwQSUegOODeADllKXYrBB6JithBQ+93
 1+BriVbD70HA3ImNzIori9P7I2wbQVDRy9PIiBQAWuFHHYL/piRqmIj
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

do_recvmmsg() and getsockopt(SO_ERROR) call sock_error() without the
socket lock and clear sk_err with xchg(). Annotate the matching
lockless peeks with READ_ONCE().

Patch 1 covers TCP. Patch 2 covers MPTCP, including the remaining
unmarked subflow peeks.

This does not consume sk_err. The check-then-sock_error() TOCTOU on
the no-data paths is a separate issue.

---
Changes in v4:
- split the annotation change, one points to tcp and another points to
  mptcp.
- annotate the remaining unmarked MPTCP sk_err peeks on the
  subflow error-report path.
- Link to v3: https://patch.msgid.link/20260912-mptcp-sk-err-net-v3-1-c41383878bde@proton.me

Changes in v3:
- drop the Fixes tag and retarget to net-next
- annotate the remaining unmarked sk_err peeks on the TCP/MPTCP
  send, recv and splice paths
- Link to v2: https://patch.msgid.link/20260909-mptcp-sk-err-net-v2-1-5044abecac90@proton.me

Changes in v2:
- add Reported-by and Closes for the MPTCP syzkaller report
- Link to v1: https://patch.msgid.link/20260908-mptcp-sk-err-net-v1-1-da71aaec9afd@proton.me

---
Quanye Yang (2):
      tcp: annotate lockless access to sk->sk_err
      mptcp: annotate lockless access to sk->sk_err

 include/net/tcp.h    | 3 ++-
 net/core/stream.c    | 2 +-
 net/ipv4/tcp.c       | 6 +++---
 net/ipv4/tcp_bpf.c   | 7 +++----
 net/mptcp/protocol.c | 8 ++++----
 net/mptcp/subflow.c  | 4 ++--
 6 files changed, 15 insertions(+), 15 deletions(-)
---
base-commit: 211f2a875f6f447745d80d5762d6d614503ac84a
change-id: 20260908-mptcp-sk-err-net-7ff88ef05044

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

