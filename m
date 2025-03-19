From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 19 Mar 2025 03:13:39 +0000
Subject: [PATCH net-next v2 6/7] selftests/net: Delete timeout from
 test_connect_socket()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-tcp-ao-selftests-polling-v2-6-da48040153d1@gmail.com>
References: <20250319-tcp-ao-selftests-polling-v2-0-da48040153d1@gmail.com>
In-Reply-To: <20250319-tcp-ao-selftests-polling-v2-0-da48040153d1@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>, Dmitry Safonov <0x7f454c46@gmail.com>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742354050; l=5727;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=ALMVvlTrm1gvr8aNFWvAU1f6luL58dhhCBbfYPACl7Y=;
 b=Nf9xzs9ZlTnqcBbrKiWEOuX7aS3mkvTbJcZcDgDNH2QtHEpokBOH5gIe/KJwqq20iW5IZpilh
 k8+nGelBLEXAXyVtgsebrlCItE1Qok4thYsvTMuyg1b3/ETm8sDJKTM
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unused: it's always either the default timeout or asynchronous
connect().

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/aolib.h    |  8 ++++----
 tools/testing/selftests/net/tcp_ao/lib/sock.c     | 19 ++++++-------------
 tools/testing/selftests/net/tcp_ao/rst.c          |  5 ++---
 tools/testing/selftests/net/tcp_ao/self-connect.c |  2 +-
 4 files changed, 13 insertions(+), 21 deletions(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/aolib.h b/tools/testing/selftests/net/tcp_ao/lib/aolib.h
index 3c8c5ac2a878a7a4f5949055bdc2a9f05f3d1de5..e4d3d5016b619ef30362bc03802a2455b6aee99c 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/aolib.h
+++ b/tools/testing/selftests/net/tcp_ao/lib/aolib.h
@@ -289,7 +289,7 @@ extern int link_set_up(const char *intf);
 extern const unsigned int test_server_port;
 extern int test_wait_fd(int sk, time_t sec, bool write);
 extern int __test_connect_socket(int sk, const char *device,
-				 void *addr, size_t addr_sz, time_t timeout);
+				 void *addr, size_t addr_sz, bool async);
 extern int __test_listen_socket(int backlog, void *addr, size_t addr_sz);
 
 static inline int test_listen_socket(const union tcp_addr taddr,
@@ -338,19 +338,19 @@ static inline int test_listen_socket(const union tcp_addr taddr,
 #endif
 
 static inline int _test_connect_socket(int sk, const union tcp_addr taddr,
-				       unsigned int port, time_t timeout)
+				       unsigned int port, bool async)
 {
 	sockaddr_af addr;
 
 	tcp_addr_to_sockaddr_in(&addr, &taddr, htons(port));
 	return __test_connect_socket(sk, veth_name,
-				     (void *)&addr, sizeof(addr), timeout);
+				     (void *)&addr, sizeof(addr), async);
 }
 
 static inline int test_connect_socket(int sk, const union tcp_addr taddr,
 				      unsigned int port)
 {
-	return _test_connect_socket(sk, taddr, port, TEST_TIMEOUT_SEC);
+	return _test_connect_socket(sk, taddr, port, false);
 }
 
 extern int __test_set_md5(int sk, void *addr, size_t addr_sz,
diff --git a/tools/testing/selftests/net/tcp_ao/lib/sock.c b/tools/testing/selftests/net/tcp_ao/lib/sock.c
index 1befaf0aa98f9de83fa466cd68a24f467c541a2d..7863ebc36f3c6ced463bd3c8d2c082d5ad152e01 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/sock.c
+++ b/tools/testing/selftests/net/tcp_ao/lib/sock.c
@@ -111,7 +111,7 @@ static int __test_skpair_poll(int sk, bool write, uint64_t timeout,
 }
 
 int __test_connect_socket(int sk, const char *device,
-			  void *addr, size_t addr_sz, time_t timeout)
+			  void *addr, size_t addr_sz, bool async)
 {
 	long flags;
 	int err;
@@ -123,15 +123,6 @@ int __test_connect_socket(int sk, const char *device,
 			test_error("setsockopt(SO_BINDTODEVICE, %s)", device);
 	}
 
-	if (!timeout) {
-		err = connect(sk, addr, addr_sz);
-		if (err) {
-			err = -errno;
-			goto out;
-		}
-		return 0;
-	}
-
 	flags = fcntl(sk, F_GETFL);
 	if ((flags < 0) || (fcntl(sk, F_SETFL, flags | O_NONBLOCK) < 0))
 		test_error("fcntl()");
@@ -141,9 +132,9 @@ int __test_connect_socket(int sk, const char *device,
 			err = -errno;
 			goto out;
 		}
-		if (timeout < 0)
+		if (async)
 			return sk;
-		err = test_wait_fd(sk, timeout, 1);
+		err = test_wait_fd(sk, TEST_TIMEOUT_SEC, 1);
 		if (err)
 			goto out;
 	}
