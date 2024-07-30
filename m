From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Tue, 30 Jul 2024 03:12:16 +0100
Subject: [PATCH net-next 2/7] selftests/net: Provide test_snprintf() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240730-tcp-ao-selftests-upd-6-12-v1-2-ffd4bf15d638@gmail.com>
References: <20240730-tcp-ao-selftests-upd-6-12-v1-0-ffd4bf15d638@gmail.com>
In-Reply-To: <20240730-tcp-ao-selftests-upd-6-12-v1-0-ffd4bf15d638@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722305607; l=1997;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=Hn2Bs9Fc12/AgT2T+RfB5ex9Lh+DmQaxL5WEBCBy03c=;
 b=vzbfnONCkUpmAXmtf052TLVJ0Gl9J9VN6abOlydRPRQDr1Itxrv4mqS6HUDMLSqZy3XOPh7jw
 kfNFciSa+TpDSZqlQYQsL0Fb436BuXK7b49538rgEMu3l5OV2WTCf7h
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Re-invented std::stringstream :-)

No need for buffer array - malloc() it.
It's going to be helpful of path concat printings.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/aolib.h | 56 ++++++++++++++++++++++----
 1 file changed, 49 insertions(+), 7 deletions(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/aolib.h b/tools/testing/selftests/net/tcp_ao/lib/aolib.h
index fbc7f6111815..fdf44d176e0b 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/aolib.h
+++ b/tools/testing/selftests/net/tcp_ao/lib/aolib.h
@@ -37,17 +37,59 @@ extern void __test_xfail(const char *buf);
 extern void __test_error(const char *buf);
 extern void __test_skip(const char *buf);
 
+static inline char *test_snprintf(const char *fmt, va_list vargs)
+{
+	char *ret = NULL;
+	size_t size = 0;
+	va_list tmp;
+	int n = 0;
+
+	va_copy(tmp, vargs);
+	n = vsnprintf(ret, size, fmt, tmp);
+	if (n < 0)
+		return NULL;
+
+	size = (size_t) n + 1;
+	ret = malloc(size);
+	if (ret == NULL)
+		return NULL;
+
+	n = vsnprintf(ret, size, fmt, vargs);
+	if (n < 0 || n > size - 1) {
+		free(ret);
+		return NULL;
+	}
+	return ret;
+}
+
+__attribute__((__format__(__printf__, 1, 2)))
+static inline char *test_sprintf(const char *fmt, ...)
+{
+	va_list vargs;
+	char *ret;
+
+	va_start(vargs, fmt);
+	ret = test_snprintf(fmt, vargs);
+	va_end(vargs);
+
+	return ret;
+}
+
 __attribute__((__format__(__printf__, 2, 3)))
 static inline void __test_print(void (*fn)(const char *), const char *fmt, ...)
 {
-#define TEST_MSG_BUFFER_SIZE 4096
-	char buf[TEST_MSG_BUFFER_SIZE];
-	va_list arg;
+	va_list vargs;
+	char *msg;
 
-	va_start(arg, fmt);
-	vsnprintf(buf, sizeof(buf), fmt, arg);
-	va_end(arg);
-	fn(buf);
+	va_start(vargs, fmt);
+	msg = test_snprintf(fmt, vargs);
+	va_end(vargs);
+
+	if (!msg)
+		return;
+
+	fn(msg);
+	free(msg);
 }
 
 #define test_print(fmt, ...)						\

-- 
2.42.2

