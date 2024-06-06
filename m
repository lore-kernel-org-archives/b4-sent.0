From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Fri, 07 Jun 2024 00:26:00 +0100
Subject: [PATCH net-next v4 6/6] Documentation/tcp-ao: Add a few lines on
 tracepoints
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240607-tcp_ao-tracepoints-v4-6-88dc245c1f39@gmail.com>
References: <20240607-tcp_ao-tracepoints-v4-0-88dc245c1f39@gmail.com>
In-Reply-To: <20240607-tcp_ao-tracepoints-v4-0-88dc245c1f39@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, David Ahern <dsahern@kernel.org>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, Simon Horman <horms@kernel.org>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717716372; l=1312;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=YTvLVmZiUq3+/gRlZqmFldpsbcd2Jw9oBAFB4f9XdXg=;
 b=yBoZ3XI+U9N6yjIg9OPIw3XAbfb8H+9R7O49RdavjZgRFul6opVKoRDnbgKXoKGQovgFtKxRwu+n
 /JokHbbvCr7fWvjB6R2vjraI3PWvVf5wugCuxEAWZ2bR5C3ZQDss
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 Documentation/networking/tcp_ao.rst | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/networking/tcp_ao.rst b/Documentation/networking/tcp_ao.rst
index 8a58321acce7..e96e62d1dab3 100644
--- a/Documentation/networking/tcp_ao.rst
+++ b/Documentation/networking/tcp_ao.rst
@@ -337,6 +337,15 @@ TCP-AO per-socket counters are also duplicated with per-netns counters,
 exposed with SNMP. Those are ``TCPAOGood``, ``TCPAOBad``, ``TCPAOKeyNotFound``,
 ``TCPAORequired`` and ``TCPAODroppedIcmps``.
 
+For monitoring purposes, there are following TCP-AO trace events:
+``tcp_hash_bad_header``, ``tcp_hash_ao_required``, ``tcp_ao_handshake_failure``,
+``tcp_ao_wrong_maclen``, ``tcp_ao_wrong_maclen``, ``tcp_ao_key_not_found``,
+``tcp_ao_rnext_request``, ``tcp_ao_synack_no_key``, ``tcp_ao_snd_sne_update``,
+``tcp_ao_rcv_sne_update``. It's possible to separately enable any of them and
+one can filter them by net-namespace, 4-tuple, family, L3 index, and TCP header
+flags. If a segment has a TCP-AO header, the filters may also include
+keyid, rnext, and maclen. SNE updates include the rolled-over numbers.
+
 RFC 5925 very permissively specifies how TCP port matching can be done for
 MKTs::
 

-- 
2.42.0

