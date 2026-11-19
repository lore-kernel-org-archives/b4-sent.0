From: Mohamed Salem Gorrab <grghdghhhh@gmail.com>
Date: Thu, 19 Nov 2026 05:44:04 -0500
Subject: [PATCH] alpha: boot: check OSFLAGS length in start_kernel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-alpha-osflags-v1-1-b5f58d1cbdf8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPPS/moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0NL3cScgoxE3fzitJzE9GLdFFPDVAuLNAMjiyRjJaCegqLUtMwKsHn
 RsbW1ALZTViNfAAAA
X-Change-ID: 20261119-alpha-osflags-d51e88f028b3
To: Richard Henderson <richard.henderson@linaro.org>, 
 Matt Turner <mattst88@gmail.com>, Magnus Lindholm <linmag7@gmail.com>
Cc: linux-alpha@vger.kernel.org, 
 Mohamed Salem Gorrab <grghdghhhh@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795085044; l=1227;
 i=grghdghhhh@gmail.com; s=20261119; h=from:subject:message-id;
 bh=IUZzSyFE+63kVHFb5iMI12mDAdfpqdsDko6szqWLryo=;
 b=Fc7gj1wCpmabIZN4jItIvTZFFJfoIA351tAJpwEJ+NToKfW2wGTHlL+cLQaB5RMJ9WL37yueE
 qrw/htYoTt3AVvYZLcDk5ThSW8Z3ebFWB2TCf0VsfYFYf63bRyD8Hbg
X-Developer-Key: i=grghdghhhh@gmail.com; a=ed25519;
 pk=vEfbRi05Tj25VTTOeRMU3V1L4HD3BpEHjTc5Tm6Hw1E=
X-Endpoint-Received: by B4 Relay for grghdghhhh@gmail.com/20261119 with auth_id=1569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bootp.c and bootpz.c reject a length >= sizeof(envval) from
callback_getenv() before writing the terminating NUL. main.c only
rejects negative values, so a return value of 256 would write one
byte past the end of envval.

Use the same check as the other two files. I don't know whether the
SRM firmware can actually return a length equal to the buffer size,
so this is mainly for consistency. I have not tested on Alpha
hardware.

Signed-off-by: Mohamed Salem Gorrab <grghdghhhh@gmail.com>
---
 arch/alpha/boot/main.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/alpha/boot/main.c b/arch/alpha/boot/main.c
index 22a1cb0264afe6397ef2598c107f88280b979d63..0ce301edb219dc0c2fbabe5f692b48437a79d3b1 100644
--- a/arch/alpha/boot/main.c
+++ b/arch/alpha/boot/main.c
@@ -176,7 +176,7 @@ void start_kernel(void)
 	}
 
 	nbytes = callback_getenv(ENV_BOOTED_OSFLAGS, envval, sizeof(envval));
-	if (nbytes < 0) {
+	if (nbytes < 0 || nbytes >= sizeof(envval)) {
 		nbytes = 0;
 	}
 	envval[nbytes] = '\0';

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261119-alpha-osflags-d51e88f028b3

Best regards,
-- 
Mohamed Salem Gorrab <grghdghhhh@gmail.com>

