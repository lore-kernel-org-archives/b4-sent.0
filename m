From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 14 Sep 2026 15:55:49 +0200
Subject: [PATCH 1/9] dt-bindings: vendor-prefixes: Add GlobalFoundries,
 Inc.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-p8700-dts-v1-1-3267f14ebce1@htecgroup.com>
References: <20260914-p8700-dts-v1-0-3267f14ebce1@htecgroup.com>
In-Reply-To: <20260914-p8700-dts-v1-0-3267f14ebce1@htecgroup.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Anup Patel <anup@brainfault.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Inochi Amaoto <inochiama@outlook.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Conor Dooley <conor@kernel.org>, linux-riscv@lists.infradead.org, 
 Vladimir Kondratiev <vladimir.kondratiev@mobileye.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789394164; l=1295;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=kuKqE2k4y4LDyGnqtj3oO0/ZCuqCwkmJo6BCsnZGNKc=;
 b=hjpmDgpH5H6bTV89dWm4yNI88HSAplU0zTEId7wlyzbd/VMhq6uaQ2u8yUUYzc40tf7c4Kz0y
 xXEvOYrF6nDBw1qeZSmCkjFYHQl3ej6nBvKpLPIsSUETgROHWybFrtr
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GlobalFoundries acquired MIPS. All MIPS RISC-V
compatibles should be labeled with the 'gf' prefix in the future.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index ba2002969373433b1f48118872c46cf7bcfff276..b699935f60b96b3cfbb9c6e8ce802fcbedc52c1b 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -668,6 +668,8 @@ patternProperties:
     description: Genexis BV/AB
   "^geniatech,.*":
     description: Geniatech, Inc.
+  "^gf,.*":
+    description: GlobalFoundries, Inc.
   "^giantec,.*":
     description: Giantec Semiconductor, Inc.
   "^giantplus,.*":
@@ -1104,7 +1106,7 @@ patternProperties:
   "^minix,.*":
     description: MINIX Technology Ltd.
   "^mips,.*":
-    description: MIPS Technology (deprecated, use 'mti' or 'img')
+    description: MIPS Technology (deprecated, use 'mti', 'img', or 'gf')
     deprecated: true
   "^miramems,.*":
     description: MiraMEMS Sensing Technology Co., Ltd.

-- 
2.43.0

