From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:28:57 -0400
Subject: [PATCH v5 12/21] init: Drop __nocfi from __init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220901-kcfi_support-v5-12-be2007d8da63@linuxfoundation.org>
References: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
In-Reply-To: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=890;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=x7OX0kZCMkXgJU8pYjvcHEC6czvwXJrBc8T8v/dBI7Y=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIF2X8/Wp0mtiBGbYVE3Sxui4bVjW8f+Lt8PdnnVLq11nLH
 xuULOkpZGMS4GGTFFFnK9sVuCip86CGX3mMKM4eVCWQIAxenAExkUQDDHy6PfKNNFwIdVW+uELPcc+
 KF3PFT8XM6sn/KLnRwcmP8Z8DIcOHD2pYrOV8OpJ09WttTFCg3efb9PRcduTc937yMrXqmMTMA
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

It's no longer necessary to disable CFI checking for all __init
functions. Drop the __nocfi attribute from __init.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Reviewed-by: Kees Cook <keescook@chromium.org>
Tested-by: Kees Cook <keescook@chromium.org>

diff --git a/include/linux/init.h b/include/linux/init.h
index baf0b29a7010..88f2964097f5 100644
--- a/include/linux/init.h
+++ b/include/linux/init.h
@@ -47,7 +47,7 @@
 
 /* These are for everybody (although not all archs will actually
    discard it in modules) */
-#define __init		__section(".init.text") __cold  __latent_entropy __noinitretpoline __nocfi
+#define __init		__section(".init.text") __cold  __latent_entropy __noinitretpoline
 #define __initdata	__section(".init.data")
 #define __initconst	__section(".init.rodata")
 #define __exitdata	__section(".exit.data")

-- 
b4 0.10.0-dev-03aea
