From: Xincheng Ji <jixincheng@ultrarisc.com>
Date: Fri, 23 Oct 2026 09:56:44 +0800
Subject: [PATCH v5 4/7] dt-bindings: timer: Add UltraRISC DP1000 CLINT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-ultrarisc-dts-v5-4-af79dbd6ccec@ultrarisc.com>
References: <20261023-ultrarisc-dts-v5-0-af79dbd6ccec@ultrarisc.com>
In-Reply-To: <20261023-ultrarisc-dts-v5-0-af79dbd6ccec@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Andrew Lunn <andrew@lunn.ch>, 
 Jia Wang <wangjia@ultrarisc.com>, Xincheng Ji <jixincheng@ultrarisc.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Anup Patel <anup@brainfault.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 linux-riscv@lists.infradead.org, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792720613; l=964;
 i=jixincheng@ultrarisc.com; s=20260922; h=from:subject:message-id;
 bh=H5nCeqGhgsZIHGD5OQKUEdhmWR2MLVPLwQY1q4JBFrk=;
 b=n5uhlSypA4p4aXoYVjzvbz9AEnBnRmoj57GAOM21f/j4kSd+WxfYzE5Ju0OXSKYsrAwq4MxGo
 zxGIJLN1aEtBgDI++i/Vika4R3P2eVluElpoXF8iE+neIcBXS9vdPI1
X-Developer-Key: i=jixincheng@ultrarisc.com; a=ed25519;
 pk=n848dcS5D6g0vLad/rjp4Gf/1eedTe1a3pYUrkt2260=
X-Endpoint-Received: by B4 Relay for jixincheng@ultrarisc.com/20260922 with auth_id=1046
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Jia Wang <wangjia@ultrarisc.com>

Add compatible string for UltraRISC DP1000 CLINT.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
---
 Documentation/devicetree/bindings/timer/sifive,clint.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/timer/sifive,clint.yaml b/Documentation/devicetree/bindings/timer/sifive,clint.yaml
index 3673836e14de..878f267d089b 100644
--- a/Documentation/devicetree/bindings/timer/sifive,clint.yaml
+++ b/Documentation/devicetree/bindings/timer/sifive,clint.yaml
@@ -40,6 +40,7 @@ properties:
               - starfive,jh8100-clint   # StarFive JH8100
               - starfive,jhb100-clint   # StarFive JHB100
               - tenstorrent,blackhole-clint # Tenstorrent Blackhole
+              - ultrarisc,dp1000-clint  # UltraRISC DP1000
           - const: sifive,clint0        # SiFive CLINT v0 IP block
       - items:
           - {}

-- 
2.34.1

