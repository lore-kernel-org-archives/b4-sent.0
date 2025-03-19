From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 19 Mar 2025 03:13:38 +0000
Subject: [PATCH net-next v2 5/7] selftests/net: Print the testing side in
 unsigned-md5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-tcp-ao-selftests-polling-v2-5-da48040153d1@gmail.com>
References: <20250319-tcp-ao-selftests-polling-v2-0-da48040153d1@gmail.com>
In-Reply-To: <20250319-tcp-ao-selftests-polling-v2-0-da48040153d1@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>, Dmitry Safonov <0x7f454c46@gmail.com>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742354050; l=6683;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=ydYQTERZSZOIrkX7tioZa86cOGyjJIFbeHHeiWz4Tmo=;
 b=rJkngdPcft4GRfNcmLEvk1RAGd52w2jCUdytvIwpLP+Afhlaf4DQaGcA06r/bbrZpBiED59G4
 1/fz5ulq/7YADqz5GFtKfBo/TVg42Tgm2/mE5qXHm7ovCH6NGQbQPGE
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As both client and server print the same test name on failure or pass,
add "[server]" so that it's more obvious from a log which side printed
"ok" or "not ok".

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/unsigned-md5.c | 44 +++++++++++------------
 1 file changed, 22 insertions(+), 22 deletions(-)

diff --git a/tools/testing/selftests/net/tcp_ao/unsigned-md5.c b/tools/testing/selftests/net/tcp_ao/unsigned-md5.c
index 4cde2c9f7f49c9ae5a7e1bf73745ef77c7b4706a..a1467b64390adcb5904c02fcfc378a37e989a8bd 100644
--- a/tools/testing/selftests/net/tcp_ao/unsigned-md5.c
+++ b/tools/testing/selftests/net/tcp_ao/unsigned-md5.c
@@ -157,80 +157,80 @@ static void *server_fn(void *arg)
 
 	server_add_routes();
 
