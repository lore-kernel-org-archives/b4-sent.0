From: Sam Day <me@samcday.com>
Date: Wed, 10 Jun 2026 11:27:39 +1000
Subject: [PATCH v3 01/10] binman: support running multiple tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-android-binman-v3-1-710298a38fcc@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781054859; l=4941;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=kIK+4azIL/AZP4NqypOgT6JI2NsNZfqbJ2OQ35To2Rk=;
 b=BdKTRJLlens/MJwRrM7GJpAio3TClFGOwHf1xkWobo0SreUBpzW0iYurM4X8LTfSoz93ULKGc
 hlHA9bn+2BKAAV5EK6Z2D/Zq+/AZzu5t2uqxlNUfP3Gqb4QB0vlcN9F
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The helptext for `binman test` suggests that this was already supported,
but it wasn't properly wired up.
---
 tools/binman/main.py            |  8 ++++----
 tools/u_boot_pylib/test_util.py | 23 ++++++++++++++++-------
 2 files changed, 20 insertions(+), 11 deletions(-)

diff --git a/tools/binman/main.py b/tools/binman/main.py
index a0c775fd629..5473789361d 100755
--- a/tools/binman/main.py
+++ b/tools/binman/main.py
@@ -58,8 +58,8 @@ def RunTests(debug, verbosity, processes, test_preserve_dirs, args, toolpath):
             the output directory for this test. Both directories are displayed
             on the command line.
         processes: Number of processes to use to run tests (None=same as #CPUs)
-        args: List of positional args provided to binman. This can hold a test
-            name to execute (as in 'binman test testSections', for example)
+        args: List of positional args provided to binman. This can hold test
+            names to execute (as in 'binman test testSections', for example)
         toolpath: List of paths to use for tools
     """
     from binman import bintool_test
@@ -72,13 +72,13 @@ def RunTests(debug, verbosity, processes, test_preserve_dirs, args, toolpath):
     from binman import image_test
     import doctest
 
-    test_name = args and args[0] or None
+    test_names = args or None
 
     # Run the entry tests first ,since these need to be the first to import the
     # 'entry' module.
     result = test_util.run_test_suites(
         'binman', debug, verbosity, False, test_preserve_dirs, processes,
-        test_name, toolpath,
+        test_names, toolpath,
         [bintool_test.TestBintool, entry_test.TestEntry, ftest.TestFunctional,
          fdt_test.TestFdt, elf_test.TestElf, image_test.TestImage,
          cbfs_util_test.TestCbfs, fip_util_test.TestFip])
diff --git a/tools/u_boot_pylib/test_util.py b/tools/u_boot_pylib/test_util.py
index 364596d7a0c..ff275a7b7c0 100644
--- a/tools/u_boot_pylib/test_util.py
+++ b/tools/u_boot_pylib/test_util.py
@@ -157,7 +157,7 @@ def run_test_suites(toolname, debug, verbosity, no_capture, test_preserve_dirs,
             the output directory for this test. Both directories are displayed
             on the command line.
         processes: Number of processes to use to run tests (None=same as #CPUs)
-        test_name: Name of test to run, or None for all
+        test_name: Name of test, or list of test names, to run; None for all
         toolpath: List of paths to use for tools
         class_and_module_list: List of test classes (type class) and module
            names (type str) to run
@@ -182,12 +182,19 @@ def run_test_suites(toolname, debug, verbosity, no_capture, test_preserve_dirs,
         resultclass=FullTextTestResult,
     )
 
-    if use_concurrent and processes != 1 and not test_name:
+    if isinstance(test_name, str):
+        test_names = [test_name]
+    else:
+        test_names = list(test_name or [])
+    test_name_set = set(test_names)
+
+    if use_concurrent and processes != 1 and not test_names:
         suite = ConcurrentTestSuite(suite,
                 fork_for_tests(processes or multiprocessing.cpu_count()))
 
     for module in class_and_module_list:
-        if isinstance(module, str) and (not test_name or test_name == module):
+        if (isinstance(module, str) and
+                (not test_names or module in test_name_set)):
             suite.addTests(doctest.DocTestSuite(module))
 
     for module in class_and_module_list:
@@ -197,15 +204,17 @@ def run_test_suites(toolname, debug, verbosity, no_capture, test_preserve_dirs,
         if hasattr(module, 'setup_test_args'):
             setup_test_args = getattr(module, 'setup_test_args')
             setup_test_args(preserve_indir=test_preserve_dirs,
-                preserve_outdirs=test_preserve_dirs and test_name is not None,
+                preserve_outdirs=test_preserve_dirs and bool(test_names),
                 toolpath=toolpath, verbosity=verbosity, no_capture=no_capture)
-        if test_name:
+        if test_names:
             # Since Python v3.5 If an ImportError or AttributeError occurs
             # while traversing a name then a synthetic test that raises that
             # error when run will be returned. Check that the requested test
             # exists, otherwise these errors are included in the results.
-            if test_name in loader.getTestCaseNames(module):
-                suite.addTests(loader.loadTestsFromName(test_name, module))
+            module_test_names = loader.getTestCaseNames(module)
+            for name in test_names:
+                if name in module_test_names:
+                    suite.addTests(loader.loadTestsFromName(name, module))
         else:
             suite.addTests(loader.loadTestsFromTestCase(module))
 

-- 
2.54.0

