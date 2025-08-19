From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Tue, 19 Aug 2025 10:45:57 +0800
Subject: [PATCH] selftests: net: fix memory leak in tls.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250819-memoryleak-v1-1-d4c70a861e62@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAGTlo2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDC0NL3dzU3PyiypzUxGxdy5Sk1GTLxDSzZANzJaCGgqLUtMwKsGHRsbW
 1APHd1ZpcAAAA
X-Change-ID: 20250819-memoryleak-9dbec9af6c07
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, zhanjun@uniontech.com, 
 niecheng1@uniontech.com, guanwentao@uniontech.com, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755571557; l=1183;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=bJ2O1uJkJydfjBXKxT0NanxgQaONGN6lDC7g+1imYiw=;
 b=xzQfIUFyWMrFvujCffyv+PN8PbAoSZ2gVir4MYYu1oaGPhjxkT884zXmNyYRWxQMZ4Rumu7Ms
 XYBWpUhR09bAYeg8F5B+p2tk283oVjxbzbsV8eaet43ZEfxXqNBY/Sy
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To free memory and close fd after use

Suggested-by: Jun Zhan <zhanjun@uniontech.com>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 tools/testing/selftests/net/tls.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/tools/testing/selftests/net/tls.c b/tools/testing/selftests/net/tls.c
index d8cfcf9bb82594ca078c998ce5849131bf46ade8..23cf6ff5fa49378bd7906334ff402aa61a205f29 100644
--- a/tools/testing/selftests/net/tls.c
+++ b/tools/testing/selftests/net/tls.c
@@ -427,6 +427,8 @@ TEST_F(tls, sendfile)
 	EXPECT_GE(filefd, 0);
 	fstat(filefd, &st);
 	EXPECT_GE(sendfile(self->fd, filefd, 0, st.st_size), 0);
+
+	close(filefd);
 }
 
 TEST_F(tls, send_then_sendfile)
@@ -448,6 +450,9 @@ TEST_F(tls, send_then_sendfile)
 
 	EXPECT_GE(sendfile(self->fd, filefd, 0, st.st_size), 0);
 	EXPECT_EQ(recv(self->cfd, buf, st.st_size, MSG_WAITALL), st.st_size);
+
+	free(buf);
+	close(filefd);
 }
 
 static void chunked_sendfile(struct __test_metadata *_metadata,

---
base-commit: be48bcf004f9d0c9207ff21d0edb3b42f253829e
change-id: 20250819-memoryleak-9dbec9af6c07

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

