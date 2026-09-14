From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 14 Sep 2026 15:55:55 +0200
Subject: [PATCH 7/9] dt-bindings: interrupt-controller:
 thead,c900-aclint-sswi: Add MIPS P8700 gf compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-p8700-dts-v1-7-3267f14ebce1@htecgroup.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789394164; l=1111;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=WFsJFX8KbR9cAkA42pWDMyhUYcejxHY2wNhnlUtG9bs=;
 b=Y7p8yYv9zwnZFtrXTS2MrDg97xIcAaHrIiLL96HI0AQv1uDO2SVRXXJx1FZDMMtkpgsUOM0Og
 C41uzxDrVQLDtZAhRn0Vff+6OL7NlwO/Gug92lvhiUE32V0HhaDp3ec
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new compatible for the MIPS P8700 ACLINT SSWI, with the "gf"
vendor prefix. The original compatible is left as is.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 .../bindings/interrupt-controller/thead,c900-aclint-sswi.yaml          | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/thead,c900-aclint-sswi.yaml b/Documentation/devicetree/bindings/interrupt-controller/thead,c900-aclint-sswi.yaml
index d02c6886283af790d75357f77a714558f68bb7d1..6c79d7b7058a64bb39141d565f0a6304365991f2 100644
--- a/Documentation/devicetree/bindings/interrupt-controller/thead,c900-aclint-sswi.yaml
+++ b/Documentation/devicetree/bindings/interrupt-controller/thead,c900-aclint-sswi.yaml
@@ -30,6 +30,9 @@ properties:
           - const: thead,c900-aclint-sswi
       - items:
           - const: mips,p8700-aclint-sswi
+      - items:
+          - const: gf,mips-p8700-aclint-sswi
+          - const: mips,p8700-aclint-sswi
       - items:
           - enum:
               - anlogic,dr1v90-aclint-sswi

-- 
2.43.0

