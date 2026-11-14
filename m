From: Prateekshit Jaiswal <prateekshitjaiswal73@gmail.com>
Date: Sat, 14 Nov 2026 11:44:08 +0530
Subject: [PATCH 1/2] docs: kdoc: emit warnings for symbols selected with
 -function/-export
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-kdoc-dup-warnings-v1-1-265f89bc3f9c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794636849; l=5015;
 i=prateekshitjaiswal73@gmail.com; s=20261107; h=from:subject:message-id;
 bh=sMPzBKJW3ciyPVffUZVgGMn0wTa3lXZSu57g8NNQ69U=;
 b=u2V9+Y4Q8riBQTX7km53qzUFfjGn4e1TtYJuO/GGp7UcVc8yXysPzuN9+oA8FC8tBDVXAUv9M
 FLPX0sLYi17AMDTFuHciZETg1FzodcMn4VZvOd4mb7K9r8iUX+HXYRe
X-Developer-Key: i=prateekshitjaiswal73@gmail.com; a=ed25519;
 pk=Z9QqjsqOUk3AvD5zQ8B+Kufufuvk9wEO7eT9m1nMJdo=
X-Endpoint-Received: by B4 Relay for prateekshitjaiswal73@gmail.com/20261107 with auth_id=1445
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 9cbc2d3b137b ("scripts/kernel-doc.py: postpone warnings to the
output plugin") moved warning output into
OutputFormat.check_declaration(), which is supposed to print the
warnings of each symbol it lets through. The OUTPUT_INCLUDE and
OUTPUT_EXPORTED branch returns without that call, so -function,
-export, and the Sphinx kernel-doc :identifiers: and :export: options
drop the warnings of the symbols they keep. On v6.18 the command below
prints nothing, even though intel_dkl_phy_read() does not describe its
return value:

  $ ./scripts/kernel-doc -none -Wall -function intel_dkl_phy_read drivers/gpu/drm/i915/display/intel_dkl_phy.c

From v6.19 the warning still appears, because the parser prints the
warnings of every entry itself. That is a separate bug, fixed in the
next patch. Fixing only that one would make this gap visible again.
Until then, this change prints the selected symbols' warnings twice in
these modes.

Call out_warnings() in that branch as well, as the other modes do, and
add tests for the warnings shown with each output filter.

The problem was found, and the fix and tests drafted, with the help of
an AI coding assistant (Claude Code); I have reviewed and tested the
result.

Fixes: 9cbc2d3b137b ("scripts/kernel-doc.py: postpone warnings to the output plugin")
Signed-off-by: Prateekshit Jaiswal <prateekshitjaiswal73@gmail.com>
---
 tools/lib/python/kdoc/kdoc_output.py |  1 +
 tools/unittests/test_kdoc_parser.py  | 71 ++++++++++++++++++++++++++++++++++++
 2 files changed, 72 insertions(+)

diff --git a/tools/lib/python/kdoc/kdoc_output.py b/tools/lib/python/kdoc/kdoc_output.py
index 659a2c6fb6be..e0f24302cbc4 100644
--- a/tools/lib/python/kdoc/kdoc_output.py
+++ b/tools/lib/python/kdoc/kdoc_output.py
@@ -167,6 +167,7 @@ class OutputFormat:
 
         if self.out_mode in [self.OUTPUT_INCLUDE, self.OUTPUT_EXPORTED]:
             if name in self.function_table:
+                self.out_warnings(args)
                 return True
 
         if self.out_mode == self.OUTPUT_INTERNAL:
diff --git a/tools/unittests/test_kdoc_parser.py b/tools/unittests/test_kdoc_parser.py
index 6e305988cb6d..35f7a140942d 100755
--- a/tools/unittests/test_kdoc_parser.py
+++ b/tools/unittests/test_kdoc_parser.py
@@ -353,6 +353,77 @@ class ManFilterTail(unittest.TestCase):
         self.assertEqual(self.run_filter(export=True), "")
 
 
+class OutputFilterWarnings(unittest.TestCase):
+    """
+    The output step shows the warnings of the symbols it outputs, once.
+    """
+
+    source = dedent("""
+        /**
+         * foo - First function
+         */
+        int foo(int a) { return 0; };
+
+        /**
+         * bar - Second function
+         * @b: an argument
+         */
+        int bar(int b) { return 0; };
+    """)
+
+    def setUp(self):
+        self.config = MockKdocConfig()
+        kernel_doc = KernelDoc(self.config, "mock.c", CTransforms())
+
+        with patch('builtins.open', new_callable=mock_open,
+                   read_data=self.source):
+            with patch.object(self.config, 'warning'):
+                _, self.entries = kernel_doc.parse_kdoc()
+
+        self.out_style = ManFormat()
+        self.out_style.set_config(self.config)
+
+    def run_filter(self, **kwargs):
+        args = {"export": False, "internal": False, "symbol": None,
+                "nosymbol": None, "function_table": set(),
+                "enable_lineno": False, "no_doc_sections": False}
+        args.update(kwargs)
+
+        self.out_style.set_filter(**args)
+
+        with patch.object(self.config, 'warning') as warning:
+            self.out_style.output_symbols("mock.c", self.entries)
+
+        return [call.args[0] for call in warning.call_args_list]
+
+    def test_all_symbols(self):
+        """Without a filter, the warning of foo is shown."""
+        warnings = self.run_filter()
+
+        self.assertEqual(len(warnings), 1)
+        self.assertIn("'a' not described in 'foo'", warnings[0])
+
+    def test_selected_symbol(self):
+        """The warning of a symbol selected by name is shown."""
+        warnings = self.run_filter(symbol=["foo"], function_table={"foo"})
+
+        self.assertEqual(len(warnings), 1)
+        self.assertIn("'a' not described in 'foo'", warnings[0])
+
+    def test_exported_symbol(self):
+        """The warning of an exported symbol is shown."""
+        warnings = self.run_filter(export=True, function_table={"foo"})
+
+        self.assertEqual(len(warnings), 1)
+        self.assertIn("'a' not described in 'foo'", warnings[0])
+
+    def test_other_symbol(self):
+        """The warning of a symbol that is not selected is not shown."""
+        warnings = self.run_filter(symbol=["bar"], function_table={"bar"})
+
+        self.assertEqual(warnings, [])
+
+
 class CToRest(unittest.TestCase):
     out_style = RestFormat()
     config = MockKdocConfig()

-- 
2.53.0

