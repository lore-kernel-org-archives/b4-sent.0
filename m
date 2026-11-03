From: Yongjian Wang <echoowall@gmail.com>
Subject: [PATCH net-next 0/4] tcp: fix tcp_base_mss on passive connections
 and test MTU probing
Date: Tue, 03 Nov 2026 15:09:40 +0800
Message-Id: <20261103-mtu-probing-series-v1-0-a2809e725aaa@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALSI6WoC/yWMwQqDMBAFf0XeuQtGwbb+ivRgzMZuoaskUQTx3
 03rcRhmdkQOwhFtsSPwKlEmzWBuBYZ3ryOTuMyoyqoxpqzpmxaaw2RFR7pa6h93Wz+9s+w8cjg
 H9rL9px2UEylvCa/LxMV+eEi/J47jBKx0Vy6AAAAA
X-Change-ID: 20261103-mtu-probing-series-a87b39fdbedf
To: ncardwell@google.com, horms@kernel.org, edumazet@kernel.org, 
 kuba@kernel.org, kuniyu@google.com, shuah@kernel.org, davem@davemloft.net, 
 pabeni@redhat.com
Cc: netdev@vger.kernel.org, panweiping3@gmail.com, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793689782; l=1412;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=jaAiv7oc3XrWZgOFj0uLPEs+taPtXcOPn4WA+vqNjCA=;
 b=R0ssqhNpJtIIHhSW9RvoiT8+/dGCb3h6d3O0KPiv9vOh9NXFRP2xho9/v7joOVVI+7gvT8doP
 zAUmTlJqhtiC9As3pxD/3ZsBYNPq1EaKoZDsZA+kHGPg4t5nPkXsIIX
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While adding selftests for MTU probing, I noticed that passive
connections do not start at tcp_base_mss with tcp_mtu_probing=2.
Patch 1 fixes that and patch 2 adds a regression test.

This has been wrong since 2014 and only matters with a non-default
sysctl, so I am sending it to net-next. Patch 1 changes behaviour for
users of tcp_mtu_probing=2. Please let me know if you would prefer it
to go through net or to be backported to stable.

Patches 3 and 4 add the missing coverage for black hole detection
(tcp_mtu_probing=1) and for the MTU search on active connections
(tcp_mtu_probing=2).

---
Yongjian Wang (4):
      tcp: sync MSS after enabling MTU probing on passive connections
      selftests/net: packetdrill: test tcp_base_mss on passive connections
      selftests/net: packetdrill: add TCP black hole detection test
      selftests/net: packetdrill: add TCP MTU probing test

 net/ipv4/tcp_input.c                               |  1 +
 .../net/packetdrill/tcp_mtu_probing_blackhole.pkt  | 37 +++++++++++++++++++
 .../net/packetdrill/tcp_mtu_probing_passive.pkt    | 27 ++++++++++++++
 .../net/packetdrill/tcp_mtu_probing_search.pkt     | 43 ++++++++++++++++++++++
 4 files changed, 108 insertions(+)
---
base-commit: 4dd16e31135ea8437a720222df34e8745f385d6d
change-id: 20261103-mtu-probing-series-a87b39fdbedf

Best regards,
--  
Yongjian Wang <echoowall@gmail.com>

