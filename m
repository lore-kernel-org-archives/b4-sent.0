From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Wed, 25 Jun 2025 16:21:00 +0200
Subject: [PATCH v4 5/7] riscv: hwprobe: Document MIPS xmipsexectl vendor
 extension
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250625-p8700-pause-v4-5-6c7dd7f85756@htecgroup.com>
References: <20250625-p8700-pause-v4-0-6c7dd7f85756@htecgroup.com>
In-Reply-To: <20250625-p8700-pause-v4-0-6c7dd7f85756@htecgroup.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Jonathan Corbet <corbet@lwn.net>
Cc: Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750861258; l=1433;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=ONKDrupJVIvTuOPl4HYtUjJG9+vS9PioyKkmG/eBvIA=;
 b=lB3maqHxBHGl1G03VPK/N0rQBhStz3QP5CAL+JiHBDDtytrfEuPLDlOiUTcZ54+Wunt80Dc/n
 VTN80isflIeA6/Zvx9uUZq8VhatdJ0LTU1vbFSaPLzkjJx/eqQBSufN
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document support for MIPS vendor extensions using the key
"RISCV_HWPROBE_KEY_VENDOR_EXT_MIPS_0" and xmipsexectl vendor extension
using the key "RISCV_HWPROBE_VENDOR_EXT_XMIPSEXECTL".

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 Documentation/arch/riscv/hwprobe.rst | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/arch/riscv/hwprobe.rst b/Documentation/arch/riscv/hwprobe.rst
index 2aa9be272d5de1c15559a978a956bc36c34de81c..2f449c9b15bdd6b9813c9a968deca1a4c4ff9b14 100644
--- a/Documentation/arch/riscv/hwprobe.rst
+++ b/Documentation/arch/riscv/hwprobe.rst
@@ -327,6 +327,15 @@ The following keys are defined:
   * :c:macro:`RISCV_HWPROBE_MISALIGNED_VECTOR_UNSUPPORTED`: Misaligned vector accesses are
     not supported at all and will generate a misaligned address fault.
 
+* :c:macro:`RISCV_HWPROBE_KEY_VENDOR_EXT_MIPS_0`: A bitmask containing the
+  mips vendor extensions that are compatible with the
+  :c:macro:`RISCV_HWPROBE_BASE_BEHAVIOR_IMA`: base system behavior.
+
+  * MIPS
+
+    * :c:macro:`RISCV_HWPROBE_VENDOR_EXT_XMIPSEXECTL`: The xmipsexectl vendor
+        extension is supported in the MIPS ISA extensions spec.
+
 * :c:macro:`RISCV_HWPROBE_KEY_VENDOR_EXT_THEAD_0`: A bitmask containing the
   thead vendor extensions that are compatible with the
   :c:macro:`RISCV_HWPROBE_BASE_BEHAVIOR_IMA`: base system behavior.

-- 
2.34.1

