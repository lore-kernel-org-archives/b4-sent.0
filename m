From: Yongjian Wang <echoowall@gmail.com>
Date: Mon, 23 Nov 2026 19:04:10 +0800
Subject: [PATCH net-next v3 2/2] selftests/net: packetdrill: test
 tcp_mtu_probe_floor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-tcp-mtu-probing-doc-v1-v3-2-c288c2df9666@gmail.com>
References: <20261123-tcp-mtu-probing-doc-v1-v3-0-c288c2df9666@gmail.com>
In-Reply-To: <20261123-tcp-mtu-probing-doc-v1-v3-0-c288c2df9666@gmail.com>
To: corbet@lwn.net, kuba@kernel.org, edumazet@kernel.org, pabeni@redhat.com, 
 davem@davemloft.net, shuah@kernel.org
Cc: Yongjian Wang <echoowall@gmail.com>, ncardwell@google.com, 
 kuniyu@google.com, rdunlap@infradead.org, linux-kselftest@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, skhan@linuxfoundation.org, horms@kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795431849; l=2254;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=L2mM/OhObLn59aLpNJ9Spn+BLz/qgLoUlYL6TTs8CZQ=;
 b=3V8xSAG8iabgXfHb/kqahTVUGbuhiAxkOHPUCsW3ZCsx63YVBJMhGj9eT4AgqJMBi2224D5Ab
 GlroLvG6p5qDpMJ7QPV0620sAitddv4LfNE36jGAfM1NGJJwWEXoq/J
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tcp_mtu_probe_floor has no selftest coverage.

Add a test where a full-sized segment keeps timing out without any ICMP
feedback. After the first detection falls back to tcp_base_mss, check
that each further retransmission timeout halves the MSS, and that the
MSS stops at tcp_mtu_probe_floor.

Use tcp_retries1=1 and disable TLP, as in
tcp_mtu_probing_blackhole_no_tlp_retries1_is_1.pkt, so that every
retransmission comes from the RTO timer.

Signed-off-by: Yongjian Wang <echoowall@gmail.com>
Reviewed-by: Kuniyuki Iwashima <kuniyu@google.com>
---
 .../tcp_mtu_probing_blackhole_floor.pkt            | 37 ++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole_floor.pkt b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole_floor.pkt
new file mode 100644
index 000000000000..dd040d9beca0
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole_floor.pkt
@@ -0,0 +1,37 @@
+// SPDX-License-Identifier: GPL-2.0
+// Test that after black hole detection, each further retransmission timeout
+// halves the MSS, but not below tcp_mtu_probe_floor.
+
+`./defaults.sh
+sysctl -q net.ipv4.tcp_mtu_probing=1
+sysctl -q net.ipv4.tcp_base_mss=1024
+sysctl -q net.ipv4.tcp_mtu_probe_floor=300
+sysctl -q net.ipv4.tcp_retries1=1
+sysctl -q net.ipv4.tcp_early_retrans=0`
+
+    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 65535 <mss 1460,nop,nop,sackOK>
+   +0 > S. 0:0(0) ack 1 <mss 1460,nop,nop,sackOK>
+  +.1 < . 1:1(0) ack 1 win 65535
+   +0 accept(3, ..., ...) = 4
+
+   +0 write(4, ..., 1460) = 1460
+   +0 > P. 1:1461(1460) ack 1
+  +.3 > P. 1:1461(1460) ack 1
+
+// The first detection falls back to tcp_base_mss.
+  +.6 > . 1:1025(1024) ack 1
+
+// Each further timeout halves the MSS.
+ +1.2 > . 1:513(512) ack 1
+
+// Half of 512 is below tcp_mtu_probe_floor, so the floor is used.
+ +2.4 > . 1:301(300) ack 1
+
+// The MSS does not go below the floor.
+ +4.8 > . 1:301(300) ack 1
+  +.1 < . 1:1(0) ack 1461 win 65535

-- 
Git-157)

