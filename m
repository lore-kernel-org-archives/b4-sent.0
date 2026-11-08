From: Yongjian Wang <echoowall@gmail.com>
Subject: [PATCH net-next v2 0/4] tcp: fix tcp_base_mss on passive
 connections and test MTU probing
Date: Sun, 08 Nov 2026 22:39:50 +0800
Message-Id: <20261108-mtu-probing-series-v2-0-355d6490c3db@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALaJ8GoC/32NzQ6CMBCEX4Xs2TVtiQKefA/DoYUF1khL2kIwh
 HeXn7vHycw33wKBPFOAR7KAp4kDO7sFdUmg6rRtCbneMiih7lKKFPs44uCdYdviyaLOM5MWTW2
 obmADB08Nz8fpCyxFtDRHKM8mjOZNVdw/923HITr/PfyTPIh/qkmiQK1yUVCmblrrZ9tr/lwr1
 0O5rusP5Xx3w9AAAAA=
X-Change-ID: 20261103-mtu-probing-series-a87b39fdbedf
To: davem@davemloft.net, pabeni@redhat.com, ncardwell@google.com, 
 horms@kernel.org, kuba@kernel.org, kuniyu@google.com, shuah@kernel.org, 
 edumazet@kernel.org
Cc: linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 panweiping3@gmail.com, netdev@vger.kernel.org, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794148792; l=1935;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=19c4Gk3Gwmmdf6hcqazZwt4ILAXYtGIkiZQuAikm1yE=;
 b=lsncIAFuU5jy3vx7rFvzCCDrgzTHmMBJXO9pb8CuTOJIbro6eZmufAC0uCoBMgQMAujaU2d0m
 AhkcMvtSmitAqXR5SheoluhamBWjXdtlJYOE25fEXTuQJY3BI+yU6T+
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

Tested on x86_64 KVM with all 496 packetdrill cases passing, plus
targeted checks for simultaneous open and Fast Open with MTU probing
enabled. The three affected TCP objects also build with W=1 under
allyesconfig and allmodconfig.

---
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
 .../net/packetdrill/tcp_mtu_probing_search.pkt     | 43 ++++++++++++++++++++++
 6 files changed, 110 insertions(+), 1 deletion(-)
---
base-commit: fa5196392691051963726787944db872420dfa75
change-id: 20261103-mtu-probing-series-a87b39fdbedf

Best regards,
--  
Yongjian Wang <echoowall@gmail.com>

