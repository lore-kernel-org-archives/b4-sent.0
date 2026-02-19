From: Simon Baatz <gmbnomis@gmail.com>
Date: Fri, 20 Feb 2026 00:55:15 +0100
Subject: [PATCH RFC net-next 2/4] selftests/net: packetdrill: add
 tcp_rcv_wnd_shrink_nomem.pkt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-tcp_rfc7323_retract_wnd_rfc-v1-2-904942561479@gmail.com>
References: <20260220-tcp_rfc7323_retract_wnd_rfc-v1-0-904942561479@gmail.com>
In-Reply-To: <20260220-tcp_rfc7323_retract_wnd_rfc-v1-0-904942561479@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 David Ahern <dsahern@kernel.org>, Stefano Brivio <sbrivio@redhat.com>, 
 Jon Maloy <jmaloy@redhat.com>, Jason Xing <kerneljasonxing@gmail.com>, 
 mfreemon@cloudflare.com, Shuah Khan <shuah@kernel.org>
Cc: Christian Ebner <c.ebner@proxmox.com>, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771545363; l=4471;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=shV3LeyDSvHNPDJqS+FQdEgy1T49GBnnSnb8us2W3og=;
 b=xGZKGivQ75Ms7KtqBRvjePpsdXIw+/G4oWgp1g+CzycNYrcnAwOtWiY9hsL4KToDT8FLXToES
 V0voxoqwpiwC3C/MBoJt0pk1a0rHfpEh0iEq+0x32DiNfMH1ITfTLKw
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This test verifies the sequence number checks using the maximum
advertised window sequence number. Cases:

1. The window is reduced to zero because of memory

2. The window grows again but still does not reach the originally
   advertised window

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt   | 109 +++++++++++++++++++++
 1 file changed, 109 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt
new file mode 100644
index 0000000000000000000000000000000000000000..cd761300d02df449ff68cd6ff6f3b8ac62d5f27b
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt
@@ -0,0 +1,109 @@
+// SPDX-License-Identifier: GPL-2.0
+
+--mss=1000
+
+`./defaults.sh
+sysctl -q net.ipv4.tcp_rmem="4096 32768 $((32*1024*1024))"`
+
+    0 `nstat -n`
+
+// Establish a connection.
+   +0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 32792 <mss 1000,nop,wscale 7>
+   +0 > S. 0:0(0) ack 1 <mss 1460,nop,wscale 10>
+   +0 < . 1:1(0) ack 1 win 257
+
+  +0 accept(3, ..., ...) = 4
+
+  +0 < P. 1:10001(10000) ack 1 win 257
+   * > .  1:1(0) ack 10001 win 16
+
+// Segments smaller than the window scale factor do not allow to reduce the adv. window
+  +0 < P. 10001:11024(1023) ack 1 win 257
+  * > .  1:1(0) ack 11024 win 16
+  +0 < P. 11024:12047(1023) ack 1 win 257
+  * > .  1:1(0) ack 12047 win 16
+  +0 < P. 12047:13070(1023) ack 1 win 257
+  * > .  1:1(0) ack 13070 win 16
+  +0 < P. 13070:14093(1023) ack 1 win 257
+  * > .  1:1(0) ack 14093 win 16
+  +0 < P. 14093:15116(1023) ack 1 win 257
+  * > .  1:1(0) ack 15116 win 16
+  +0 < P. 15116:16139(1023) ack 1 win 257
+  * > .  1:1(0) ack 16139 win 16
+  +0 < P. 16139:17162(1023) ack 1 win 257
+  * > .  1:1(0) ack 17162 win 16
+  +0 < P. 17162:18185(1023) ack 1 win 257
+  * > .  1:1(0) ack 18185 win 16
+  +0 < P. 18185:19208(1023) ack 1 win 257
+  * > .  1:1(0) ack 19208 win 16
+  +0 < P. 19208:20231(1023) ack 1 win 257
+  * > .  1:1(0) ack 20231 win 16
+  +0 < P. 20231:21254(1023) ack 1 win 257
+  * > .  1:1(0) ack 21254 win 16
+  +0 < P. 21254:22277(1023) ack 1 win 257
+  * > .  1:1(0) ack 22277 win 16
+  +0 < P. 22277:23300(1023) ack 1 win 257
+  * > .  1:1(0) ack 23300 win 16
+  +0 < P. 23300:24323(1023) ack 1 win 257
+  * > .  1:1(0) ack 24323 win 16
+  +0 < P. 24323:25346(1023) ack 1 win 257
+  * > .  1:1(0) ack 25346 win 16
+  +0 < P. 25346:26369(1023) ack 1 win 257
+  * > .  1:1(0) ack 26369 win 16
+  +0 < P. 26369:27392(1023) ack 1 win 257
+  * > .  1:1(0) ack 27392 win 16
+  +0 < P. 27392:28415(1023) ack 1 win 257
+  * > .  1:1(0) ack 28415 win 16
+  +0 < P. 28415:29438(1023) ack 1 win 257
+  * > .  1:1(0) ack 29438 win 16
+  +0 < P. 29438:30461(1023) ack 1 win 257
+  * > .  1:1(0) ack 30461 win 16
+  +0 < P. 30461:31484(1023) ack 1 win 257
+  * > .  1:1(0) ack 31484 win 16
+  +0 < P. 31484:32507(1023) ack 1 win 257
+  * > .  1:1(0) ack 32507 win 16
+  +0 < P. 32507:33530(1023) ack 1 win 257
+  * > .  1:1(0) ack 33530 win 16
+
+// rcv buffer out of memory
+  +0 < P. 33530:49914(16384) ack 1 win 257
+  +0 > .  1:1(0) ack 33530 win 0
+
+// max window seq advertised 33530 + 16*1024 = 49914
+
+  +0 write(4, ..., 1000) = 1000
+  +0 > P.  1:1001(1000) ack 33530 win 0
+
+// LINUX_MIB_BEYOND_WINDOW: segment is beyond the max window sequence
+  +0 < . 49915:49915(0) ack 1001 win 257
+  +0 > . 1001:1001(0) ack 33530 win 0
+
+  +0 < . 49914:49914(0) ack 1001 win 257
+
+  +0 %{
+assert tcpi_bytes_acked == 1000, tcpi_bytes_acked
+}%
+
+  +0 read(4, ..., 10000) = 10000
+  +0 > .  1001:1001(0) ack 33530 win 9
+
+  +0 write(4, ..., 1000) = 1000
+  +0 > P.  1001:2001(1000) ack 33530 win 9
+
+  // advertise right edge is 33530 + 9*1024 = 42746, but we still need to regard our maximum offer 49914 as in window
+  +0 < . 49914:49914(0) ack 2001 win 257
+
+  +0 %{
+assert tcpi_bytes_acked == 2000, tcpi_bytes_acked
+}%
+
+  +0 < P. 33530:42746(9216) ack 2001 win 257
+   * > .  2001:2001(0) ack 42746 win 0
+
+// Check LINUX_MIB_BEYOND_WINDOW has been incremented once
+  +0 `nstat | grep TcpExtBeyondWindow | grep -q " 1 "`

-- 
2.52.0

