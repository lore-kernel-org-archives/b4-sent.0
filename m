From: Simon Baatz <gmbnomis@gmail.com>
Date: Wed, 08 Apr 2026 23:50:05 +0200
Subject: [PATCH net-next 4/7] selftests/net: packetdrill: add
 tcp_rcv_wnd_snd_ack_no_scaling.pkt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-4-76a6f212e153@gmail.com>
References: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-0-76a6f212e153@gmail.com>
In-Reply-To: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-0-76a6f212e153@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775685040; l=2164;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=3UD78GSmL8ZM19AY/0d9FZwB1822EnTOwXfy0idIPhY=;
 b=63aS0f7Hf24M3Z/9aXF1uyxaeIDIWMqQkDKXmH8Hxy4rrkgc1FEZ7MtW3FgIkJvPfqK0z/qfd
 u97GMpuJIHPDF0MiaLdaaSjz5tHe8Pgvs16YbUeZWernVMwjfqY+hly
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Verify that, when no TCP window scaling is used, each packet that
substantially advances the right edge of the receive window is ACKed
immediately.

Multiple packets are used so that the scaling_ratio receive window
adaptation can settle and does not by itself cause immediate ACKs,
avoiding false positives.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../packetdrill/tcp_rcv_wnd_snd_ack_no_scaling.pkt | 37 ++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_snd_ack_no_scaling.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_snd_ack_no_scaling.pkt
new file mode 100644
index 0000000000000..41561b026da85
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_snd_ack_no_scaling.pkt
@@ -0,0 +1,37 @@
+// SPDX-License-Identifier: GPL-2.0
+//
+// Every packet must be ACKed immediately if the right edge of receive window
+// advances substantially. This test verifies that behavior when the connection
+// does not use window scaling.
+--mss=1000
+
+`./defaults.sh`
+
+// Initialize connection
+    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 setsockopt(3, SOL_SOCKET, SO_RCVBUF, [256000], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 32792
+   +0 > S. 0:0(0) ack 1 win 65535 <mss 1460>
+   +0 < . 1:1(0) ack 1 win 32792
+
+   +0 accept(3, ..., ...) = 4
+
+   +0 < P. 1:65001(65000) ack 1 win 32792
+   +0 > . 1:1(0) ack 65001 win 65535
+   +0 < P. 65001:130001(65000) ack 1 win 32792
+   +0 > . 1:1(0) ack 130001 win 65535
+   +0 < P. 130001:195001(65000) ack 1 win 32792
+   +0 > . 1:1(0) ack 195001 win 65535
+   +0 < P. 195001:260001(65000) ack 1 win 32792
+   +0 > . 1:1(0) ack 260001 win 65535
+   +0 < P. 260001:325001(65000) ack 1 win 32792
+   +0 > . 1:1(0) ack 325001 win 65535
+
+// reading all data does not open the window further -> no ACK
+   +0 read(4, ..., 325000) = 325000
+ +0.2 < P. 325001:390001(65000) ack 1 win 32792
+   +0 > . 1:1(0) ack 390001 win 65535

-- 
2.53.0

