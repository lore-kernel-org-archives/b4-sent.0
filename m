From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Tue, 30 Jul 2024 03:12:17 +0100
Subject: [PATCH net-next 3/7] selftests/net: Be consistent in kconfig
 checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240730-tcp-ao-selftests-upd-6-12-v1-3-ffd4bf15d638@gmail.com>
References: <20240730-tcp-ao-selftests-upd-6-12-v1-0-ffd4bf15d638@gmail.com>
In-Reply-To: <20240730-tcp-ao-selftests-upd-6-12-v1-0-ffd4bf15d638@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722305607; l=2700;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=PdEStG299EXQfXQVBhomcx2f3Galb07Vq+9A5L4s+Lw=;
 b=uMBROFsSPN4MGu5IQV+mWnWwnDaL/ftb+UbVj6bG4WudU2Aen4e2F32hiz8AkRimC7Tto53Vt
 JD4v8GKGqKCDuf1FugHzWf7BCMWKiXL3uCyyzteQWb/iXt2DBnYntNj
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Most of the functions in tcp-ao lib/ return negative errno or -1 in case
of a failure. That creates inconsistencies in lib/kconfig, which saves
what was the error code. As well as the uninitialized kconfig value is
-1, which also may be the result of a check.

Define KCONFIG_UNKNOWN and save negative return code, rather than
libc-style errno.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/kconfig.c | 23 ++++++++++++-----------
 1 file changed, 12 insertions(+), 11 deletions(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/kconfig.c b/tools/testing/selftests/net/tcp_ao/lib/kconfig.c
index f279ffc3843b..3bf4a7e4b3c9 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/kconfig.c
+++ b/tools/testing/selftests/net/tcp_ao/lib/kconfig.c
@@ -6,7 +6,7 @@
 #include "aolib.h"
 
 struct kconfig_t {
-	int _errno;		/* the returned error if not supported */
+	int _error;		/* negative errno if not supported */
 	int (*check_kconfig)(int *error);
 };
 
@@ -62,7 +62,7 @@ static int has_tcp_ao(int *err)
 	memcpy(&tmp.addr, &addr, sizeof(addr));
 	*err = 0;
 	if (setsockopt(sk, IPPROTO_TCP, TCP_AO_ADD_KEY, &tmp, sizeof(tmp)) < 0) {
-		*err = errno;
+		*err = -errno;
 		if (errno != ENOPROTOOPT)
 			ret = -errno;
 	}
@@ -87,7 +87,7 @@ static int has_tcp_md5(int *err)
 	 */
 	*err = 0;
 	if (test_set_md5(sk, addr_any, 0, -1, DEFAULT_TEST_PASSWORD)) {
-		*err = errno;
+		*err = -errno;
 		if (errno != ENOPROTOOPT && errno == ENOMEM) {
 			test_print("setsockopt(TCP_MD5SIG_EXT): %m");
 			ret = -errno;
@@ -116,13 +116,14 @@ static int has_vrfs(int *err)
 	return ret;
 }
 
+#define KCONFIG_UNKNOWN			1
 static pthread_mutex_t kconfig_lock = PTHREAD_MUTEX_INITIALIZER;
 static struct kconfig_t kconfig[__KCONFIG_LAST__] = {
-	{ -1, has_net_ns },
-	{ -1, has_veth },
-	{ -1, has_tcp_ao },
-	{ -1, has_tcp_md5 },
-	{ -1, has_vrfs },
+	{ KCONFIG_UNKNOWN, has_net_ns },
+	{ KCONFIG_UNKNOWN, has_veth },
+	{ KCONFIG_UNKNOWN, has_tcp_ao },
+	{ KCONFIG_UNKNOWN, has_tcp_md5 },
+	{ KCONFIG_UNKNOWN, has_vrfs },
 };
 
 const char *tests_skip_reason[__KCONFIG_LAST__] = {
@@ -138,11 +139,11 @@ bool kernel_config_has(enum test_needs_kconfig k)
 	bool ret;
 
 	pthread_mutex_lock(&kconfig_lock);
-	if (kconfig[k]._errno == -1) {
-		if (kconfig[k].check_kconfig(&kconfig[k]._errno))
+	if (kconfig[k]._error == KCONFIG_UNKNOWN) {
+		if (kconfig[k].check_kconfig(&kconfig[k]._error))
 			test_error("Failed to initialize kconfig %u", k);
 	}
-	ret = kconfig[k]._errno == 0;
+	ret = kconfig[k]._error == 0;
 	pthread_mutex_unlock(&kconfig_lock);
 	return ret;
 }

-- 
2.42.2

