From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 08 Jul 2025 02:30:42 -0500
Subject: [PATCH] efistub: Lower default log level
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250708-efi-default-loglevel-v1-1-12b80db5af16@gmail.com>
X-B4-Tracking: v=1; b=H4sIACHJbGgC/x2MWwqAIBAArxL73YI9rOgq0ceiay1IhZYE0d2TP
 gdm5oHIQTjCWDwQOEmUfctQlQWYlbaFUWxmqFWtVa8GZCdo2dHlT/T74jmxx9aSpqYzZIYecnq
 ErN3/dprf9wNJVExsZgAAAA==
X-Change-ID: 20250708-efi-default-loglevel-4da5a36cac87
To: Ard Biesheuvel <ardb@kernel.org>
Cc: linux-efi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751959845; l=1284;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=ChssDVXeeXa5KArbpSvIR/bGgEJum64xNRRJ9Dgia9U=;
 b=RtJOCFiU2aGfuqIawoZEJwZPTcljVs3ePx4Yx4kiqwjhMcNJ6DuCDFo0/JJg77PCkYtTCs7yx
 OHKIz0/ER86BiJcmOgWrfqwM6nizx1zDBYZK6Oz+m9eZIlPn/1meBh9
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some uefi implementations will write the efistub logs to the display
over a splash image. This is not desirable for debug and info logs, so
lower the default efi log level to exclude them.

Suggested-by: Ard Biesheuvel <ardb@kernel.org>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/firmware/efi/libstub/printk.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/firmware/efi/libstub/printk.c b/drivers/firmware/efi/libstub/printk.c
index 3a67a2cea7bdf1aa215d48dbf9ece4ceec6e4c28..bc599212c05dd746a9c54abbbe61a4bf70f1a8c4 100644
--- a/drivers/firmware/efi/libstub/printk.c
+++ b/drivers/firmware/efi/libstub/printk.c
@@ -5,13 +5,13 @@
 #include <linux/ctype.h>
 #include <linux/efi.h>
 #include <linux/kernel.h>
-#include <linux/printk.h> /* For CONSOLE_LOGLEVEL_* */
+#include <linux/kern_levels.h>
 #include <asm/efi.h>
 #include <asm/setup.h>
 
 #include "efistub.h"
 
-int efi_loglevel = CONSOLE_LOGLEVEL_DEFAULT;
+int efi_loglevel = LOGLEVEL_NOTICE;
 
 /**
  * efi_char16_puts() - Write a UCS-2 encoded string to the console

---
base-commit: d7b8f8e20813f0179d8ef519541a3527e7661d3a
change-id: 20250708-efi-default-loglevel-4da5a36cac87

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

