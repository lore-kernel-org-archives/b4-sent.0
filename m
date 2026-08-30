From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 20:24:54 +0200
Subject: [PATCH 1/2] dt-check-style: Handle indented fragments in
 indent-unit-dts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-dts-check-fix-v1-1-e7c1b2774730@kernel.org>
References: <20260830-b4-dts-check-fix-v1-0-e7c1b2774730@kernel.org>
In-Reply-To: <20260830-b4-dts-check-fix-v1-0-e7c1b2774730@kernel.org>
To: Rob Herring <robh@kernel.org>, Saravana Kannan <saravanak@kernel.org>
Cc: Daniel Golle <daniel@makrotopia.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, asahi@lists.linux.dev, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7155; i=sven@kernel.org;
 h=from:subject:message-id; bh=uNyo1KeB0l/zhhOV3ClmH6VMvBYFLbaYjk2fSTkapm0=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aU0lr7E7usmuy7rj/S8ZC30JctVtx6P0XOLKrqxAXLW
 XkPpi3vKGVhEONikBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAEzkw1uGP/xvN81wb07aL3ft
 /qvbv/bfyl+Q1/30bPXZzGtM8QsO59kxMtx9vvDyP2t+ra3l4vsW7f9Yzah/OED5S931mxsXi8U
 winEAAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The multi-die Apple SoCs contain most of their nodes in a file that is
included to instantiate the same nodes across both dies. These included
fragments all have a tabs-only prefix that is correct in the final
composed file. dt-check-style however finds the first line starting with
two (or more) tabs and then indent-unit-dts rejects those correctly
indented files.

Fix that by detecing a tabs-only prefix shared by rootless files and
treat that as a constant offset. Also add fixtures to test this.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 scripts/dtc/dt-check-style                         | 69 +++++++++++++++++-----
 .../bad/dts-fragment-missing-prefix.dtsi           |  6 ++
 .../bad/dts-indented-ref-node.dtsi                 |  6 ++
 .../expected/dts-fragment-missing-prefix.dtsi.txt  |  2 +
 .../expected/dts-indented-ref-node.dtsi.txt        |  2 +
 5 files changed, 70 insertions(+), 15 deletions(-)

diff --git a/scripts/dtc/dt-check-style b/scripts/dtc/dt-check-style
index 96deffc0d8a7..2afc05fa6602 100755
--- a/scripts/dtc/dt-check-style
+++ b/scripts/dtc/dt-check-style
@@ -380,12 +380,43 @@ def check_mixed_indent_chars(ctx):
                 yield (cont.lineno, 'mixed tabs and spaces in indent')
 
 
