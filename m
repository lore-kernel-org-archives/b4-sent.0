From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 16 Oct 2026 23:50:44 +0200
Subject: [PATCH] mach-snapdragon: fix the serial number taken from the
 command line
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-b4-snapdragon-serialno-v1-1-9d0aa26d4229@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDQAxA4atI1g04489Ar1K6yGjUlJKRSVsK4
 t0d2+W3eG8D4yxscK02yPwRk6QF7lLBsJDOjDIWg69972rXY2zRlNYx05wUz5qempA4cNf4ELv
 QQInXzJN8f+Pb/W97xwcPr/MG+34AWZI5+noAAAA=
X-Change-ID: 20261016-b4-snapdragon-serialno-ae7e5327b573
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792187448; l=1780;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=0CLedReSuo8u1BPyLssJGADja6VBG1fKJ9aup0vJ/RM=;
 b=9yHLJtPqF2yQCSPsKgIoCpraqVp13MrBy2NY4wsmwkzlVQERgTmO0/ahyoFqBJYfn8mCKHQrw
 ua1ezF6zqL5CqZXJIfcgEPafWH2ZJRdB82CytwGOx3zqXh6VyXiM2rj
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check the android command line if it contain the 'androidboot.serialno'
so the qcom_set_serialno() either the return value or skips the value.

Fix also the helper to parse the value as the last word of the command
line.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
The serial number is currently broken on devices where the command line
has no androidboot.serialno or passes it as the last word.

Fix it so it does not set the value from uninitialised stack data.
---
 arch/arm/mach-snapdragon/board.c | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index 5fb3240acc5..50edcd0f6ce 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -331,15 +331,13 @@ static int get_cmdline_option(const char *cmdline, const char *key, char *out, i
 		return -ENOENT;
 
 	p += strlen(key);
-	p_end = strstr(p, " ");
-	if (!p_end)
-		return -ENOENT;
 
-	len = p_end - p;
-	if (len > out_len)
-		len = out_len;
+	p_end = strchr(p, ' ');
+	len = p_end ? p_end - p : strlen(p);
+	if (len >= out_len)
+		len = out_len - 1;
 
-	strncpy(out, p, len);
+	memcpy(out, p, len);
 	out[len] = '\0';
 
 	return 0;
@@ -373,7 +371,9 @@ void qcom_set_serialno(void)
 		return;
 	}
 
-	get_cmdline_option(cmdline, "androidboot.serialno=", serial, sizeof(serial));
+	if (get_cmdline_option(cmdline, "androidboot.serialno=", serial, sizeof(serial)))
+		return;
+
 	if (serial[0] != '\0')
 		env_set("serial#", serial);
 }

---
base-commit: 1bcb2fe324180d0a8cfbdb0511737eba1d5b8550
change-id: 20261016-b4-snapdragon-serialno-ae7e5327b573

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

