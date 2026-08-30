From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 20:24:55 +0200
Subject: [PATCH 2/2] dt-check-style: Handle indented fragments in
 indent-consistent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-dts-check-fix-v1-2-e7c1b2774730@kernel.org>
References: <20260830-b4-dts-check-fix-v1-0-e7c1b2774730@kernel.org>
In-Reply-To: <20260830-b4-dts-check-fix-v1-0-e7c1b2774730@kernel.org>
To: Rob Herring <robh@kernel.org>, Saravana Kannan <saravanak@kernel.org>
Cc: Daniel Golle <daniel@makrotopia.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, asahi@lists.linux.dev, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3411; i=sven@kernel.org;
 h=from:subject:message-id; bh=JMPnBMGvgZ/FE+epN+cZJhAYFT7odaEQX02dt28/WNA=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aU0robe566yklmrM+RC37v+mxHgWgpz9H6NTdlVj3ic
 JhV5PK6o5SFQYyLQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCR2mqGv1ITv+08E6b6zGup
 oXHevOAZi44zccuInjYQWCAZUaTje5qR4YJcopmn5XzV7PcWnYeF934IjT9cyeB6Sm2FWXU0T/B
 HZgA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

indent-consistent compares every line against its nesting depth without
accounting for the constant indentation prefix used for include fragments.
It thus rejects otherwise valid fragments.

Fix that by adding the fragment prefix to the expected indentation and add
test fixtures.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 scripts/dtc/dt-check-style                            |  3 ++-
 .../dt-style-selftest/bad/dts-fragment-indent.dtsi    | 12 ++++++++++++
 .../expected/dts-fragment-indent.dtsi.txt             |  3 +++
 scripts/dtc/dt-style-selftest/good/dts-fragment.dtsi  | 19 +++++++++++++++++++
 4 files changed, 36 insertions(+), 1 deletion(-)

diff --git a/scripts/dtc/dt-check-style b/scripts/dtc/dt-check-style
index 2afc05fa6602..f867cb6d8070 100755
--- a/scripts/dtc/dt-check-style
+++ b/scripts/dtc/dt-check-style
@@ -486,6 +486,7 @@ def check_indent_consistent(ctx):
         if unit != '\t':
             return
 
+    prefix = detect_fragment_offset(ctx)
     for dl in ctx.lines:
         if dl.linetype in (LineType.BLANK, LineType.PREPROCESSOR):
             continue
@@ -498,7 +499,7 @@ def check_indent_consistent(ctx):
         # The indent must be 'unit' repeated dl.depth times, exactly.
         # NODE_CLOSE lines have depth equal to the post-decrement value,
         # which matches the indent expected.
-        expected = unit * dl.depth
+        expected = prefix + unit * dl.depth
         if dl.indent_str != expected:
             yield (dl.lineno,
                    'indent mismatch (expected depth %d * %r)' %
diff --git a/scripts/dtc/dt-style-selftest/bad/dts-fragment-indent.dtsi b/scripts/dtc/dt-style-selftest/bad/dts-fragment-indent.dtsi
new file mode 100644
index 000000000000..6d143c4dd9b2
--- /dev/null
+++ b/scripts/dtc/dt-style-selftest/bad/dts-fragment-indent.dtsi
@@ -0,0 +1,12 @@
+// SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+/* Incorrect indentation inside an indented include fragment. */
+
+	bus@10000 {
+		compatible = "simple-bus";
+		reg = <0x10000 0x1000>;
+
+		device@100 {
+				compatible = "example,test";
+				reg = <0x100 0x10>;
+		};
+	};
diff --git a/scripts/dtc/dt-style-selftest/expected/dts-fragment-indent.dtsi.txt b/scripts/dtc/dt-style-selftest/expected/dts-fragment-indent.dtsi.txt
new file mode 100644
index 000000000000..84ec8eb73468
--- /dev/null
+++ b/scripts/dtc/dt-style-selftest/expected/dts-fragment-indent.dtsi.txt
@@ -0,0 +1,3 @@
+# mode=strict
+bad/dts-fragment-indent.dtsi:9: [indent-consistent] indent mismatch (expected depth 2 * '\t')
+bad/dts-fragment-indent.dtsi:10: [indent-consistent] indent mismatch (expected depth 2 * '\t')
diff --git a/scripts/dtc/dt-style-selftest/good/dts-fragment.dtsi b/scripts/dtc/dt-style-selftest/good/dts-fragment.dtsi
new file mode 100644
index 000000000000..58735112d3aa
--- /dev/null
+++ b/scripts/dtc/dt-style-selftest/good/dts-fragment.dtsi
@@ -0,0 +1,19 @@
+// SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+/* Include fragment indented for its inclusion context. */
+
+	bus@10000 {
+		compatible = "simple-bus";
+		reg = <0x10000 0x1000>;
+		#address-cells = <1>;
+		#size-cells = <1>;
+
+		device@100 {
+			compatible = "example,test";
+			reg = <0x100 0x10>;
+		};
+	};
+
+	bus@20000 {
+		compatible = "simple-bus";
+		reg = <0x20000 0x1000>;
+	};

-- 
2.55.0

