From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 22 Jul 2026 10:42:46 +0200
Subject: [PATCH RFC 1/2] dt-bindings: regmap: add common schema for
 no-sequential-read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-regmap-single-read-v1-1-aaaf31591669@linux.dev>
References: <20260722-regmap-single-read-v1-0-aaaf31591669@linux.dev>
In-Reply-To: <20260722-regmap-single-read-v1-0-aaaf31591669@linux.dev>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Alexander Stein <alexander.stein@ew.tq-group.com>, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 driver-core@lists.linux.dev, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784709824; l=1961;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=II7rqJ8vAH0MCpVujV5WTZLZYW7Z+swXHrvYP22m8bM=;
 b=hRG5jhYvYw0e42JCiJ9i03gLnYgCrKFWKO8iOB/MeSkF+h2EUj9fuZB/HRjVFN7ti/CQRjO8k
 rwuU3Nw3KHdAF+GTKBcgkPyHnBNacebkXLnrRLIflFuKLxzogFFvl+o
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a common regmap dt-binding schema with an optional boolean
property no-sequential-read to describe hardware integrations where
reading multiple consecutive registers in a single operation is not
reliable and registers must be read individually.

A typical case are imaging sensors used on vendor-provided camera
modules whose bus integration does not support reads that advance across
consecutive register addresses. In such cases, single-register reads
work, but bulk reads do not. This restriction is a property of the
concrete hardware integration, not of the chip itself. It therefore
cannot be identified from the device driver and duplicating firmware
parsing in each affected driver does not scale.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 .../devicetree/bindings/regmap/common.yaml         | 26 ++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/Documentation/devicetree/bindings/regmap/common.yaml b/Documentation/devicetree/bindings/regmap/common.yaml
new file mode 100644
index 0000000000000..1d713bc3217da
--- /dev/null
+++ b/Documentation/devicetree/bindings/regmap/common.yaml
@@ -0,0 +1,26 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/regmap/common.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Common register access constraints
+
+maintainers:
+  - TBD
+
+description:
+  Common properties describing register access constraints.
+
+properties:
+  no-sequential-read:
+    type: boolean
+    description:
+      Indicates that this device instance does not support sequential
+      register reads.
+
+      Reads may start at a given register address, but reading multiple
+      consecutive registers in a single operation is not reliable.
+      Software must instead read registers individually.
+
+additionalProperties: true

-- 
2.53.0