@@ -181,12 +172,14 @@ int _test_skpair_connect_poll(int sk, const char *device,
 	if (test_get_tcp_counters(sk, &c))
 		test_error("test_get_tcp_counters()");
 	synchronize_threads(); /* 1: init skpair & read nscounters */
-	ret = __test_connect_socket(sk, device, addr, addr_sz, -1);
+	ret = __test_connect_socket(sk, device, addr, addr_sz, true);
 	if (ret < 0) {
 		test_tcp_counters_free(&c);
 		return (*err = ret);
 	}
 	ret = __test_skpair_poll(sk, 1, TEST_TIMEOUT_SEC, &c, condition, err);
+	if (ret < 0)
+		close(sk);
 	test_tcp_counters_free(&c);
 	return ret;
 }
diff --git a/tools/testing/selftests/net/tcp_ao/rst.c b/tools/testing/selftests/net/tcp_ao/rst.c
index f752df511ba2e646384cf02ccae3c2f807ebaed1..e51be747e2b4f5e0a02f413afd011168a8554302 100644
--- a/tools/testing/selftests/net/tcp_ao/rst.c
+++ b/tools/testing/selftests/net/tcp_ao/rst.c
@@ -271,8 +271,7 @@ static void test_client_active_rst(unsigned int port)
 
 	synchronize_threads(); /* 1: MKT added */
 	for (i = 0; i < last; i++) {
-		err = _test_connect_socket(sk[i], this_ip_dest, port,
-					       (i == 0) ? TEST_TIMEOUT_SEC : -1);
+		err = _test_connect_socket(sk[i], this_ip_dest, port, i != 0);
 		if (err < 0)
 			test_error("failed to connect()");
 	}
@@ -283,7 +282,7 @@ static void test_client_active_rst(unsigned int port)
 		test_error("test_wait_fds(): %d", err);
 
 	/* async connect() with third sk to get into request_sock_queue */
-	err = _test_connect_socket(sk[last], this_ip_dest, port, -1);
+	err = _test_connect_socket(sk[last], this_ip_dest, port, 1);
 	if (err < 0)
 		test_error("failed to connect()");
 
diff --git a/tools/testing/selftests/net/tcp_ao/self-connect.c b/tools/testing/selftests/net/tcp_ao/self-connect.c
index 93732732c60c03ccdec093de4964cf9f8caa7b0d..10927cfa23840d31a67e4de34fa2211f9b54cf4b 100644
--- a/tools/testing/selftests/net/tcp_ao/self-connect.c
+++ b/tools/testing/selftests/net/tcp_ao/self-connect.c
@@ -64,7 +64,7 @@ static void tcp_self_connect(const char *tst, unsigned int port,
 		test_error("test_get_tcp_counters()");
 
 	if (__test_connect_socket(sk, "lo", (struct sockaddr *)&addr,
-				  sizeof(addr), TEST_TIMEOUT_SEC) < 0) {
+				  sizeof(addr), 0) < 0) {
 		ns_after = netstat_read();
 		netstat_print_diff(ns_before, ns_after);
 		test_error("failed to connect()");

-- 
2.42.2

