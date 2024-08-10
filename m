From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sat, 10 Aug 2024 13:25:16 +0100
Subject: [PATCH kmod 2/2] m4: remove verbose license exception clause
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240810-b4-spdx-fixup-v1-2-b9c84d637fb3@gmail.com>
References: <20240810-b4-spdx-fixup-v1-0-b9c84d637fb3@gmail.com>
In-Reply-To: <20240810-b4-spdx-fixup-v1-0-b9c84d637fb3@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Lucas De Marchi <lucas.de.marchi@gmail.com>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723292726; l=1516;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=4i3lPNK55/Jj+IH1COzPpCNGv9x/md4G29+CkWIv0Os=;
 b=fGnn/BmKGEG0Ko/XAgBKGXb+V0KzcimIZdE5SzHwbL5FJWcxXjAiKzHtKr243Ryw/2dD35cx4
 Qc4uncwgtTSC55hI5nkpgBSe500XCuezBgG7kKzVCZFjZI2YOfjnFgJ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is already encoded in the SPDX license identifier.

Cc: Lucas De Marchi <lucas.de.marchi@gmail.com>
Fixes: b5a2cd0 ("Use SPDX header for license")
Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 m4/features.m4 | 13 -------------
 1 file changed, 13 deletions(-)

diff --git a/m4/features.m4 b/m4/features.m4
index 87ed2fb..6384a05 100644
--- a/m4/features.m4
+++ b/m4/features.m4
@@ -1,19 +1,6 @@
 # SPDX-License-Identifier: GPL-2.0-or-later WITH Autoconf-exception-macro
 #
 #  Copyright (c) 2015 Lucas De Marchi <lucas.de.marchi@gmail.com>
-#
-#  As a special exception, the respective Autoconf Macro's copyright owner
-#  gives unlimited permission to copy, distribute and modify the configure
-#  scripts that are the output of Autoconf when processing the Macro. You
-#  need not follow the terms of the GNU General Public License when using
-#  or distributing such scripts, even though portions of the text of the
-#  Macro appear in them. The GNU General Public License (GPL) does govern
-#  all other use of the material that constitutes the Autoconf Macro.
-#
-#  This special exception to the GPL applies to versions of the Autoconf
-#  Macro released by the Autoconf Archive. When you make and distribute a
-#  modified version of the Autoconf Macro, you may extend this special
-#  exception to the GPL to apply to your modified version as well.
 
 # CC_FEATURE_APPEND([FLAGS], [ENV-TO-CHECK], [FLAG-NAME])
 AC_DEFUN([CC_FEATURE_APPEND], [

-- 
2.45.2

