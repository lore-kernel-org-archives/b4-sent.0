From: Prateekshit Jaiswal <prateekshitjaiswal73@gmail.com>
Date: Sat, 14 Nov 2026 11:44:09 +0530
Subject: [PATCH 2/2] docs: kdoc: don't print warnings of stored entries
 twice
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-kdoc-dup-warnings-v1-2-265f89bc3f9c@gmail.com>
References: <20261114-kdoc-dup-warnings-v1-0-265f89bc3f9c@gmail.com>
In-Reply-To: <20261114-kdoc-dup-warnings-v1-0-265f89bc3f9c@gmail.com>
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Prateekshit Jaiswal <prateekshitjaiswal73@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794636849; l=5723;
 i=prateekshitjaiswal73@gmail.com; s=20261107; h=from:subject:message-id;
 bh=Dt4V+mOJct8QU5hxnTe0SDVaaxQ3Jn2Hrk2c1EC3JUE=;
 b=KKkXyMmi8Zg3mVNSXlBvv7/M48TKyQ4HyG7cCb7dh7mqo9Y1Otq9qmdDcP6o5EzXXAApJmAm+
 UCQbFyLZ70QAjds6PjfVo2aQZIE4DZdZCLjKG0CJ+lSEPqxWDIscbTf
X-Developer-Key: i=prateekshitjaiswal73@gmail.com; a=ed25519;
 pk=Z9QqjsqOUk3AvD5zQ8B+Kufufuvk9wEO7eT9m1nMJdo=
X-Endpoint-Received: by B4 Relay for prateekshitjaiswal73@gmail.com/20261107 with auth_id=1445
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 469c1c9eb6c9 ("kernel-doc: Issue warnings that were silently
discarded") was meant to print warnings of entries that never reach
the output step. With no symbol filter, kernel-doc now prints the
warnings of every documented symbol twice:

  $ ./scripts/kernel-doc -none -Wall drivers/gpu/drm/i915/display/intel_dkl_phy.c
  Warning: drivers/gpu/drm/i915/display/intel_dkl_phy.c:47 No description found for return value of 'intel_dkl_phy_read'
  Warning: drivers/gpu/drm/i915/display/intel_dkl_phy.c:47 No description found for return value of 'intel_dkl_phy_read'

The flush uses "self.entry not in self.entries" to tell stored entries
from discarded ones. output_declaration() stores a new KdocItem built
from the entry, never the KernelEntry itself, so that test is always
true. Every stored entry then warns once in the parser and once in the
output plugin.

Those parser-side prints also ignore the later symbol filter, so
"-function intel_dkl_phy_write" still warns about intel_dkl_phy_read().
Commit 292eca316321 ("docs: kdoc: fix logic to handle unissued
warnings") routes the flush through config.warning(), which increments
the warning count. -Werror then reports "2 warnings as errors" for a
single warning, and a -function run fails because of a different
symbol.

Mark the entry as stored in output_declaration(), flush warnings only
for entries that were not stored, and add tests for both cases. This
needs the previous patch. Without it, symbols selected with -function
or -export would lose their warnings.

Running "kernel-doc -none -Wall" over the 10320 .c and .h files with
kernel-doc comments, the output shrinks from 87900 to 49625 lines,
while the set of distinct lines stays the same.

The problem was found, and the fix and tests drafted, with the help of
an AI coding assistant (Claude Code); I have reviewed and tested the
result.

Fixes: 469c1c9eb6c9 ("kernel-doc: Issue warnings that were silently discarded")
Signed-off-by: Prateekshit Jaiswal <prateekshitjaiswal73@gmail.com>
---
 tools/lib/python/kdoc/kdoc_parser.py |  4 ++-
 tools/unittests/test_kdoc_parser.py  | 55 ++++++++++++++++++++++++++++++++++++
 2 files changed, 58 insertions(+), 1 deletion(-)

diff --git a/tools/lib/python/kdoc/kdoc_parser.py b/tools/lib/python/kdoc/kdoc_parser.py
index 80d4245acd17..ef5879b05308 100644
--- a/tools/lib/python/kdoc/kdoc_parser.py
+++ b/tools/lib/python/kdoc/kdoc_parser.py
@@ -135,6 +135,7 @@ class KernelEntry:
         self.prototype = ""
 
         self.warnings = []
+        self.stored = False
 
         self.parameterlist = []
         self.parameterdescs = {}
@@ -323,6 +324,7 @@ class KernelDoc:
                         self.entry.parametertypes,
                         self.entry.parameterdesc_start_lines)
         self.entries.append(item)
+        self.entry.stored = True
 
         self.config.log.debug("Output: %s:%s = %s", dtype, name, pformat(args))
 
@@ -346,7 +348,7 @@ class KernelDoc:
               during the output step of the code, depending on the
               selected symbols.
         """
-        if self.entry and self.entry not in self.entries:
+        if self.entry and not self.entry.stored:
             for log_msg in self.entry.warnings:
                 self.config.warning(log_msg)
 
diff --git a/tools/unittests/test_kdoc_parser.py b/tools/unittests/test_kdoc_parser.py
index 35f7a140942d..709455a4b39c 100755
--- a/tools/unittests/test_kdoc_parser.py
+++ b/tools/unittests/test_kdoc_parser.py
@@ -567,6 +567,61 @@ class TestContextLockStruct(GenerateKdocItem):
         self.assertEqual(entries[0].name, "debugfs_cancellation")
         self.assertEqual(entries[0].warnings, [])
 
+class TestUnusedWarnings(GenerateKdocItem):
+    """
+    Test that the parser itself only emits warnings of discarded entries.
+    """
+
+    def parse(self, source):
+        """
+        Parse source, returning the entries and the warnings emitted.
+        """
+        kernel_doc = KernelDoc(self.config, "test.c", self.xforms)
+
+        with patch('builtins.open', new_callable=mock_open,
+                   read_data=dedent(source)):
+            with patch.object(self.config, 'warning') as warning:
+                _, entries = kernel_doc.parse_kdoc()
+
+        return entries, [call.args[0] for call in warning.call_args_list]
+
+    def test_stored_entry(self):
+        """
+        Warnings of a stored entry are left for the output step, which
+        applies the symbol filters, so they must not be emitted here.
+        """
+        source = """
+            /**
+             * func - Do nothing
+             */
+            int func(int arg) { return 0; }
+        """
+
+        entries, emitted = self.parse(source)
+
+        self.assertEqual(len(entries), 1)
+        self.assertEqual(len(entries[0].warnings), 1)
+        self.assertIn("'arg' not described", entries[0].warnings[0])
+        self.assertEqual(emitted, [])
+
+    def test_discarded_entry(self):
+        """
+        Warnings of an entry that is never stored are emitted once.
+        """
+        source = """
+            /**
+             * to_user_ptr - cast a u64 to a user space pointer
+             * @x: the u64 to convert
+             */
+            #define u64_to_user_ptr(x) ((void __user *)(uintptr_t)(x))
+        """
+
+        entries, emitted = self.parse(source)
+
+        self.assertEqual(entries, [])
+        self.assertEqual(len(emitted), 1)
+        self.assertIn("expecting prototype for to_user_ptr()", emitted[0])
+
 #
 # Class and logic to create dynamic tests from YAML
 #

-- 
2.53.0

