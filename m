From: Yongjian Wang <echoowall@gmail.com>
Date: Wed, 18 Nov 2026 16:10:53 +0800
Subject: [PATCH net-next v2 2/2] selftests/net: packetdrill: test
 tcp_mtu_probe_floor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-tcp-mtu-probing-doc-v1-v2-2-e795f20b8cfe@gmail.com>
References: <20261118-tcp-mtu-probing-doc-v1-v2-0-e795f20b8cfe@gmail.com>
In-Reply-To: <20261118-tcp-mtu-probing-doc-v1-v2-0-e795f20b8cfe@gmail.com>
To: corbet@lwn.net, edumazet@kernel.org, davem@davemloft.net, 
 kuba@kernel.org, shuah@kernel.org, pabeni@redhat.com
Cc: Yongjian Wang <echoowall@gmail.com>, rdunlap@infradead.org, 
 linux-doc@vger.kernel.org, horms@kernel.org, ncardwell@google.com, 
 kuniyu@google.com, skhan@linuxfoundation.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794989453; l=2202;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=WrcY9iXn4SXDQlJWipeiEC5l8GUQMcBnGkZOHeOty8w=;
 b=WhNkoerzSliW4HHWgcU2HRPh+ONRc6XzzwRKlmUOnmhFoedAJM0lNeXSM7bwGvL/5QpJhlKl9
 2wyyDcXXhNtCgrkY5VPaXeXsTRwYH8x3PwUumkHq7tnouREhinNc4Lh
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

