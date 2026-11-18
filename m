From: =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
Date: Wed, 18 Nov 2026 20:07:14 +0100
Subject: [PATCH 2/3] dt-bindings: arm: altera: add Terasic DE25-Nano
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261118-de25-nano-v1-2-473d16131f7a@gmail.com>
References: <20261118-de25-nano-v1-0-473d16131f7a@gmail.com>
In-Reply-To: <20261118-de25-nano-v1-0-473d16131f7a@gmail.com>
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Mahesh Rao <mahesh.rao@altera.com>, 
 Mohamad Asyraaf Azhar <mohamad.asyraaf.azhar@altera.com>, 
 =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795028833; l=924;
 i=alex.cramt@gmail.com; s=20261118; h=from:subject:message-id;
 bh=q+ynkvnX0dWnC9dNQRmhhqyaPWV3G/Ese9y4dmoLVu8=;
 b=5n2X0zcxAsj5ooWW6SMw304IiTNsQdgp3JXMjiLvZrnhb21CGSlO2AeBnelg1ZIwpFrtGL8P8
 hjLpjpqX1xSA/YUZZwlwXN75kwiDD0sR4O5IGPfJAHyjQj+iOfzpcWh
X-Developer-Key: i=alex.cramt@gmail.com; a=ed25519;
 pk=vQBaXUvFG7cCIaWDKclPMjo3b4XfPEVkuPjaWCkYddc=
X-Endpoint-Received: by B4 Relay for alex.cramt@gmail.com/20261118 with auth_id=1561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Terasic DE25-Nano is a development board built around the Agilex 5
A5EB013BB23B SoC FPGA, with 1 GiB of HPS DDR4, a microSD slot, a gigabit
Ethernet port and USB.

Signed-off-by: Alexandra Østermark <alex.cramt@gmail.com>
---
 Documentation/devicetree/bindings/arm/altera.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/altera.yaml b/Documentation/devicetree/bindings/arm/altera.yaml
index ae38ba0dc..75f874e8b 100644
--- a/Documentation/devicetree/bindings/arm/altera.yaml
+++ b/Documentation/devicetree/bindings/arm/altera.yaml
@@ -118,6 +118,7 @@ properties:
               - intel,socfpga-agilex5-socdk-modular
               - intel,socfpga-agilex5-socdk-nand
               - intel,socfpga-agilex5-socdk-tsn-cfg2
+              - terasic,de25-nano
           - const: intel,socfpga-agilex5
 
       - description: Agilex72 boards

-- 
2.56.0

