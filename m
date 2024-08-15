From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Thu, 15 Aug 2024 22:32:27 +0100
Subject: [PATCH net-next v3 2/8] selftests/net: Provide test_snprintf()
 helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240815-tcp-ao-selftests-upd-6-12-v3-2-7bd2e22bb81c@gmail.com>
References: <20240815-tcp-ao-selftests-upd-6-12-v3-0-7bd2e22bb81c@gmail.com>
In-Reply-To: <20240815-tcp-ao-selftests-upd-6-12-v3-0-7bd2e22bb81c@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723757567; l=2413;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=8+utKAlqfPj4BJg8ENUdZrxm7vNk3Rr7aXRZIl8U7xQ=;
 b=RCXSUY+OYpRw6ztdHMQSUvD+mZp3Jj1xrGrmkpODDzznG9HtmrkMPEw7OtEmNnAnP+0PA3lv5
 fQXipoW1FUrD2TYExlTQEX1s9nSpAO2iBo574j/4Ku8+PrLkcr6u71U
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of pre-allocating a fixed-sized buffer of TEST_MSG_BUFFER_SIZE
and printing into it, call vsnprintf() with str = NULL, which will
return the needed size of the buffer. This hack is documented in
man 3 vsnprintf.

Essentially, in C++ terms, it re-invents std::stringstream, which is
going to be used to print different tracing paths and formatted strings.
Use it straight away in __test_print() - which is thread-safe version of
printing in selftests.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/aolib.h | 59 ++++++++++++++++++++++----
 1 file changed, 50 insertions(+), 9 deletions(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/aolib.h b/tools/testing/selftests/net/tcp_ao/lib/aolib.h
index fbc7f6111815..60a63419cabb 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/aolib.h
+++ b/tools/testing/selftests/net/tcp_ao/lib/aolib.h
@@ -37,17 +37,58 @@ extern void __test_xfail(const char *buf);
 extern void __test_error(const char *buf);
 extern void __test_skip(const char *buf);
 
-__attribute__((__format__(__printf__, 2, 3)))
-static inline void __test_print(void (*fn)(const char *), const char *fmt, ...)
+static inline char *test_snprintf(const char *fmt, va_list vargs)
 {
-#define TEST_MSG_BUFFER_SIZE 4096
-	char buf[TEST_MSG_BUFFER_SIZE];
-	va_list arg;
+	char *ret = NULL;
+	size_t size = 0;
+	va_list tmp;
+	int n = 0;
 
-	va_start(arg, fmt);
-	vsnprintf(buf, sizeof(buf), fmt, arg);
-	va_end(arg);
-	fn(buf);
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
+static __printf(1, 2) inline char *test_sprintf(const char *fmt, ...)
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
+static __printf(2, 3) inline void __test_print(void (*fn)(const char *),
+					       const char *fmt, ...)
+{
+	va_list vargs;
+	char *msg;
+
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

