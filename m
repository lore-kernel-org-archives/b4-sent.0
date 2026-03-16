From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 16 Mar 2026 15:06:58 +0800
Subject: [PATCH 2/4] MAINTAINERS: Add entry for the UltraRISC DP1000 PCIe
 controller driver and its DT binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260316-ultrarisc-pcie-v1-2-ef2946ede698@ultrarisc.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773644922; l=906;
 i=wangjia@ultrarisc.com; s=20260309; h=from:subject:message-id;
 bh=S1wEZ7Qj4tYv0/nzKH9ecqpxkAyEAumj1u8QGL/LCmU=;
 b=k/OPXKc2hLilx+CL/XIe0/HcMf/WLkYIYOEZy5X0GAoCsCpp4g45Z9IQUE+FuAcOVj9/a46Nf
 v3UeZVX3eQtBa2SMl83GV0u3ThurTyk1um3TSrmBIRlCVuVe5p+3ZmN
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=XvYkrelqJIIzobY7j+nIg8rsfv5kzaOzuc1UPhd087U=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260309 with auth_id=682
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a MAINTAINERS entry for the UltraRISC DP1000 PCIe host driver and its
DT binding.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 96ea84948d76..5caa383fe0ec 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -20571,6 +20571,14 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/pci/starfive,jh7110-pcie.yaml
 F:	drivers/pci/controller/plda/pcie-starfive.c
 
+PCIE DRIVER FOR ULTRARISC DP1000
+M:	Xincheng Zhang <zhangxincheng@ultrarisc.com>
+M:	Jia Wang <wangjia@ultrarisc.com>
+L:	linux-pci@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/pci/ultrarisc,dp1000-pcie.yaml
+F:	drivers/pci/controller/dwc/pcie-ultrarisc.c
+
 PCIE ENDPOINT DRIVER FOR QUALCOMM
 M:	Manivannan Sadhasivam <mani@kernel.org>
 L:	linux-pci@vger.kernel.org

-- 
2.34.1

