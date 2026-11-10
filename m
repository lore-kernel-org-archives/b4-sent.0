From: Yongjian Wang <echoowall@gmail.com>
Date: Wed, 11 Nov 2026 00:45:56 +0800
Subject: [PATCH net-next v4 2/4] selftests/net: packetdrill: test
 tcp_base_mss on passive connections
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-mtu-probing-series-v4-2-6f2e484ca8ea@gmail.com>
References: <20261111-mtu-probing-series-v4-0-6f2e484ca8ea@gmail.com>
In-Reply-To: <20261111-mtu-probing-series-v4-0-6f2e484ca8ea@gmail.com>
To: pabeni@redhat.com, kuba@kernel.org, shuah@kernel.org, 
 edumazet@kernel.org, horms@kernel.org, kuniyu@google.com, 
 ncardwell@google.com, davem@davemloft.net
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 netdev@vger.kernel.org, panweiping3@gmail.com, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794329156; l=1599;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=3lQsY78vSTiBOpqp4bdac9scSAkC/asJAFx3o/C4nk4=;
 b=KlldzqTr+zVzxlntQk6qL3845h9aSVYsDMJB7yZ+xOEeVyu5/nQTgumE/1UvAkJnrWzaeoJsI
 dv651n3WLjlA4RQ3jCzJFjwofZsYaDxxIZUSau/vUpeDfmsPiP2xN3+
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check that a passive connection starts at tcp_base_mss with
net.ipv4.tcp_mtu_probing=2, as an active connection does.

Signed-off-by: Yongjian Wang <echoowall@gmail.com>
---
 .../net/packetdrill/tcp_mtu_probing_passive.pkt    | 27 ++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_passive.pkt b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_passive.pkt
new file mode 100644
index 000000000000..14bae144cce2
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_passive.pkt
@@ -0,0 +1,27 @@
+// SPDX-License-Identifier: GPL-2.0
+// Test that a passive connection starts at tcp_base_mss with tcp_mtu_probing=2,
+// the same way as an active connection.
+
+`./defaults.sh
+sysctl -q net.ipv4.tcp_mtu_probing=2
+sysctl -q net.ipv4.tcp_base_mss=1024
+sysctl -q net.ipv4.tcp_timestamps=0`
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
+// The initial window is sent with tcp_base_mss, not the peer's MSS.
+   +0 write(4, ..., 10240) = 10240
+   +0 > P. 1:2049(2048) ack 1
+   +0 > P. 2049:4097(2048) ack 1
+   +0 > P. 4097:6145(2048) ack 1
+   +0 > P. 6145:8193(2048) ack 1
+   +0 > P. 8193:10241(2048) ack 1
+  +.1 < . 1:1(0) ack 10241 win 65535

-- 
Git-157)

