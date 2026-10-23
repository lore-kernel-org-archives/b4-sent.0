From: Atanas Kunchev <atanaskunchev@proton.me>
Date: Fri, 23 Oct 2026 20:50:46 +0300
Subject: [PATCH] binfmt_misc: fix typo in "auxiliary vector"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-binfmt-typo-v1-1-459d4ae4c15f@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNj3aTMvLTcEt2SyoJ83aQ0CwNjA4tUI+NEAyWgjoKi1LTMCrBp0bG
 1tQAdmKLbXQAAAA==
X-Change-ID: 20261023-binfmt-typo-bf80308e23a0
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Kees Cook <kees@kernel.org>
Cc: linux-doc@vger.kernel.org, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Atanas Kunchev <atanaskunchev@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792777850; l=1335;
 i=atanaskunchev@proton.me; h=from:subject:message-id;
 bh=2pX207vjhqtmwxK8nx0gyejv0Uothbk71WYMMlsUqzE=;
 b=i+SyRbqcik8GaT3nZQP2XAj+MD0WuTUYKk0+RqJXTY1hmJRh3SVhNMZVhmwU6sfTZE4EWoxjC
 SPZqpebrdTsDyccHoSkYYW+NhTYP+yBCsPr7XWkTpW8az2jyHj2eFRx
X-Developer-Key: i=atanaskunchev@proton.me; a=ed25519;
 pk=UZOV7XzSdjoak/BahXi4m/UsbdgtIb1vQI3+u1lAHOc=
X-Endpoint-Received: by B4 Relay for atanaskunchev@proton.me/default with auth_id=1293
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix "auxilary" -> "auxiliary".

Signed-off-by: Atanas Kunchev <atanaskunchev@proton.me>
---
Fix a spelling mistake in the binfmt_misc documentation.
---
 Documentation/admin-guide/binfmt-misc.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/admin-guide/binfmt-misc.rst b/Documentation/admin-guide/binfmt-misc.rst
index 9e84b877d06d..e37668371453 100644
--- a/Documentation/admin-guide/binfmt-misc.rst
+++ b/Documentation/admin-guide/binfmt-misc.rst
@@ -73,7 +73,7 @@ Here is what the fields mean:
 	    Legacy behavior of binfmt_misc is to pass the full path
             of the binary to the interpreter as an argument. When this flag is
             included, binfmt_misc will open the file for reading and pass its
-            descriptor into the auxilary vector with the key "AT_EXECFD", thus
+            descriptor into the auxiliary vector with the key "AT_EXECFD", thus
             allowing the interpreter to execute non-readable binaries. This
             feature should be used with care - the interpreter has to be trusted
             not to emit the contents of the non-readable binary.

---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261023-binfmt-typo-bf80308e23a0

Best regards,
-- 
Atanas Kunchev <atanaskunchev@proton.me>

