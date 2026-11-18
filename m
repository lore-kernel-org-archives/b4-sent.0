From: Yongjian Wang <echoowall@gmail.com>
Date: Wed, 18 Nov 2026 16:10:52 +0800
Subject: [PATCH net-next v2 1/2] tcp: document black hole detection for
 tcp_mtu_probing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-tcp-mtu-probing-doc-v1-v2-1-e795f20b8cfe@gmail.com>
References: <20261118-tcp-mtu-probing-doc-v1-v2-0-e795f20b8cfe@gmail.com>
In-Reply-To: <20261118-tcp-mtu-probing-doc-v1-v2-0-e795f20b8cfe@gmail.com>
To: corbet@lwn.net, edumazet@kernel.org, davem@davemloft.net, 
 kuba@kernel.org, shuah@kernel.org, pabeni@redhat.com
Cc: Yongjian Wang <echoowall@gmail.com>, rdunlap@infradead.org, 
 linux-doc@vger.kernel.org, horms@kernel.org, ncardwell@google.com, 
 kuniyu@google.com, skhan@linuxfoundation.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794989453; l=2444;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=ta6f43Q9WCijtV9U1XrIJWYCHAQ4FrHJdfRc+ckR0n8=;
 b=S4lH+mwLEmJOlG3gNxDU33WKSApX7xGkxPBbsThKzrn0lyRgQxF6BY/IaRIex1VXZzX6Fqylt
 pTvvDpGU65vABIK5GKvo5VMuNv+z+nFeD26bUy85582xk+RWcS4iIyj
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ip-sysctl.rst says that tcp_mtu_probing=1 enables MTU probing once an
ICMP black hole is detected, but not when that happens or what TCP
does then.

Describe both, as implemented in tcp_write_timeout() and
tcp_mtu_probing(). Also add the missing defaults of tcp_mtu_probing
and tcp_base_mss.

Signed-off-by: Yongjian Wang <echoowall@gmail.com>
Reviewed-by: Eric Dumazet <edumazet@kernel.org>
---
 Documentation/networking/ip-sysctl.rst | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/Documentation/networking/ip-sysctl.rst b/Documentation/networking/ip-sysctl.rst
index 0b7bfbd98a92..6ac8b3fb9aae 100644
--- a/Documentation/networking/ip-sysctl.rst
+++ b/Documentation/networking/ip-sysctl.rst
@@ -412,6 +412,8 @@ tcp_base_mss - INTEGER
 	Path MTU discovery (MTU probing).  If MTU probing is enabled,
 	this is the initial MSS used by the connection.
 
+	Default: 1024
+
 tcp_mtu_probe_floor - INTEGER
 	If MTU probing is enabled this caps the minimum MSS used for search_low
 	for the connection.
@@ -711,6 +713,25 @@ tcp_mtu_probing - INTEGER
 	- 1 - Disabled by default, enabled when an ICMP black hole detected
 	- 2 - Always enabled, use initial MSS of tcp_base_mss.
 
+	A black hole is detected when the retransmission timer fires after
+	the handshake and retransmissions have stayed unacknowledged for as
+	long as tcp_retries1 retransmissions would take with an RTO starting
+	at 200 ms and doubling each time, which is 3 seconds with the
+	default tcp_retries1. This time is counted from the first
+	retransmission and only checked when the timer fires, so a flow
+	with a 200 ms RTO detects the black hole at the fifth timeout,
+	about 6 seconds after the original transmission.
+
+	With value 1, the first detection enables MTU probing and lowers
+	the MSS to tcp_base_mss if it is larger. From then on, and from the
+	first detection with value 2, each further retransmission timeout
+	lowers search_low to half its MSS, keeping it at most tcp_base_mss
+	and at least tcp_mtu_probe_floor and tcp_min_snd_mss, and lowers the
+	MSS to match if it is larger. Once MTU probing is enabled, the
+	connection also probes for a larger MSS, as with value 2.
+
+	Default: 0
+
 tcp_probe_interval - UNSIGNED INTEGER
 	Controls how often to start TCP Packetization-Layer Path MTU
 	Discovery reprobe. The default is reprobing every 10 minutes as

-- 
Git-157)

