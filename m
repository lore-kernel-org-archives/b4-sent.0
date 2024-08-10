From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sat, 10 Aug 2024 13:25:15 +0100
Subject: [PATCH kmod 1/2] m4: reinstate CC_CHECK_FLAG_APPEND summary
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240810-b4-spdx-fixup-v1-1-b9c84d637fb3@gmail.com>
References: <20240810-b4-spdx-fixup-v1-0-b9c84d637fb3@gmail.com>
In-Reply-To: <20240810-b4-spdx-fixup-v1-0-b9c84d637fb3@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Lucas De Marchi <lucas.de.marchi@gmail.com>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723292726; l=1027;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=AF5iab6GulDH6KmEHj4ODm9E17GVEFRi9ewJjoqAJxU=;
 b=Ls03SQmbnebXlYWpWG9+yJ9PaeeS0fQ2iuxdZkWLxtXon5xzBQeH2P3n0VdRbGzrgBvGqLlEW
 tr3YjJ/YwLsBfzTvOTYSpWeSVTU19XpxkVis9f/AbExN5Zl2tEA+n0Q
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Earlier commit was reducing the license boilerplate to SPDX license
identifiers and erroneously dropped the function summary section.

Cc: Lucas De Marchi <lucas.de.marchi@gmail.com>
Fixes: b5a2cd0 ("Use SPDX header for license")
Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 m4/attributes.m4 | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/m4/attributes.m4 b/m4/attributes.m4
index 69865ee..a22bb58 100644
--- a/m4/attributes.m4
+++ b/m4/attributes.m4
@@ -4,6 +4,11 @@
 # Copyright (c) 2006-2008 xine project
 # Copyright (c) 2012 Lucas De Marchi <lucas.de.marchi@gmail.com>
 
+# Check if FLAG in ENV-VAR is supported by compiler and append it
+# to WHERE-TO-APPEND variable. Note that we invert -Wno-* checks to
+# -W* as gcc cannot test for negated warnings.
+# CC_CHECK_FLAG_APPEND([WHERE-TO-APPEND], [ENV-VAR], [FLAG])
+
 AC_DEFUN([CC_CHECK_FLAG_APPEND], [
   AC_CACHE_CHECK([if $CC supports flag $3 in envvar $2],
                  AS_TR_SH([cc_cv_$2_$3]),

-- 
2.45.2

