From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:29:03 -0400
Subject: [PATCH v5 18/21] x86/tools/relocs: Ignore __kcfi_typeid_ relocations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220901-kcfi_support-v5-18-be2007d8da63@linuxfoundation.org>
References: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
In-Reply-To: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=774;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=0xQJLUdP/e8fBJfi92lYVC9J6Oax9wCeLomJDsLcKHg=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIF2X8vNpone2ajrN+KZbveXPdtPjwzwdGh5P6ZVjlNP8WY
 tr3pHaUsDGJcDLJiiixl+2I3BRU+9JBL7zGFmcPKBDKEgYtTACYi5cvwP/3DjHczrh17GRqds+vV6j
 kqz8wna5tue3xexLDJ2sArLoLhvw8/n2ZRXWDMRfdbjaslbL2NXzwsk7s9/3byIfUFl8+wMwIA
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

The compiler generates __kcfi_typeid_ symbols for annotating assembly
functions with type information. These are constants that can be
referenced in assembly code and are resolved by the linker. Ignore
them in relocs.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Reviewed-by: Kees Cook <keescook@chromium.org>
Tested-by: Kees Cook <keescook@chromium.org>

diff --git a/arch/x86/tools/relocs.c b/arch/x86/tools/relocs.c
index e2c5b296120d..2925074b9a58 100644
--- a/arch/x86/tools/relocs.c
+++ b/arch/x86/tools/relocs.c
@@ -56,6 +56,7 @@ static const char * const sym_regex_kernel[S_NSYMTYPES] = {
 	"^(xen_irq_disable_direct_reloc$|"
 	"xen_save_fl_direct_reloc$|"
 	"VDSO|"
+	"__kcfi_typeid_|"
 	"__crc_)",
 
 /*

-- 
b4 0.10.0-dev-03aea
