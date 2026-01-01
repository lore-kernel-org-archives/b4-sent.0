From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 01 Jan 2026 15:31:06 +0100
Subject: [PATCH u-boot] docs: kdoc: handle the obsolescensce of
 docutils.ErrorString()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260101-docutils-v1-1-81391910aca3@posteo.net>
X-B4-Tracking: v=1; b=H4sIACmFVmkC/x3MWwqAIBBA0a3EfCdo9LKtRB9mYw2Eho8IpL0nf
 R643AwBPWGAqcrg8aZAzhaIugJ9KLsjo60YGt70XHDBNqdTpDOwbpRSGa700K5Q8sujoedfzZD
 Y6lyE5X0/wNZtTWIAAAA=
X-Change-ID: 20260101-docutils-5899af0ac74b
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Jonathan Corbet <corbet@lwn.net>, 
 Zhixu Liu <zhixu.liu@gmail.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767277878; l=4083;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=X+ud5m4tMvl7KK+Kta/xOUP34NyNCr/0wkt3Cx3VRSU=;
 b=ELZSwuto/iuklWehD7d86Xx9KlyxfFxrnB1UWPtZMIEbNv1imllimJGYf+3Bq8TlDVaaecH8c
 Cm0Cy+k8T6zAtpmJEgL5lZC+3Xm7mcki1uJ7TO3LefKGpgLT62XU/Np
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ErrorString() and SafeString() docutils functions were helpers meant to
ease the handling of encodings during the Python 3 transition.  There is no
real need for them after Python 3.6, and docutils 0.22 removes them,
breaking the docs build

Handle this by just injecting our own one-liner version of ErrorString(),
and removing the sole SafeString() call entirely.

Reported-by: Zhixu Liu <zhixu.liu@gmail.com>
Signed-off-by: Jonathan Corbet <corbet@lwn.net>
Upstream: https://git.kernel.org/linus/00d95fcc4dee66dfb6980de6f2973b32f973a1eb
[j.ne: Adapted from Linux to U-Boot]
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 doc/sphinx/kernel_abi.py          | 4 +++-
 doc/sphinx/kernel_feat.py         | 4 +++-
 doc/sphinx/kernel_include.py      | 6 ++++--
 doc/sphinx/maintainers_include.py | 4 +++-
 4 files changed, 13 insertions(+), 5 deletions(-)

diff --git a/doc/sphinx/kernel_abi.py b/doc/sphinx/kernel_abi.py
index 32c50e496b5..930e9273b16 100644
--- a/doc/sphinx/kernel_abi.py
+++ b/doc/sphinx/kernel_abi.py
@@ -44,7 +44,9 @@ from os import path
 from docutils import nodes, statemachine
 from docutils.statemachine import ViewList
 from docutils.parsers.rst import directives, Directive
-from docutils.utils.error_reporting import ErrorString
+
+def ErrorString(exc):  # Shamelessly stolen from docutils
+    return f'{exc.__class__.__name}: {exc}'
 
 #
 # AutodocReporter is only good up to Sphinx 1.7
diff --git a/doc/sphinx/kernel_feat.py b/doc/sphinx/kernel_feat.py
index 2fee04f1ded..cca48f6f1a4 100644
--- a/doc/sphinx/kernel_feat.py
+++ b/doc/sphinx/kernel_feat.py
@@ -41,7 +41,9 @@ from os import path
 from docutils import nodes, statemachine
 from docutils.statemachine import ViewList
 from docutils.parsers.rst import directives, Directive
-from docutils.utils.error_reporting import ErrorString
+
+def ErrorString(exc):  # Shamelessly stolen from docutils
+    return f'{exc.__class__.__name}: {exc}'
 
 #
 # AutodocReporter is only good up to Sphinx 1.7
diff --git a/doc/sphinx/kernel_include.py b/doc/sphinx/kernel_include.py
index f523aa68a36..6522de9dd69 100755
--- a/doc/sphinx/kernel_include.py
+++ b/doc/sphinx/kernel_include.py
@@ -34,11 +34,13 @@ u"""
 import os.path
 
 from docutils import io, nodes, statemachine
-from docutils.utils.error_reporting import SafeString, ErrorString
 from docutils.parsers.rst import directives
 from docutils.parsers.rst.directives.body import CodeBlock, NumberLines
 from docutils.parsers.rst.directives.misc import Include
 
+def ErrorString(exc):  # Shamelessly stolen from docutils
+    return f'{exc.__class__.__name}: {exc}'
+
 __version__  = '1.0'
 
 # ==============================================================================
@@ -109,7 +111,7 @@ class KernelInclude(Include):
             raise self.severe('Problems with "%s" directive path:\n'
                               'Cannot encode input file path "%s" '
                               '(wrong locale?).' %
-                              (self.name, SafeString(path)))
+                              (self.name, path))
         except IOError as error:
             raise self.severe('Problems with "%s" directive path:\n%s.' %
                       (self.name, ErrorString(error)))
diff --git a/doc/sphinx/maintainers_include.py b/doc/sphinx/maintainers_include.py
index 13557d3d3c2..ab79a74dc0c 100755
--- a/doc/sphinx/maintainers_include.py
+++ b/doc/sphinx/maintainers_include.py
@@ -22,10 +22,12 @@ import re
 import os.path
 
 from docutils import statemachine
-from docutils.utils.error_reporting import ErrorString
 from docutils.parsers.rst import Directive
 from docutils.parsers.rst.directives.misc import Include
 
+def ErrorString(exc):  # Shamelessly stolen from docutils
+    return f'{exc.__class__.__name}: {exc}'
+
 __version__  = '1.0'
 
 def setup(app):

---
base-commit: bb28daf51301546fc2b6882e51f39f5d12952375
change-id: 20260101-docutils-5899af0ac74b

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

