From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Sat, 13 Apr 2024 02:42:54 +0100
Subject: [PATCH net 3/4] selftests/tcp_ao: Fix fscanf() call for
 format-security
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240413-tcp-ao-selftests-fixes-v1-3-f9c41c96949d@gmail.com>
References: <20240413-tcp-ao-selftests-fixes-v1-0-f9c41c96949d@gmail.com>
In-Reply-To: <20240413-tcp-ao-selftests-fixes-v1-0-f9c41c96949d@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712972582; l=1369;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=8QLIHbMoN2Kwyajab0w/1qWe3pRkg64mhy39Rmm7dW4=;
 b=E+Tm/hDau67ueNTODWxl1Xainp4x+/2jO0SZqndJTzxr2VvGLnENcbzY/loJ0nCmerjr1CVsT0A+
 bgy+z5hHAMtNEGPNhInjRYw45a9tupTNZ83cWzf41CbwVWFNmK7m
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On my new laptop with packages from nixos-unstable, gcc 12.3.0 produces:
> lib/proc.c: In function ‘netstat_read_type’:
> lib/proc.c:89:9: error: format not a string literal and no format arguments [-Werror=format-security]
>    89 |         if (fscanf(fnetstat, type->header_name) == EOF)
>       |         ^~
> cc1: some warnings being treated as errors

Here the selftests lib parses header name, while expectes non-space word
ending with a column.

Fixes: cfbab37b3da0 ("selftests/net: Add TCP-AO library")
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/proc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/proc.c b/tools/testing/selftests/net/tcp_ao/lib/proc.c
index 2fb6dd8adba6..8b984fa04286 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/proc.c
+++ b/tools/testing/selftests/net/tcp_ao/lib/proc.c
@@ -86,7 +86,7 @@ static void netstat_read_type(FILE *fnetstat, struct netstat **dest, char *line)
 
 	pos = strchr(line, ' ') + 1;
 
-	if (fscanf(fnetstat, type->header_name) == EOF)
+	if (fscanf(fnetstat, "%[^ :]", type->header_name) == EOF)
 		test_error("fscanf(%s)", type->header_name);
 	if (fread(&tmp, 1, 1, fnetstat) != 1 || tmp != ':')
 		test_error("Unexpected netstat format (%c)", tmp);

-- 
2.42.0

