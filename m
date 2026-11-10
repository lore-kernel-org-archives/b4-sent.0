From: Yongjian Wang <echoowall@gmail.com>
Subject: [PATCH net-next v4 0/4] tcp: fix tcp_base_mss on passive
 connections and test MTU probing
Date: Wed, 11 Nov 2026 00:45:54 +0800
Message-Id: <20261111-mtu-probing-series-v4-0-6f2e484ca8ea@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEJK82oC/33PywqDMBAF0F+RrJuSh8+u+h+li8SMmlKjJFEs4
 r836kaKdDnM3HOZGTmwGhy6RTOyMGqnOxOG+BKhshGmBqxVmBEjLKWUcNz6Afe2k9rUeM9ikWe
 SF5WSoCoUgr2FSk8b+kAGPDYwefTcN26QLyj9aq63jXa+s5+tf6Rb4l/VSDHBguWkgIwlQoh73
 Qr9vpZduxWM7EjkpwQLBE8SlcYFKbmSvwQ/EJScEjwQKnwrJFsdeiSWZfkCoAZjh1YBAAA=
X-Change-ID: 20261103-mtu-probing-series-a87b39fdbedf
To: pabeni@redhat.com, kuba@kernel.org, shuah@kernel.org, 
 edumazet@kernel.org, horms@kernel.org, kuniyu@google.com, 
 ncardwell@google.com, davem@davemloft.net
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 netdev@vger.kernel.org, panweiping3@gmail.com, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794329156; l=2591;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=S4Re5/ONNr+x1/wp/J9VFbiypqePCo68XyhS83zfVnY=;
 b=Lk/TrL3KGYJaH2dJNyRWBnpDgGzuq5SFRj8zqIqYznmEVK7sdELtgaazUWLNjBKn4bwkFCi4j
 HB2kwLyICT7BVDFBm+U2z5+1Hb/k7qKi/yTbKvxWJ31Gk5lNinQy6Hm
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With tcp_mtu_probing=2, passive TCP connections can start at the full
MSS because they sync MSS before initializing MTU probing. Patch 1
moves initialization next to the existing MSS sync in the passive
paths and in the active SYN-ACK path. Patch 2 adds a regression test.

Patches 3 and 4 add coverage for black hole detection and the MTU
search on active connections.

On x86_64 KVM, the revised MTU search test passed in IPv4, IPv6 and
IPv4-mapped IPv6 with patch 1 applied. Without patch 1, it failed in
all three modes. The first TSO packet carried 2072 bytes of TCP
payload, and the test expected 2048.

---
Changes in v4:
- Rename the existing black hole test to show its non-default settings.
- Add a black hole test that only sets tcp_mtu_probing=1 (Neal, patch 3).
- Link to v3: https://lore.kernel.org/r/20261110-mtu-probing-series-v3-0-dedfab25d641@gmail.com

Changes in v3:
- Document how the passive MSS issue was discovered (patch 1).
- Let the SYN offer timestamps in the MTU search test so it also
  covers the active-open change in patch 1 (Neal, patch 4).
- Link to v2: https://lore.kernel.org/r/20261108-mtu-probing-series-v2-0-355d6490c3db@gmail.com

Changes in v2:
- Move tcp_mtup_init() before the existing MSS sync in IPv4 and IPv6
  passive opens and in the active SYN-ACK path. Remove the late
  initialization from tcp_init_transfer() (Kuniyuki and Neal).
- Keep the three packetdrill patches unchanged.
- Link to v1: https://lore.kernel.org/netdev/20261103-mtu-probing-series-v1-0-a2809e725aaa@gmail.com/

---
Yongjian Wang (4):
      tcp: initialize MTU probing before syncing MSS at connection setup
      selftests/net: packetdrill: test tcp_base_mss on passive connections
      selftests/net: packetdrill: add TCP black hole detection tests
      selftests/net: packetdrill: add TCP MTU probing test

 net/ipv4/tcp_input.c                               |  2 +-
 net/ipv4/tcp_ipv4.c                                |  1 +
 net/ipv6/tcp_ipv6.c                                |  1 +
 .../net/packetdrill/tcp_mtu_probing_blackhole.pkt  | 38 ++++++++++++++++++++
 ..._mtu_probing_blackhole_no_tlp_retries1_is_1.pkt | 38 ++++++++++++++++++++
 .../net/packetdrill/tcp_mtu_probing_passive.pkt    | 27 ++++++++++++++
 .../net/packetdrill/tcp_mtu_probing_search.pkt     | 42 ++++++++++++++++++++++
 7 files changed, 148 insertions(+), 1 deletion(-)
---
base-commit: fa5196392691051963726787944db872420dfa75
change-id: 20261103-mtu-probing-series-a87b39fdbedf

Best regards,
--  
Yongjian Wang <echoowall@gmail.com>

