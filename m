From: =?utf-8?q?Alexandra_=C3=98stermark?= <alex.cramt@gmail.com>
Date: Wed, 18 Nov 2026 20:07:13 +0100
Subject: [PATCH 1/3] arm64: dts: socfpga: agilex5: add the service layer
 interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261118-de25-nano-v1-1-473d16131f7a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795028833; l=1261;
 i=alex.cramt@gmail.com; s=20261118; h=from:subject:message-id;
 bh=481VP81WZKi/ygpfq41EOdbsewe8WlT8xUBo1hTQ0dA=;
 b=VA25FgGLIXjC3WvEziZDi4ZpKCwgpHfs9xJ7Wq5dLe0HaxyXjHjcSn3f98n6+93GhmrRyNLDB
 FNeHe6JWH5YA1tr7qZlpiEvVdV9FHu3L8OYTluGlB2sDRoFTPzmjXyi
X-Developer-Key: i=alex.cramt@gmail.com; a=ed25519;
 pk=vQBaXUvFG7cCIaWDKclPMjo3b4XfPEVkuPjaWCkYddc=
X-Endpoint-Received: by B4 Relay for alex.cramt@gmail.com/20261118 with auth_id=1561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SDM signals completion of asynchronous service layer requests on
GIC SPI 0, which the Stratix 10 and Agilex 7 device trees already wire
up, as does Altera's vendor tree for Agilex 5. Upstream's Agilex 5 svc
node lacks it, so stratix10-svc logs "Failed to get IRQ, falling back
to polling mode" and polls for every async reply.

Add the interrupt as the other SoCs do. Tested on a Terasic DE25-Nano:
the driver registers it for sip async operations, it fires
(/proc/interrupts counts it), and FPGA configuration through the FPGA
manager still works.

Signed-off-by: Alexandra Østermark <alex.cramt@gmail.com>
---
 arch/arm64/boot/dts/altera/socfpga_agilex5.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/altera/socfpga_agilex5.dtsi b/arch/arm64/boot/dts/altera/socfpga_agilex5.dtsi
index 161f3d4bb..d272cc4fd 100644
--- a/arch/arm64/boot/dts/altera/socfpga_agilex5.dtsi
+++ b/arch/arm64/boot/dts/altera/socfpga_agilex5.dtsi
@@ -84,6 +84,8 @@ svc {
 			compatible = "intel,agilex5-svc";
 			method = "smc";
 			memory-region = <&service_reserved>;
+			interrupts = <GIC_SPI 0 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-parent = <&intc>;
 			iommus = <&smmu 10>;
 
 			fpga_mgr: fpga-mgr {

-- 
2.56.0

