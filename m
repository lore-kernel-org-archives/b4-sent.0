From: Quanye Yang <quanyeyang@proton.me>
Subject: [PATCH net-next v5 0/2] tcp: annotate lockless access to
 sk->sk_err
Date: Fri, 25 Sep 2026 05:47:55 -0700
Message-Id: <20260925-mptcp-sk-err-net-v5-0-0cac04d6ea48@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XOQQ6CMBAF0KuQrh3TliLFlfcwLkqZajUU0laCM
 dzdghticPkzM+/PmwT0FgM5Zm/icbDBdi6FYpcRfVPuimCblAmn/EArKqHto+4hPAC9B4cRSmO
 kREMLKgRJZ71HY8eFPJN5weEYyeU7Cc/6jjrO4rx7syF2/rW0D2y5+F80MGDQqJIphbpSpjn1v
 oud27e48ANfA9UGwBMwv6lq1EpX9BfIVwDjG0CeAC1YLnNZyrrBX0CsgXIDEECBGSpMwQ0vDmw
 NTNP0ATbphJ+PAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790340527; l=2016;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=yzTFT5eQV1N0hhk6LRnlE8otFg7jvGAPkT6VYEZMNPs=;
 b=0ecpuS0VbDnnDSJOQFSDqe8rw7eLXRYGHFCxZPctJXRC8+Z0JlcHL+juPNO3Yf+a7SaNI7SFN
 ZWerm32oUT5C9AeI8Q4qq+994bzSwJvJR6Iy4OjwY7Ub0KHJWyzXidY
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

do_recvmmsg() and getsockopt(SO_ERROR) call sock_error() without the
socket lock and clear sk_err with xchg().

Patch 1 covers TCP. Peek-only sites use READ_ONCE(). On the no-data
recv and splice paths, call sock_error() once and only stop when it
returns a non-zero error. tcp_bpf_sendmsg() folds two unmarked loads
into one READ_ONCE() and uses that value as the returned errno.

Patch 2 does the same for MPTCP and annotates the remaining subflow
error-report peeks.

---
Changes in v5:
- recv/splice: call sock_error() once instead of peek-then-consume
- mention the tcp_bpf_sendmsg() READ_ONCE fold in the TCP commit
- Link to v4: https://patch.msgid.link/20260917-mptcp-sk-err-net-v4-0-1f04f52f2561@proton.me

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

 include/net/tcp.h    |  2 +-
 net/core/stream.c    |  2 +-
 net/ipv4/tcp.c       | 12 +++++-------
 net/ipv4/tcp_bpf.c   | 10 ++++------
 net/mptcp/protocol.c | 14 ++++++--------
 net/mptcp/subflow.c  |  4 ++--
 6 files changed, 19 insertions(+), 25 deletions(-)
---
base-commit: 211f2a875f6f447745d80d5762d6d614503ac84a
change-id: 20260908-mptcp-sk-err-net-7ff88ef05044

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

