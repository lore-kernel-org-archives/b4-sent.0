From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 09 Jul 2025 19:05:53 +0800
Subject: [PATCH v2 2/9] dt-bindings: mips: loongson: Add CQ-T300B board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250709-loongson1-arch-v2-2-bcff6e518c09@gmail.com>
References: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
In-Reply-To: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752059245; l=783;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=4UnKtWWBR/lKpvKPk/u0S68OurozbQkpD8iTBCm47UM=;
 b=0pK1mnfNtYwyiRNlPdI32qFp3B/GCl0CfXWiOwNNBujCg0mBx/EkdOymfczQuooGj3BdtCMYS
 9VSlPCMTXYkA67DBa7so5SQscm/QjiIH4yuulnZgP3qK2emqh8pvaki
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document loongson,cq-t300b, a board based on Loongson-1C.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 Documentation/devicetree/bindings/mips/loongson/devices.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/mips/loongson/devices.yaml b/Documentation/devicetree/bindings/mips/loongson/devices.yaml
index 8736eb9fe224..4532b774c0eb 100644
--- a/Documentation/devicetree/bindings/mips/loongson/devices.yaml
+++ b/Documentation/devicetree/bindings/mips/loongson/devices.yaml
@@ -47,6 +47,7 @@ properties:
       - description: LS1C based boards
         items:
           - enum:
+              - loongson,cq-t300b
               - loongmasses,smartloong-1c
           - const: loongson,ls1c
 

-- 
2.43.0

