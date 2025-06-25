From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Wed, 25 Jun 2025 16:20:56 +0200
Subject: [PATCH v4 1/7] dt-bindings: riscv: Add xmipsexectl ISA extension
 description
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250625-p8700-pause-v4-1-6c7dd7f85756@htecgroup.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750861257; l=1302;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=h13o/f46vhfOxj3D4iHSUN8apIuhKjiCZWPiTgA7Dm8=;
 b=bybQmtA8JYGfk8SiLTuOilDEXK5tT9xmFca05oXB0CyhBAtjNDrFXIGgHUHKdAijZXjcbV3p1
 JgyhwV4egd+C8PDaz7ap5wnXKVTad51WO59WymZenWRomONPsWUPyfr
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The xmipsexectl extension is described in the MIPS RV64 P8700/P8700-F
Multiprocessing System Programmer’s Guide linked at [1].

Link: https://mips.com/wp-content/uploads/2025/06/P8700_Programmers_Reference_Manual_Rev1.84_5-31-2025.pdf

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 Documentation/devicetree/bindings/riscv/extensions.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/riscv/extensions.yaml b/Documentation/devicetree/bindings/riscv/extensions.yaml
index ede6a58ccf5347d92785dc085a011052c1aade14..de41a6f074d3af2ceaf5293dfe75d16f43d416d6 100644
--- a/Documentation/devicetree/bindings/riscv/extensions.yaml
+++ b/Documentation/devicetree/bindings/riscv/extensions.yaml
@@ -662,6 +662,12 @@ properties:
             Registers in the AX45MP datasheet.
             https://www.andestech.com/wp-content/uploads/AX45MP-1C-Rev.-5.0.0-Datasheet.pdf
 
+        # MIPS
+        - const: xmipsexectl
+          description:
+            The MIPS extension for execution control as documented in
+            https://mips.com/wp-content/uploads/2025/06/P8700_Programmers_Reference_Manual_Rev1.84_5-31-2025.pdf
+
         # SiFive
         - const: xsfvqmaccdod
           description:

-- 
2.34.1

