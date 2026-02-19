From: Simon Baatz <gmbnomis@gmail.com>
Date: Fri, 20 Feb 2026 00:55:17 +0100
Subject: [PATCH RFC net-next 4/4] selftests/net: packetdrill: add
 tcp_rcv_toobig_back_to_back.pkt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-tcp_rfc7323_retract_wnd_rfc-v1-4-904942561479@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771545363; l=1646;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=c1eQDsHINo/iLpDzO11WhQUeLWxzIkGGeSmjjLGkjpQ=;
 b=tGiZqmdvVs1iMDN93UHdsZnv90evQhVamdSvCoez+vPECABVnnhvp0nW717BsblYUJtRlcHaH
 oPH4k/Yj/LuCnEItmj3gZHey/IHNif1Hx88V/lBkZm2UFDkSKgvE2qo
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This test verifies the sequence number checks using the maximum
advertised window sequence number when we accept a packet going beyond
any window that was ever advertised (i.e. rcv_nxt advances beyond
rcv_mwnd_seq).

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../packetdrill/tcp_rcv_toobig_back_to_back.pkt    | 27 ++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_toobig_back_to_back.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_toobig_back_to_back.pkt
new file mode 100644
index 0000000000000000000000000000000000000000..4d4c33d248948d3dfaf9b0c5b243ed27321e9b10
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_toobig_back_to_back.pkt
@@ -0,0 +1,27 @@
+// SPDX-License-Identifier: GPL-2.0
+
+--mss=1000
+
+`./defaults.sh`
+
+// Establish a connection.
+   +0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 setsockopt(3, SOL_SOCKET, SO_RCVBUF, [20000], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 32792 <mss 1000,nop,wscale 7>
+   +0 > S. 0:0(0) ack 1 win 18980 <mss 1460,nop,wscale 0>
+  +.1 < . 1:1(0) ack 1 win 257
+
+   +0 accept(3, ..., ...) = 4
+
+// A too big packet is accepted if the receive queue is empty
+   +0 < P. 1:20001(20000) ack 1 win 257
+// Send a RST immediately so that there is no rcv_wup/rcv_mwnd_seq update yet
+   +0 < R. 20001:20001(0) ack 1 win 257
+//    * > .  1:1(0) ack 20001 win 18000
+
+  +.1 %{ assert tcpi_state == TCP_CLOSE, tcpi_state }%
+

-- 
2.52.0

