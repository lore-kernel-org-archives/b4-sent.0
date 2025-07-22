From: Mahesh Rao <mahesh.rao@altera.com>
Date: Tue, 22 Jul 2025 23:07:53 +0800
Subject: [PATCH 3/4] dts: agilex: Add support for SDM mailbox interrupt for
 Intel Agilex SoC FPGA.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250722-sip_svc_irq-v1-3-c5b9e02c1ce6@altera.com>
References: <20250722-sip_svc_irq-v1-0-c5b9e02c1ce6@altera.com>
In-Reply-To: <20250722-sip_svc_irq-v1-0-c5b9e02c1ce6@altera.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dinh Nguyen <dinguyen@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mahesh Rao <mahesh.rao@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753196946; l=956;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=qLJL9E6mhNOyiVfHw+nPeNLWSX7L0xd4wCMDiWauGyc=;
 b=/SOzXqFsdQWRhSBWMsOdPguNNREu4BpMpU0pOPlTo/z4UC7X6csZ8iqTWM3n7hlD9s/Z7OJ9U
 jbIwpDeNskRB25CJIa4GWmTD93kqEWlXkMleN2foxsrzTR8hVcdXL8o
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Secure Device Manager (SDM) mailbox
doorbell interrupt on Agilex SoC FPGA for supporting
asynchronous transactions.

Signed-off-by: Mahesh Rao <mahesh.rao@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
---
 arch/arm64/boot/dts/intel/socfpga_agilex.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/intel/socfpga_agilex.dtsi b/arch/arm64/boot/dts/intel/socfpga_agilex.dtsi
index a77a504effeab6b487ea0ef4c733f3ed80cad5be..436de1bb18d7a561c169595ad50d54d8120fdd35 100644
--- a/arch/arm64/boot/dts/intel/socfpga_agilex.dtsi
+++ b/arch/arm64/boot/dts/intel/socfpga_agilex.dtsi
@@ -65,6 +65,8 @@ svc {
 			compatible = "intel,agilex-svc";
 			method = "smc";
 			memory-region = <&service_reserved>;
+			interrupts = <GIC_SPI 0 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-parent = <&intc>;
 
 			fpga_mgr: fpga-mgr {
 				compatible = "intel,agilex-soc-fpga-mgr";

-- 
2.35.3

