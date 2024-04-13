From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Sat, 13 Apr 2024 02:42:55 +0100
Subject: [PATCH net 4/4] selftests/tcp_ao: Printing fixes to confirm with
 format-security
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240413-tcp-ao-selftests-fixes-v1-4-f9c41c96949d@gmail.com>
References: <20240413-tcp-ao-selftests-fixes-v1-0-f9c41c96949d@gmail.com>
In-Reply-To: <20240413-tcp-ao-selftests-fixes-v1-0-f9c41c96949d@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712972582; l=3422;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=wxpBb6LXRSkXjmd5ZWPuyM5ay6kCGD4vUjqDQ4vhKHA=;
 b=RzjpBpFw7UrSJlsSzfmRDK0F7NIVVw+KR068dfVdNt06AMkdy9ah7w7UoWLndoMjzomBVdPa14O0
 ZCVN90BLA1GKUznUJw6J2yAK+8RkIyG4lKRpp4CSVb4z9l4mCxIC
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On my new laptop with packages from nixos-unstable, gcc 12.3.0 produces
> lib/setup.c: In function ‘__test_msg’:
> lib/setup.c:20:9: error: format not a string literal and no format arguments [-Werror=format-security]
>    20 |         ksft_print_msg(buf);
>       |         ^~~~~~~~~~~~~~
> lib/setup.c: In function ‘__test_ok’:
> lib/setup.c:26:9: error: format not a string literal and no format arguments [-Werror=format-security]
>    26 |         ksft_test_result_pass(buf);
>       |         ^~~~~~~~~~~~~~~~~~~~~
> lib/setup.c: In function ‘__test_fail’:
> lib/setup.c:32:9: error: format not a string literal and no format arguments [-Werror=format-security]
>    32 |         ksft_test_result_fail(buf);
>       |         ^~~~~~~~~~~~~~~~~~~~~
> lib/setup.c: In function ‘__test_xfail’:
> lib/setup.c:38:9: error: format not a string literal and no format arguments [-Werror=format-security]
>    38 |         ksft_test_result_xfail(buf);
>       |         ^~~~~~~~~~~~~~~~~~~~~~
> lib/setup.c: In function ‘__test_error’:
> lib/setup.c:44:9: error: format not a string literal and no format arguments [-Werror=format-security]
>    44 |         ksft_test_result_error(buf);
>       |         ^~~~~~~~~~~~~~~~~~~~~~
> lib/setup.c: In function ‘__test_skip’:
> lib/setup.c:50:9: error: format not a string literal and no format arguments [-Werror=format-security]
>    50 |         ksft_test_result_skip(buf);
>       |         ^~~~~~~~~~~~~~~~~~~~~
> cc1: some warnings being treated as errors

As the buffer was already pre-printed into, print it as a string
rather than a format-string.

Fixes: cfbab37b3da0 ("selftests/net: Add TCP-AO library")
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/setup.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/setup.c b/tools/testing/selftests/net/tcp_ao/lib/setup.c
index 92276f916f2f..e408b9243b2c 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/setup.c
+++ b/tools/testing/selftests/net/tcp_ao/lib/setup.c
@@ -17,37 +17,37 @@ static pthread_mutex_t ksft_print_lock = PTHREAD_MUTEX_INITIALIZER;
 void __test_msg(const char *buf)
 {
 	pthread_mutex_lock(&ksft_print_lock);
-	ksft_print_msg(buf);
+	ksft_print_msg("%s", buf);
 	pthread_mutex_unlock(&ksft_print_lock);
 }
 void __test_ok(const char *buf)
 {
 	pthread_mutex_lock(&ksft_print_lock);
-	ksft_test_result_pass(buf);
+	ksft_test_result_pass("%s", buf);
 	pthread_mutex_unlock(&ksft_print_lock);
 }
 void __test_fail(const char *buf)
 {
 	pthread_mutex_lock(&ksft_print_lock);
-	ksft_test_result_fail(buf);
+	ksft_test_result_fail("%s", buf);
 	pthread_mutex_unlock(&ksft_print_lock);
 }
 void __test_xfail(const char *buf)
 {
 	pthread_mutex_lock(&ksft_print_lock);
-	ksft_test_result_xfail(buf);
+	ksft_test_result_xfail("%s", buf);
 	pthread_mutex_unlock(&ksft_print_lock);
 }
 void __test_error(const char *buf)
 {
 	pthread_mutex_lock(&ksft_print_lock);
-	ksft_test_result_error(buf);
+	ksft_test_result_error("%s", buf);
 	pthread_mutex_unlock(&ksft_print_lock);
 }
 void __test_skip(const char *buf)
 {
 	pthread_mutex_lock(&ksft_print_lock);
-	ksft_test_result_skip(buf);
+	ksft_test_result_skip("%s", buf);
 	pthread_mutex_unlock(&ksft_print_lock);
 }
 

-- 
2.42.0

