From: Michael Riesch <michael.riesch@collabora.com>
Date: Thu, 10 Apr 2025 22:58:54 +0200
Subject: [PATCH v2 2/2] clang-format: align consecutive macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250210-clang-format-fixes-v2-2-37894413bbee@collabora.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744318740; l=1371;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=GCAcQLFrMA5v4a8RQ+v4hX/83CyGkOIzdbZt9W/iAMo=;
 b=eQYqQ3YfPADGuVnklkfGZ8zn5fc1Ke7BHBl6FyFpdefybbJRw2NKRRgfdiT6BGn/jlXU6U0L/
 32RqDjGfhLxDmqi61M2ZhSnT4keDU3L/iW3teyy6fMOiOL7q/ex73wB
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Riesch <michael.riesch@wolfvision.net>

clang-format 9 introduced the option "AlignConsecutiveMacros".
Set it to "AcrossEmptyLinesAndComments" in order to avoid macro
definitions of the form:

    #define MAGIC_REGISTER_1 0x42
    #define MAGIC_REGISTER_BIT_FLIP BIT(2)
    /* important comment */
    #define MAGIC_REGISTER_BIT_ENABLE BIT(12)

    #define MAGIC_REGISTER_2 0x43

With the option set to "AcrossEmptyLinesAndComments", they will
be converted to

    #define MAGIC_REGISTER_1	      0x42
    #define MAGIC_REGISTER_BIT_FLIP   BIT(2)
    /* important comment */
    #define MAGIC_REGISTER_BIT_ENABLE BIT(12)

    #define MAGIC_REGISTER_2	      0x43

which seems to be the convention in the kernel code base.

Signed-off-by: Michael Riesch <michael.riesch@wolfvision.net>
Reviewed-by: Nathan Chancellor <nathan@kernel.org>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 .clang-format | 1 +
 1 file changed, 1 insertion(+)

diff --git a/.clang-format b/.clang-format
index 8040b516185b..30d09cb88170 100644
--- a/.clang-format
+++ b/.clang-format
@@ -13,6 +13,7 @@ AccessModifierOffset: -4
 AlignAfterOpenBracket: Align
 AlignConsecutiveAssignments: false
 AlignConsecutiveDeclarations: false
+AlignConsecutiveMacros: AcrossEmptyLinesAndComments
 AlignEscapedNewlines: Left
 AlignOperands: true
 AlignTrailingComments: false

-- 
2.39.5

