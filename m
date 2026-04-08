From: Simon Baatz <gmbnomis@gmail.com>
Date: Wed, 08 Apr 2026 23:50:06 +0200
Subject: [PATCH net-next 5/7] selftests/net: packetdrill: add
 TCP_WINDOW_CLAMP test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-5-76a6f212e153@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775685040; l=1779;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=hTLTER1y0lqFNVxFYgmLQOhJrfwaiyL20oWEx5ESl0s=;
 b=3LrMJhspiTFgK4hTMJxNxNE0+Cy3LA+4CJRvHndFJSg8VcDt4Mo8qZUb+b2ZSwOQiH3LYup9X
 xj6E/4b/5RwDf4i4f4vfoGWlfSpcJ6oOPHWRKkPHTLLaFCWWRcoigDY
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a packetdrill test to verify that the socket option
TCP_WINDOW_CLAMP can be set to a large value on a listening socket,
but is clamped on an established socket to the maximum representable
advertised window.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../net/packetdrill/tcp_rcv_sockopt_wnd_clamp.pkt  | 28 ++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_sockopt_wnd_clamp.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_sockopt_wnd_clamp.pkt
new file mode 100644
index 0000000000000..d7203f2893c3f
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_sockopt_wnd_clamp.pkt
@@ -0,0 +1,28 @@
+// SPDX-License-Identifier: GPL-2.0
+//
+// Verify that TCP_WINDOW_CLAMP can be set to a high value on a LISTEN socket, but,
+// in an established connection, the value is clamped to the maximum representable
+// advertised window.
+--mss=1000
+
+`./defaults.sh`
+
+// Initialize connection
+    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 setsockopt(3, SOL_SOCKET, SO_RCVBUF, [256000], 4) = 0
+   +0 setsockopt(3, IPPROTO_TCP, 10, [255999], 4) = 0  // TCP_WINDOW_CLAMP == 10
+   +0 getsockopt(3, IPPROTO_TCP, 10, [255999], [4]) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 32792
+   +0 > S. 0:0(0) ack 1 win 65535 <mss 1460>
+   +0 < . 1:1(0) ack 1 win 32792
+
+   +0 accept(3, ..., ...) = 4
+
+   +0 getsockopt(4, IPPROTO_TCP, 10, [65535], [4]) = 0
+   +0 setsockopt(4, IPPROTO_TCP, 10, [255999], 4) = 0
+   +0 getsockopt(4, IPPROTO_TCP, 10, [65535], [4]) = 0
+   +0 getsockopt(3, IPPROTO_TCP, 10, [255999], [4]) = 0

-- 
2.53.0

