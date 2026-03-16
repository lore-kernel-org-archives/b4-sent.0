From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 16 Mar 2026 15:06:57 +0800
Subject: [PATCH 1/4] riscv: add UltraRISC SoC family Kconfig support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260316-ultrarisc-pcie-v1-1-ef2946ede698@ultrarisc.com>
References: <20260316-ultrarisc-pcie-v1-0-ef2946ede698@ultrarisc.com>
In-Reply-To: <20260316-ultrarisc-pcie-v1-0-ef2946ede698@ultrarisc.com>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Jingoo Han <jingoohan1@gmail.com>, 
 Xincheng Zhang <zhangxincheng@ultrarisc.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773644922; l=955;
 i=wangjia@ultrarisc.com; s=20260309; h=from:subject:message-id;
 bh=yTvCixoepaOP7H0g0NOlrwpugZtb4VLtAcECC0j8Mq8=;
 b=1g5NIQahZ7vZ6VjqyuGZB5s/gvegIH0PTVHfuyaBYDlH54vV/CScnL3pV3MVIlvRbTwOEuJA4
 ZPs04vuYuvzDhlUXRSp9XodapVXofPuuHk1D5doYu+D+/fmXQnoX+Nu
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=XvYkrelqJIIzobY7j+nIg8rsfv5kzaOzuc1UPhd087U=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260309 with auth_id=682
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The first SoC in the UltraRISC series is UR-DP1000, containing octa
UltraRISC C100 cores.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 arch/riscv/Kconfig.socs | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/riscv/Kconfig.socs b/arch/riscv/Kconfig.socs
index d621b85dd63b..f49d3ccaacde 100644
--- a/arch/riscv/Kconfig.socs
+++ b/arch/riscv/Kconfig.socs
@@ -84,6 +84,16 @@ config ARCH_THEAD
 	help
 	  This enables support for the RISC-V based T-HEAD SoCs.
 
+config ARCH_ULTRARISC
+	bool "UltraRISC RISC-V SoCs"
+	depends on MMU && !XIP_KERNEL
+	help
+	 This enables support for UltraRISC SoC platform hardware,
+	 including boards based on the UR-DP1000.
+	 UR-DP1000 is an 8-core 64-bit RISC-V SoC that supports
+	 the RV64GCBHX ISA. It supports Hardware Virtualization
+	 and RISC-V RV64 ISA H(v1.0) Extension.
+
 config ARCH_VIRT
 	bool "QEMU Virt Machine"
 	select POWER_RESET

-- 
2.34.1

