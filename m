From: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
Subject: [PATCH bpf-next v3 0/5] sockmap: Fix reading with splice(2)
Date: Wed, 09 Jul 2025 14:47:56 +0200
Message-Id: <20250709-sockmap-splice-v3-0-b23f345a67fc@datadoghq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPxkbmgC/3XNTQ6CMBCG4auQWVtTSgFx5T2Mi+kP0Ci0tqTBE
 O5u08SNxuWXN/PMBkF7owOciw28jiYYO6dRHQqQI86DJkalDYwyThvakGDlfUJHgnsYqYmq2hI
 lbVUrOKQj53Vv1gxeQbiezHpd4JbKaMJi/St/imXu/9BYEkr4iVFkKEou6ovCBZUdxudR2ilzk
 X2IOhHdD8ES0cnUeC17rNg3se/7G4l8liz9AAAA
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>
Cc: Kuniyuki Iwashima <kuniyu@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 netdev@vger.kernel.org, bpf@vger.kernel.org, 
 Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752065284; l=1938;
 i=vincent.whitchurch@datadoghq.com; s=20240606; h=from:subject:message-id;
 bh=pqv9y2+ysL7+9uOQF2f7M0nQEyHKQ5MFTUOC7/mQbII=;
 b=yePySAAhZt7yPjoxYZV+zzSkF/Ty4wntcYWGVd67nBFIWrSC2bquTXQ6BV9Jc2dYl5X+hgyBM
 UTd61t25t9wDaP3pZcK8RkoZKirweVg4IyCCsc0ZdwN7yh/ScCd18D6
X-Developer-Key: i=vincent.whitchurch@datadoghq.com; a=ed25519;
 pk=GwUiPK96WuxbUAD4UjapyK7TOt+aX0EqABOZ/BOj+/M=
X-Endpoint-Received: by B4 Relay for vincent.whitchurch@datadoghq.com/20240606 with auth_id=170
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I noticed that if the verdict callback returns SK_PASS, using splice(2)
to read from a socket in a sockmap does not work since it never sees the
data queued on to it.  As far as I can see, this is not a regression but
just something that has never worked, but it does make sockmap unusable
if you can't guarantee that the programs using the socket will not use
splice(2).

This series attempts to fix it and add a test for it.

---
Changes in v3:
- Rebase on latest bpf-next/master
- Link to v2: https://lore.kernel.org/r/20250609-sockmap-splice-v2-0-9c50645cfa32@datadoghq.com

Changes in v2:
- Rebase on latest bpf-next/master
- Remove unnecessary change in inet_dgram_ops
- Remove ->splice_read NULL check in inet_splice_read()
- Use INDIRECT_CALL_1() in inet_splice_read()
- Include test case in default test suite in test_sockmap
- Link to v1: https://lore.kernel.org/r/20240606-sockmap-splice-v1-0-4820a2ab14b5@datadoghq.com

---
Vincent Whitchurch (5):
      net: Add splice_read to prot
      tcp_bpf: Fix reading with splice(2)
      selftests/bpf: sockmap: Exit with error on failure
      selftests/bpf: sockmap: Allow SK_PASS in verdict
      selftests/bpf: sockmap: Add splice + SK_PASS regression test

 include/net/inet_common.h                  |  3 +
 include/net/sock.h                         |  3 +
 net/ipv4/af_inet.c                         | 13 ++++-
 net/ipv4/tcp_bpf.c                         |  9 +++
 net/ipv4/tcp_ipv4.c                        |  1 +
 net/ipv6/af_inet6.c                        |  2 +-
 net/ipv6/tcp_ipv6.c                        |  1 +
 tools/testing/selftests/bpf/test_sockmap.c | 90 +++++++++++++++++++++++++++++-
 8 files changed, 118 insertions(+), 4 deletions(-)
---
base-commit: ad97cb2ed06a6ba9025fd8bd14fa24369550cbb5
change-id: 20240606-sockmap-splice-d371ac07d7b4

Best regards,
-- 
Vincent Whitchurch <vincent.whitchurch@datadoghq.com>

