From: Michael Riesch <michael.riesch@collabora.com>
Date: Thu, 10 Apr 2025 22:58:53 +0200
Subject: [PATCH v2 1/2] clang-format: do not allow short enums on a single
 line
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250210-clang-format-fixes-v2-1-37894413bbee@collabora.com>
References: <20250210-clang-format-fixes-v2-0-37894413bbee@collabora.com>
In-Reply-To: <20250210-clang-format-fixes-v2-0-37894413bbee@collabora.com>
To: Miguel Ojeda <ojeda@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Nick Desaulniers <nick.desaulniers+lkml@gmail.com>
Cc: Collabora Kernel Team <kernel@collabora.com>, 
 linux-kernel@vger.kernel.org, llvm@lists.linux.dev, 
 Michael Riesch <michael.riesch@wolfvision.net>, 
 Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744318739; l=1102;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=2Vs71mWhfKOIVP32H7x/aEA2nZetyj4bgJc+AhIa5D8=;
 b=/C8t4Grf9AMtPycJW4PsRdu/pbt3F2HJFhPsBKHdfK+fQdOC0Ajc9AZiR6tERomdTwtV/l2o0
 R5UMxx2M7vVBkLyJOxUiOYwWe5btE08DwH0+rh/3jYgtJz6FY8P6wxT
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Riesch <michael.riesch@wolfvision.net>

clang-format 11 introduced the option "AllowShortEnumsOnASingleLine".
Set it to "false" in order to avoid short enums of the form:

    enum my_short_num { green, red };

With the option set to "false", they will be converted to

    enum my_short_num {
            green,
            red
    };

which is consistent with the definition of enums with more items.

Signed-off-by: Michael Riesch <michael.riesch@wolfvision.net>
Reviewed-by: Nathan Chancellor <nathan@kernel.org>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 .clang-format | 1 +
 1 file changed, 1 insertion(+)

diff --git a/.clang-format b/.clang-format
index fe1aa1a30d40..8040b516185b 100644
--- a/.clang-format
+++ b/.clang-format
@@ -19,6 +19,7 @@ AlignTrailingComments: false
 AllowAllParametersOfDeclarationOnNextLine: false
 AllowShortBlocksOnASingleLine: false
 AllowShortCaseLabelsOnASingleLine: false
+AllowShortEnumsOnASingleLine: false
 AllowShortFunctionsOnASingleLine: None
 AllowShortIfStatementsOnASingleLine: false
 AllowShortLoopsOnASingleLine: false

-- 
2.39.5

