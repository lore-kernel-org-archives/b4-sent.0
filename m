From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 15:28:47 -0400
Subject: [PATCH v5 02/21] scripts/kallsyms: Ignore __kcfi_typeid_
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20220901-kcfi_support-v5-2-be2007d8da63@linuxfoundation.org>
References: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
In-Reply-To: <20220901-kcfi_support-v5-0-be2007d8da63@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-03aea
X-Developer-Signature: v=1; a=openpgp-sha256; l=790;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=gRMrvmMoi0C5ZIXtzBavuwMor6N5O7XBd5lDRsBjioc=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIF2X9dPXp85pzpCc7PvI3kJY6e+3Xyyd5lIof1VgvvT8yd
 Uco9raOUhUGMi0FWTJGlbF/spqDChx5y6T2mMHNYmUCGMHBxCsBE7lgz/NNm43Y2+cPy6J7lOpULN3
 beXP+gU9ti1xbXFuZAxfyAaSYM/8utK+ZXW369s2jj3LYpOq5cr145xYs+u6wZEf/nj4P/a04A
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

The compiler generates __kcfi_typeid_ symbols for annotating assembly
functions with type information. These are constants that can be
referenced in assembly code and are resolved by the linker. Ignore
them in kallsyms.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Reviewed-by: Kees Cook <keescook@chromium.org>
Tested-by: Kees Cook <keescook@chromium.org>

diff --git a/scripts/kallsyms.c b/scripts/kallsyms.c
index f18e6dfc68c5..ccdf0c897f31 100644
--- a/scripts/kallsyms.c
+++ b/scripts/kallsyms.c
@@ -119,6 +119,7 @@ static bool is_ignored_symbol(const char *name, char type)
 		"__ThumbV7PILongThunk_",
 		"__LA25Thunk_",		/* mips lld */
 		"__microLA25Thunk_",
+		"__kcfi_typeid_",	/* CFI type identifiers */
 		NULL
 	};
 

-- 
b4 0.10.0-dev-03aea
