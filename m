From: Simon Baatz <gmbnomis@gmail.com>
Date: Thu, 26 Feb 2026 01:49:10 +0100
Subject: [PATCH RFC net-next v2 4/5] selftests/net: packetdrill: add
 tcp_rcv_wnd_shrink_allowed.pkt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-4-aa3f8f9cc639@gmail.com>
References: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-0-aa3f8f9cc639@gmail.com>
In-Reply-To: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-0-aa3f8f9cc639@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 David Ahern <dsahern@kernel.org>, Stefano Brivio <sbrivio@redhat.com>, 
 Jon Maloy <jmaloy@redhat.com>, Jason Xing <kerneljasonxing@gmail.com>, 
 mfreemon@cloudflare.com, Shuah Khan <shuah@kernel.org>, 
 Stefano Brivio <sbrivio@redhat.com>
Cc: Christian Ebner <c.ebner@proxmox.com>, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772066964; l=1916;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=MjsZPkGn8QBvDWJIOlx0ttylpFWaDY4F2mI8uGeZDj4=;
 b=YW4cf33OXLAcJwKNDwLdtBUt+Rhl4+Bnu31WmAA5B+E401wN8L3lhdkgqCGNc4YZWFdsBZA01
 9Cz/FplpjcRDdA8KeTgsmKYeCBbPkypbJbSEuuXFaB+go0b6rk930P6
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This test verifies the sequence number checks using the maximum
advertised window sequence number when net.ipv4.tcp_shrink_window
is enabled.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../net/packetdrill/tcp_rcv_wnd_shrink_allowed.pkt | 40 ++++++++++++++++++++++
 1 file changed, 40 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_shrink_allowed.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_shrink_allowed.pkt
new file mode 100644
index 0000000000000000000000000000000000000000..e2c73e464954331f45c11b3152f2eddecc55f88b
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_shrink_allowed.pkt
@@ -0,0 +1,40 @@
+// SPDX-License-Identifier: GPL-2.0
+
+--mss=1000
+
+`./defaults.sh
+sysctl -q net.ipv4.tcp_shrink_window=1
+sysctl -q net.ipv4.tcp_rmem="4096 32768 $((32*1024*1024))"`
+
+   0 `nstat -n`
+
+// Establish a connection.
+  +0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+  +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+  +0 bind(3, ..., ...) = 0
+  +0 listen(3, 1) = 0
+
+  +0 < S 0:0(0) win 32792 <mss 1000,nop,wscale 7>
+  +0 > S. 0:0(0) ack 1 <mss 1460,nop,wscale 10>
+  +0 < . 1:1(0) ack 1 win 257
+
+  +0 accept(3, ..., ...) = 4
+
+  +0 < P. 1:10001(10000) ack 1 win 257
+  * > .  1:1(0) ack 10001 win 15
+
+  +0 < P. 10001:11024(1023) ack 1 win 257
+  * > .  1:1(0) ack 11024 win 13
+
+// Max window seq advertised 10001 + 15*1024 = 25361, last advertised: 11024 + 13*1024 = 24336
+
+// Segment beyond the max window is dropped
+  +0 < P. 11024:25362(14338) ack 1 win 257
+  * > .  1:1(0) ack 11024 win 13
+
+// Segment using the max window is accepted
+  +0 < P. 11024:25361(14337) ack 1 win 257
+  * > .  1:1(0) ack 25361 win 0
+
+// Check LINUX_MIB_BEYOND_WINDOW has been incremented once
+  +0 `nstat | grep TcpExtBeyondWindow | grep -q " 1 "`

-- 
2.53.0

