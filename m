From: Sam Day <me@samcday.com>
Date: Wed, 10 Jun 2026 11:27:40 +1000
Subject: [PATCH v3 02/10] binman: test name globbing support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-android-binman-v3-2-710298a38fcc@samcday.com>
References: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
In-Reply-To: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Rasmus Villemoes <ravi@prevas.dk>, Javier Tia <floss@jetm.me>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, yan wang <yan.wang@softathome.com>, 
 Marek Vasut <marex@nabladev.com>, Denis Mukhin <dmukhin@ford.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781054859; l=3070;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=WQnxi6Rd5nSb22GQsdLENqKhq48kpIGbbQvj2Kbi7wI=;
 b=5n0TnMtQSfKkLDEtWDjsTKLc8y5IM6TmM2FfQsJUELnsCRTmc4j3+7vd6LKBIIs9NKqs5Mp7P
 EmpH5waqVe4D7hqxrPw02vnxHKqR/Gx9wxvjNcTxdBDQU6rtwythOSy
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This makes invocations like `binman test testAndroid*` possible. It also
composes well with the previous commit that adds support for multiple
test names: `binman test 'testAndroid*' 'testQcdt*'` also works as you'd
expect.
---
 tools/binman/cmdline.py         |  2 +-
 tools/u_boot_pylib/test_util.py | 12 +++++++-----
 2 files changed, 8 insertions(+), 6 deletions(-)

diff --git a/tools/binman/cmdline.py b/tools/binman/cmdline.py
index 9632ec115e5..b3be9f79b20 100644
--- a/tools/binman/cmdline.py
+++ b/tools/binman/cmdline.py
@@ -201,7 +201,7 @@ controlled by a description in the board device tree.'''
                  'preserve the output directory if a single test is run (pass '
                  'test name at the end of the command line')
         test_parser.add_argument('tests', nargs='*',
-                                 help='Test names to run (omit for all)')
+                                 help='Test names/patterns to run (omit for all)')
 
     tool_parser = subparsers.add_parser('tool', help='Check bintools')
     tool_parser.add_argument('-l', '--list', action='store_true',
diff --git a/tools/u_boot_pylib/test_util.py b/tools/u_boot_pylib/test_util.py
index ff275a7b7c0..2089b3574ca 100644
--- a/tools/u_boot_pylib/test_util.py
+++ b/tools/u_boot_pylib/test_util.py
@@ -4,6 +4,7 @@
 #
 
 import doctest
+import fnmatch
 import glob
 import multiprocessing
 import os
@@ -186,7 +187,9 @@ def run_test_suites(toolname, debug, verbosity, no_capture, test_preserve_dirs,
         test_names = [test_name]
     else:
         test_names = list(test_name or [])
-    test_name_set = set(test_names)
+
+    def _match_name(name):
+        return any(fnmatch.fnmatchcase(name, pattern) for pattern in test_names)
 
     if use_concurrent and processes != 1 and not test_names:
         suite = ConcurrentTestSuite(suite,
@@ -194,7 +197,7 @@ def run_test_suites(toolname, debug, verbosity, no_capture, test_preserve_dirs,
 
     for module in class_and_module_list:
         if (isinstance(module, str) and
-                (not test_names or module in test_name_set)):
+                (not test_names or _match_name(module))):
             suite.addTests(doctest.DocTestSuite(module))
 
     for module in class_and_module_list:
@@ -211,9 +214,8 @@ def run_test_suites(toolname, debug, verbosity, no_capture, test_preserve_dirs,
             # while traversing a name then a synthetic test that raises that
             # error when run will be returned. Check that the requested test
             # exists, otherwise these errors are included in the results.
-            module_test_names = loader.getTestCaseNames(module)
-            for name in test_names:
-                if name in module_test_names:
+            for name in loader.getTestCaseNames(module):
+                if _match_name(name):
                     suite.addTests(loader.loadTestsFromName(name, module))
         else:
             suite.addTests(loader.loadTestsFromTestCase(module))

-- 
2.54.0