-	try_accept("AO server (INADDR_ANY): AO client", port++, NULL, 0,
+	try_accept("[server] AO server (INADDR_ANY): AO client", port++, NULL, 0,
 		   &addr_any, 0, 0, 100, 100, 0, "TCPAOGood",
 		   TEST_CNT_GOOD, 0, 0);
-	try_accept("AO server (INADDR_ANY): MD5 client", port++, NULL, 0,
+	try_accept("[server] AO server (INADDR_ANY): MD5 client", port++, NULL, 0,
 		   &addr_any, 0, 0, 100, 100, 0, "TCPMD5Unexpected",
 		   TEST_CNT_NS_MD5_UNEXPECTED, 1, FAULT_TIMEOUT);
-	try_accept("AO server (INADDR_ANY): no sign client", port++, NULL, 0,
+	try_accept("[server] AO server (INADDR_ANY): no sign client", port++, NULL, 0,
 		   &addr_any, 0, 0, 100, 100, 0, "TCPAORequired",
 		   TEST_CNT_AO_REQUIRED, 0, FAULT_TIMEOUT);
-	try_accept("AO server (AO_REQUIRED): AO client", port++, NULL, 0,
+	try_accept("[server] AO server (AO_REQUIRED): AO client", port++, NULL, 0,
 		   &this_ip_dest, TEST_PREFIX, true,
 		   100, 100, 0, "TCPAOGood", TEST_CNT_GOOD, 0, 0);
-	try_accept("AO server (AO_REQUIRED): unsigned client", port++, NULL, 0,
+	try_accept("[server] AO server (AO_REQUIRED): unsigned client", port++, NULL, 0,
 		   &this_ip_dest, TEST_PREFIX, true,
 		   100, 100, 0, "TCPAORequired",
 		   TEST_CNT_AO_REQUIRED, 0, FAULT_TIMEOUT);
 
-	try_accept("MD5 server (INADDR_ANY): AO client", port++, &addr_any, 0,
+	try_accept("[server] MD5 server (INADDR_ANY): AO client", port++, &addr_any, 0,
 		   NULL, 0, 0, 0, 0, 0, "TCPAOKeyNotFound",
 		   TEST_CNT_NS_KEY_NOT_FOUND, 1, FAULT_TIMEOUT);
-	try_accept("MD5 server (INADDR_ANY): MD5 client", port++, &addr_any, 0,
+	try_accept("[server] MD5 server (INADDR_ANY): MD5 client", port++, &addr_any, 0,
 		   NULL, 0, 0, 0, 0, 0, NULL, 0, 1, 0);
-	try_accept("MD5 server (INADDR_ANY): no sign client", port++, &addr_any,
+	try_accept("[server] MD5 server (INADDR_ANY): no sign client", port++, &addr_any,
 		   0, NULL, 0, 0, 0, 0, 0, "TCPMD5NotFound",
 		   TEST_CNT_NS_MD5_NOT_FOUND, 1, FAULT_TIMEOUT);
 
-	try_accept("no sign server: AO client", port++, NULL, 0,
+	try_accept("[server] no sign server: AO client", port++, NULL, 0,
 		   NULL, 0, 0, 0, 0, 0, "TCPAOKeyNotFound",
 		   TEST_CNT_NS_KEY_NOT_FOUND, 0, FAULT_TIMEOUT);
-	try_accept("no sign server: MD5 client", port++, NULL, 0,
+	try_accept("[server] no sign server: MD5 client", port++, NULL, 0,
 		   NULL, 0, 0, 0, 0, 0, "TCPMD5Unexpected",
 		   TEST_CNT_NS_MD5_UNEXPECTED, 1, FAULT_TIMEOUT);
-	try_accept("no sign server: no sign client", port++, NULL, 0,
+	try_accept("[server] no sign server: no sign client", port++, NULL, 0,
 		   NULL, 0, 0, 0, 0, 0, "CurrEstab", 0, 0, 0);
 
-	try_accept("AO+MD5 server: AO client (matching)", port++,
+	try_accept("[server] AO+MD5 server: AO client (matching)", port++,
 		   &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, "TCPAOGood", TEST_CNT_GOOD, 1, 0);
-	try_accept("AO+MD5 server: AO client (misconfig, matching MD5)", port++,
+	try_accept("[server] AO+MD5 server: AO client (misconfig, matching MD5)", port++,
 		   &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, "TCPAOKeyNotFound", TEST_CNT_AO_KEY_NOT_FOUND,
 		   1, FAULT_TIMEOUT);
-	try_accept("AO+MD5 server: AO client (misconfig, non-matching)", port++,
+	try_accept("[server] AO+MD5 server: AO client (misconfig, non-matching)", port++,
 		   &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, "TCPAOKeyNotFound", TEST_CNT_AO_KEY_NOT_FOUND,
 		   1, FAULT_TIMEOUT);
-	try_accept("AO+MD5 server: MD5 client (matching)", port++,
+	try_accept("[server] AO+MD5 server: MD5 client (matching)", port++,
 		   &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, NULL, 0, 1, 0);
-	try_accept("AO+MD5 server: MD5 client (misconfig, matching AO)", port++,
+	try_accept("[server] AO+MD5 server: MD5 client (misconfig, matching AO)", port++,
 		   &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, "TCPMD5Unexpected",
 		   TEST_CNT_NS_MD5_UNEXPECTED, 1, FAULT_TIMEOUT);
-	try_accept("AO+MD5 server: MD5 client (misconfig, non-matching)", port++,
+	try_accept("[server] AO+MD5 server: MD5 client (misconfig, non-matching)", port++,
 		   &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, "TCPMD5Unexpected",
 		   TEST_CNT_NS_MD5_UNEXPECTED, 1, FAULT_TIMEOUT);
-	try_accept("AO+MD5 server: no sign client (unmatched)", port++,
+	try_accept("[server] AO+MD5 server: no sign client (unmatched)", port++,
 		   &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, "CurrEstab", 0, 1, 0);
-	try_accept("AO+MD5 server: no sign client (misconfig, matching AO)",
+	try_accept("[server] AO+MD5 server: no sign client (misconfig, matching AO)",
 		   port++, &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, "TCPAORequired",
 		   TEST_CNT_AO_REQUIRED, 1, FAULT_TIMEOUT);
-	try_accept("AO+MD5 server: no sign client (misconfig, matching MD5)",
+	try_accept("[server] AO+MD5 server: no sign client (misconfig, matching MD5)",
 		   port++, &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, "TCPMD5NotFound",
 		   TEST_CNT_NS_MD5_NOT_FOUND, 1, FAULT_TIMEOUT);
 
 	/* Key rejected by the other side, failing short through skpair */
-	try_accept("AO+MD5 server: client with both [TCP-MD5] and TCP-AO keys",
+	try_accept("[server] AO+MD5 server: client with both [TCP-MD5] and TCP-AO keys",
 		   port++, &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, NULL, 0, 1, FAULT_KEYREJECT);
-	try_accept("AO+MD5 server: client with both TCP-MD5 and [TCP-AO] keys",
+	try_accept("[server] AO+MD5 server: client with both TCP-MD5 and [TCP-AO] keys",
 		   port++, &this_ip_dest, TEST_PREFIX, &client2, TEST_PREFIX, 0,
 		   100, 100, 0, NULL, 0, 1, FAULT_KEYREJECT);
 

-- 
2.42.2

