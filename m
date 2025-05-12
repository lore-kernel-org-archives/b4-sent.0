From: Mahesh Rao <mahesh.rao@altera.com>
Date: Mon, 12 May 2025 19:39:55 +0800
Subject: [PATCH v2 5/7] dts: agilex: Add support for SDM mailbox interrupt
 for Intel Agilex SoC FPGA.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250512-sip_svc_upstream-v2-5-fae5c45c059d@altera.com>
References: <20250512-sip_svc_upstream-v2-0-fae5c45c059d@altera.com>
In-Reply-To: <20250512-sip_svc_upstream-v2-0-fae5c45c059d@altera.com>
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mahesh Rao <mahesh.rao@altera.com>
Cc: Matthew Gerlach <matthew.gerlach@altera.com>, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747050016; l=956;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=Qju5FftDEBjY7mgDWEHoQiNo3ptWBPQcrDs6T4v7xUo=;
 b=tIZE59Rukq2QBCrIeK7LfK3lKt7SYYhFKwjXcF+tOwJCIBXcw3OngRIjBfC6PU8lTMMRunoIL
 XzzSGvaxmCrCPoTIqsiDJmS9uP3n6+1vtiozYOiBF4EG3kVq1XWYF9K
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
index 1235ba5a9865a175001fd3ef2bad710842f93be4..bd8c386a2ee31b85d6ee9be2dff6176565a85077 100644
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

