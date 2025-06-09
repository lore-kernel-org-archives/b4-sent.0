From: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
Subject: [PATCH bpf-next v2 0/5] sockmap: Fix reading with splice(2)
Date: Mon, 09 Jun 2025 15:26:57 +0200
Message-Id: <20250609-sockmap-splice-v2-0-9c50645cfa32@datadoghq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACHhRmgC/3WNyw6CMBBFf4XM2jFtrWBc+R+GRR8DTBRaW0Iwh
 H+3Ye/y5OSeu0GmxJThXm2QaOHMYSqgThW4wUw9IfvCoITSohY15uBeo4mY45sdob800jjR+MZ
 qKKOYqOP1CD7Bxg4nWmdoixk4zyF9j6dFHv5fdJEoUN+UMMpYqe314c1sfOiHz9mFEdp933/T9
 CxaugAAAA==
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>
Cc: Kuniyuki Iwashima <kuniyu@amazon.com>, netdev@vger.kernel.org, 
 bpf@vger.kernel.org, Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749475632; l=1657;
 i=vincent.whitchurch@datadoghq.com; s=20240606; h=from:subject:message-id;
 bh=XGEWAwE33wL/9vohSj+5FqkrczlWwGAL/bYW7vM/ZPA=;
 b=SczZKmrp+zK4X6raqu8rOTd0Pq0ybIE4stOf67y5EaqbMwDrcbYips0hY2slbQcbVYkNtGggr
 BRYiYezLd/+CJitEpb/xFkTTTgF7duZ6yGNzVCJQhf+N0tepUtYyjRl
X-Developer-Key: i=vincent.whitchurch@datadoghq.com; a=ed25519;
 pk=GwUiPK96WuxbUAD4UjapyK7TOt+aX0EqABOZ/BOj+/M=
X-Endpoint-Received: by B4 Relay for vincent.whitchurch@datadoghq.com/20240606 with auth_id=170
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I noticed that if the verdict callback returns SK_PASS, using splice(2)
to read from the socket doesn't work since it never sees the data queued
on to it.  As far as I can see, this is not a regression but just
something that has never worked.

This series attempts to fix it and add a test for it.

---
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
base-commit: e41079f53e8792c99cc8888f545c31bc341ea9ac
change-id: 20240606-sockmap-splice-d371ac07d7b4

Best regards,
-- 
Vincent Whitchurch <vincent.whitchurch@datadoghq.com>

