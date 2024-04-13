From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Sat, 13 Apr 2024 02:42:53 +0100
Subject: [PATCH net 2/4] selftests/tcp_ao: Zero-init tcp_ao_info_opt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240413-tcp-ao-selftests-fixes-v1-2-f9c41c96949d@gmail.com>
References: <20240413-tcp-ao-selftests-fixes-v1-0-f9c41c96949d@gmail.com>
In-Reply-To: <20240413-tcp-ao-selftests-fixes-v1-0-f9c41c96949d@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712972582; l=1034;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=3bRkAaWMpwCvEVUHFASSPFH/W2xMsTy4q2ZYGJH/FcI=;
 b=aZvNsjzortZd28wwafvkCmgyJVPjZQcwxuQ5gPXrPthVSKj60nH6vApYB/+5TgqvtXPLqEBmh5x+
 f7RSvRMsBWHk/b46SuYVSBsFsRX6ns0IW2+2X7YvrhZdaTu9iEUE
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The structure is on the stack and has to be zero-initialized as
the kernel checks for:
>	if (in.reserved != 0 || in.reserved2 != 0)
>		return -EINVAL;

Fixes: b26660531cf6 ("selftests/net: Add test for TCP-AO add setsockopt() command")
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/setsockopt-closed.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/testing/selftests/net/tcp_ao/setsockopt-closed.c b/tools/testing/selftests/net/tcp_ao/setsockopt-closed.c
index 452de131fa3a..517930f9721b 100644
--- a/tools/testing/selftests/net/tcp_ao/setsockopt-closed.c
+++ b/tools/testing/selftests/net/tcp_ao/setsockopt-closed.c
@@ -21,7 +21,7 @@ static void make_listen(int sk)
 static void test_vefify_ao_info(int sk, struct tcp_ao_info_opt *info,
 				const char *tst)
 {
-	struct tcp_ao_info_opt tmp;
+	struct tcp_ao_info_opt tmp = {};
 	socklen_t len = sizeof(tmp);
 
 	if (getsockopt(sk, IPPROTO_TCP, TCP_AO_INFO, &tmp, &len))

-- 
2.42.0

