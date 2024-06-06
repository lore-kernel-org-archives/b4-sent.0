From: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
Subject: [PATCH bpf-next 0/5] sockmap: Fix reading with splice(2)
Date: Thu, 06 Jun 2024 11:27:51 +0200
Message-Id: <20240606-sockmap-splice-v1-0-4820a2ab14b5@datadoghq.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABeBYWYC/x3MSQqAMAxA0atI1gbqgAWvIi46RA1qLY2IIN7d4
 vIt/n9AKDEJ9MUDiS4WPkJGVRbgFhNmQvbZUKu6VZ3qUA637iaixI0doW90ZZzSXtsWchQTTXz
 /wwFsnDDQfcL4vh+tlFU+agAAAA==
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>
Cc: netdev@vger.kernel.org, bpf@vger.kernel.org, 
 Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717666080; l=1284;
 i=vincent.whitchurch@datadoghq.com; s=20240606; h=from:subject:message-id;
 bh=3jtGlH/vJOZwEuic+3S8X/WuUsePedwqRR/gd3oODNk=;
 b=YP59EoxHRvNGfrOBcds1lxe8/uU8MyogOBvjqnjGQz816BDh0Vy5G2V0QVA9zfffi/YpdJhyC
 R5DQabnxMWcCCLaTQLT1yZgeQlD1tNOtd95jNCbWj+g0bl8ku+WDC80
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
Vincent Whitchurch (5):
      net: Add splice_read to prot
      tcp_bpf: Fix reading with splice(2)
      selftests/bpf: sockmap: Exit with error on failure
      selftests/bpf: sockmap: Allow SK_PASS in verdict
      selftests/bpf: sockmap: Add basic splice(2) mode

 include/net/inet_common.h                  |  3 ++
 include/net/sock.h                         |  3 ++
 net/ipv4/af_inet.c                         | 18 ++++++-
 net/ipv4/tcp_bpf.c                         |  9 ++++
 net/ipv4/tcp_ipv4.c                        |  1 +
 net/ipv6/af_inet6.c                        |  2 +-
 net/ipv6/tcp_ipv6.c                        |  1 +
 tools/testing/selftests/bpf/test_sockmap.c | 78 +++++++++++++++++++++++++++++-
 8 files changed, 111 insertions(+), 4 deletions(-)
---
base-commit: 072088704433f75dacf9e33179dd7a81f0a238d4
change-id: 20240606-sockmap-splice-d371ac07d7b4

Best regards,
-- 
Vincent Whitchurch <vincent.whitchurch@datadoghq.com>

