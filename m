From: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
Date: Tue, 03 Mar 2026 23:06:17 +0100
Subject: [PATCH] alpha: objstrip: fix partial write() buffer pointer not
 advancing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-alpha-fix-v1-1-89abede2a585@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYwNj3cScgoxE3bTMCt3kVNM0c4PUVAsDwxQloPqColSgMNis6NjaWgA
 gLHmgWwAAAA==
X-Change-ID: 20260303-alpha-fix-ce5f70ee801d
To: Richard Henderson <richard.henderson@linaro.org>, 
 Matt Turner <mattst88@gmail.com>, Magnus Lindholm <linmag7@gmail.com>
Cc: linux-alpha@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Maximilian Pezzullo <maximilianpezzullo@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772575624; l=1584;
 i=maximilianpezzullo@gmail.com; s=20260303; h=from:subject:message-id;
 bh=z1sLA8h3NypD4m7zDxw+jdCekD1EutaTlomZvuEG0dg=;
 b=TIhTx582nsVwRLtQQmuoneiiCFs/q6M5CdVhFb8BhTlny9UnZ5yZgoIiVVbMF7qEnXPl+7Dc0
 iBqr4hE4EXZBMbUa2eJBhXFPfoNMpfdjCN2u0GIVJWAXPqm8FAK3Z9+
X-Developer-Key: i=maximilianpezzullo@gmail.com; a=ed25519;
 pk=TRTR4c2Vb1IfluQvv5OUDPg7EE+pIzdPBND85UU559w=
X-Endpoint-Received: by B4 Relay for maximilianpezzullo@gmail.com/20260303 with auth_id=658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the main copy loop, on a partial write() the inner do-while
retried write(ofd, buf, n) always from the start of buf, while
only n was decremented.  This caused already-written data to be
re-written, corrupting the output file on systems where write()
returns less than the requested byte count.

Fix by introducing a pointer 'p' that tracks the current write
position within buf and advances it by nwritten on each iteration.

Closes: https://bugzilla.kernel.org/show_bug.cgi?id=221159
Signed-off-by: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
---
 arch/alpha/boot/tools/objstrip.c | 20 ++++++++++++--------
 1 file changed, 12 insertions(+), 8 deletions(-)

diff --git a/arch/alpha/boot/tools/objstrip.c b/arch/alpha/boot/tools/objstrip.c
index 7cf92d172dc..8da25c2584f 100644
--- a/arch/alpha/boot/tools/objstrip.c
+++ b/arch/alpha/boot/tools/objstrip.c
@@ -246,14 +246,18 @@ main (int argc, char *argv[])
 	    perror("read");
 	    exit(1);
 	}
-	do {
-	    nwritten = write(ofd, buf, n);
-	    if ((ssize_t) nwritten == -1) {
-		perror("write");
-		exit(1);
-	    }
-	    n -= nwritten;
-	} while (n > 0);
+	{
+	    char *p = buf;
+	    do {
+		nwritten = write(ofd, p, n);
+		if ((ssize_t) nwritten == -1) {
+		    perror("write");
+		    exit(1);
+		}
+		p += nwritten;
+		n -= nwritten;
+	    } while (n > 0);
+	}
     }
 
     if (pad) {

---
base-commit: af4e9ef3d78420feb8fe58cd9a1ab80c501b3c08
change-id: 20260303-alpha-fix-ce5f70ee801d

Best regards,
-- 
Maximilian Pezzullo <maximilianpezzullo@gmail.com>

