From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 24 Aug 2026 13:54:20 +0800
Subject: [PATCH 07/12] dt-bindings: i2c: dw: Add compatible for UltraRISC
 DP1000 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-ultrarisc-dts-v1-7-61ab7aebe9e5@ultrarisc.com>
References: <20260824-ultrarisc-dts-v1-0-61ab7aebe9e5@ultrarisc.com>
In-Reply-To: <20260824-ultrarisc-dts-v1-0-61ab7aebe9e5@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Anup Patel <anup@brainfault.org>, Mark Brown <broonie@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Jose Abreu <joabreu@synopsys.com>, 
 Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-spi@vger.kernel.org, 
 linux-i2c@vger.kernel.org, netdev@vger.kernel.org, 
 dmaengine@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787552108; l=846;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=a3FLG1v/opm8P6Mx7tFBUWeLRZtmVFCN4Uxnx7ELy+8=;
 b=FZb78z8T9rITx8H9711DLMJwoTpitGFde0UxVr48CTWjgXqPmZIps0nVG5x8Ive0NSxtUTIag
 x3P+jfsIl4CDCgsd45dmaaxozFkO1pbWp2oQT4QQIDnp4SGSBiQMxvT
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the SoC-specific compatible string and use the generic one as fallback
for the UltraRISC DP1000 I2C controller.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 Documentation/devicetree/bindings/i2c/snps,designware-i2c.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/i2c/snps,designware-i2c.yaml b/Documentation/devicetree/bindings/i2c/snps,designware-i2c.yaml
index 467bdcbb8538..eee21ca8d7ed 100644
--- a/Documentation/devicetree/bindings/i2c/snps,designware-i2c.yaml
+++ b/Documentation/devicetree/bindings/i2c/snps,designware-i2c.yaml
@@ -44,6 +44,7 @@ properties:
               - mscc,ocelot-i2c
               - sophgo,sg2044-i2c
               - thead,th1520-i2c
+              - ultrarisc,dp1000-i2c
           - const: snps,designware-i2c
 
   reg:

-- 
2.34.1