+def detect_fragment_offset(ctx):
+    """Return the indentation inherited from an include context.
+
+    A fragment has neither a root nor top-level reference nodes and all
+    its top-level lines share the same tabs-only indentation.
+    """
+    if ctx.file_type != 'dts':
+        return ''
+    offset = None
+    for dl in ctx.lines:
+        if dl.depth != 0:
+            continue
+        if dl.linetype not in (LineType.NODE_OPEN, LineType.NODE_CLOSE,
+                               LineType.PROPERTY):
+            continue
+        if dl.linetype == LineType.NODE_OPEN and \
+                (dl.node_name == '/' or dl.ref_name is not None):
+            return ''
+        if offset is None:
+            offset = dl.indent_str
+        elif dl.indent_str != offset:
+            return ''
+    if not offset:
+        return ''
+    if any(char != '\t' for char in offset):
+        return ''
+    return offset
+
+
 def detect_indent_unit(ctx):
     """Find the indent unit used at depth 1 in this block.
 
     Returns tuple of string (one of: '  ' (2 spaces), '    ' (4 spaces),
-    '\\t' (tab), or None if depth-1 is empty or ambiguous) and line number when
-    detection was made)."""
+    '\\t' (tab), or None if depth-1 is empty or ambiguous), line number when
+    detection was made, and whether the detected fragment prefix is valid.
+    """
+    prefix = detect_fragment_offset(ctx)
     for dl in ctx.lines:
         if dl.depth != 1:
             continue
@@ -395,20 +426,25 @@ def detect_indent_unit(ctx):
             continue
         if not dl.indent_str:
             continue
-        if dl.indent_str == '\t':
-            return ('\t', dl.lineno)
-        if dl.indent_str == '    ':
-            return ('    ', dl.lineno)
-        if dl.indent_str == '  ':
-            return ('  ', dl.lineno)
+        indent = dl.indent_str
+        if prefix and not indent.startswith(prefix):
+            return (indent, dl.lineno, False)
+        if prefix:
+            indent = indent[len(prefix):]
+        if indent == '\t':
+            return ('\t', dl.lineno, True)
+        if indent == '    ':
+            return ('    ', dl.lineno, True)
+        if indent == '  ':
+            return ('  ', dl.lineno, True)
         # Anything else at depth 1 is non-canonical; flag elsewhere.
-        return (dl.indent_str, dl.lineno)
-    return (None, None)
+        return (indent, dl.lineno, True)
+    return (None, None, True)
 
 
 def check_indent_unit_relaxed(ctx):
     """YAML examples: 2 or 4 spaces. Never tabs or other widths."""
-    (unit, lineno) = detect_indent_unit(ctx)
+    (unit, lineno, _) = detect_indent_unit(ctx)
     if unit is None:
         return
     if unit not in ('  ', '    '):
@@ -417,7 +453,10 @@ def check_indent_unit_relaxed(ctx):
 
 def check_indent_unit_dts(ctx):
     """DTS files: 1 tab per level. Always required."""
-    (unit, lineno) = detect_indent_unit(ctx)
+    (unit, lineno, prefix_valid) = detect_indent_unit(ctx)
+    if not prefix_valid:
+        yield (lineno, 'indent does not start with fragment offset')
+        return
     if unit is None:
         return
     if unit != '\t':
@@ -426,7 +465,7 @@ def check_indent_unit_dts(ctx):
 
 def check_indent_unit_strict(ctx):
     """YAML: must be exactly 4 spaces. DTS: 1 tab (same as relaxed)."""
-    (unit, lineno) = detect_indent_unit(ctx)
+    (unit, lineno, _) = detect_indent_unit(ctx)
     if unit is None:
         return
     if ctx.file_type == 'yaml':
@@ -437,8 +476,8 @@ def check_indent_unit_strict(ctx):
 
 def check_indent_consistent(ctx):
     """All indented lines must be a multiple of the detected unit."""
-    (unit, lineno) = detect_indent_unit(ctx)
-    if unit is None:
+    (unit, lineno, prefix_valid) = detect_indent_unit(ctx)
+    if unit is None or not prefix_valid:
         return
     if ctx.file_type == 'yaml':
         if unit not in ('  ', '    '):
diff --git a/scripts/dtc/dt-style-selftest/bad/dts-fragment-missing-prefix.dtsi b/scripts/dtc/dt-style-selftest/bad/dts-fragment-missing-prefix.dtsi
new file mode 100644
index 000000000000..a72735e0884b
--- /dev/null
+++ b/scripts/dtc/dt-style-selftest/bad/dts-fragment-missing-prefix.dtsi
@@ -0,0 +1,6 @@
+// SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+/* Include fragment whose child does not contain the inherited indentation. */
+
+		bus@10000 {
+	compatible = "simple-bus";
+		};
diff --git a/scripts/dtc/dt-style-selftest/bad/dts-indented-ref-node.dtsi b/scripts/dtc/dt-style-selftest/bad/dts-indented-ref-node.dtsi
new file mode 100644
index 000000000000..cabe4ee96d10
--- /dev/null
+++ b/scripts/dtc/dt-style-selftest/bad/dts-indented-ref-node.dtsi
@@ -0,0 +1,6 @@
+// SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+/* Reference nodes must remain at column zero. */
+
+	&example {
+		status = "okay";
+	};
diff --git a/scripts/dtc/dt-style-selftest/expected/dts-fragment-missing-prefix.dtsi.txt b/scripts/dtc/dt-style-selftest/expected/dts-fragment-missing-prefix.dtsi.txt
new file mode 100644
index 000000000000..eb525dddd904
--- /dev/null
+++ b/scripts/dtc/dt-style-selftest/expected/dts-fragment-missing-prefix.dtsi.txt
@@ -0,0 +1,2 @@
+# mode=relaxed
+bad/dts-fragment-missing-prefix.dtsi:5: [indent-unit-dts] indent does not start with fragment offset
diff --git a/scripts/dtc/dt-style-selftest/expected/dts-indented-ref-node.dtsi.txt b/scripts/dtc/dt-style-selftest/expected/dts-indented-ref-node.dtsi.txt
new file mode 100644
index 000000000000..ed86cc9b36c6
--- /dev/null
+++ b/scripts/dtc/dt-style-selftest/expected/dts-indented-ref-node.dtsi.txt
@@ -0,0 +1,2 @@
+# mode=strict
+bad/dts-indented-ref-node.dtsi:5: [indent-unit-dts] indent unit must be 1 tab in DTS, got '\t\t'

-- 
2.55.0

