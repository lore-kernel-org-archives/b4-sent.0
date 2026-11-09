From: Yongjian Wang <echoowall@gmail.com>
Subject: [PATCH net-next v3 0/4] tcp: fix tcp_base_mss on passive
 connections and test MTU probing
Date: Tue, 10 Nov 2026 00:44:34 +0800
Message-Id: <20261110-mtu-probing-series-v3-0-dedfab25d641@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHL48WoC/32Nyw7CIBBFf8WwFkPBvlz5H8YFlGk7xkIDlNQ0/
 Xf72HRhXN7MnHMm4sEheHI7TcRBRI/WLEOcT6RqpWmAol424YxnScIE7cJAe2cVmobuLJVFrkR
 ZawW6JgvYO6hx3KQPYiBQA2Mgz/3iB/WCKqzO9bdFH6z7bP2YbMS/VEwoo5IXrIScp1LKe9NJf
 F8q222ByI+K4qeCLwqRpjq7lqwSWh0V8zx/AZqEFmYTAQAA
X-Change-ID: 20261103-mtu-probing-series-a87b39fdbedf
To: davem@davemloft.net, edumazet@kernel.org, pabeni@redhat.com, 
 shuah@kernel.org, kuniyu@google.com, horms@kernel.org, ncardwell@google.com, 
 kuba@kernel.org
Cc: netdev@vger.kernel.org, panweiping3@gmail.com, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794242675; l=2247;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=8Drvlb2AolCBjBW0hz5Yzs3wLctlMcWWUnLNb3Xmf30=;
 b=smYkDI3Wu6IkStp5vcQIpwLfu2m9tSlfMUzL2ltv/VNbH4MxnzC07U4KWY1FaKX/y1prmjHzE
 YWT/+UVtxdyCBqQIm+2z88kwb6iuW3nWQSTUawyYOLeyQz9qOAeVOwa
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
      selftests/net: packetdrill: add TCP black hole detection test
      selftests/net: packetdrill: add TCP MTU probing test

 net/ipv4/tcp_input.c                               |  2 +-
 net/ipv4/tcp_ipv4.c                                |  1 +
 net/ipv6/tcp_ipv6.c                                |  1 +
 .../net/packetdrill/tcp_mtu_probing_blackhole.pkt  | 37 +++++++++++++++++++
 .../net/packetdrill/tcp_mtu_probing_passive.pkt    | 27 ++++++++++++++
 .../net/packetdrill/tcp_mtu_probing_search.pkt     | 42 ++++++++++++++++++++++
 6 files changed, 109 insertions(+), 1 deletion(-)
---
base-commit: fa5196392691051963726787944db872420dfa75
change-id: 20261103-mtu-probing-series-a87b39fdbedf

Best regards,
--  
Yongjian Wang <echoowall@gmail.com>

