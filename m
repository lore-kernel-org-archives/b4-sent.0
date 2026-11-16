From: Matt Thompson <matt@boondocker.io>
Date: Mon, 16 Nov 2026 02:35:48 -0700
Subject: [PATCH RFC v3 6/6] PCI: rockchip-host: Mask the client correctable
 error interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-rfc-b4-v3-6-0bf052b68f2a@boondocker.io>
References: <20261116-rfc-b4-v3-0-0bf052b68f2a@boondocker.io>
In-Reply-To: <20261116-rfc-b4-v3-0-0bf052b68f2a@boondocker.io>
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 linux-pci@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794821744; l=1536;
 i=matt@boondocker.io; s=rk3399-rfc-20261113; h=from:subject:message-id;
 bh=ce3FAgQbXHJSx+KdqASGBJHjnYp6SNCbhPb8KwijOGQ=;
 b=Roa8HS4rvXHjevx86m6SGHzFE/Uvg8ZIdOKnCckQyQAhP/T2bbAmFPtUYp+bBt/mQYp8z/z+f
 Q3cGA20Dji+DvKbDPqSCsiGW2i2ULWqy5FZQpt8sDp0OfoYQJDvjq1k
X-Developer-Key: i=matt@boondocker.io; a=ed25519;
 pk=WMnh3kwFFRkrqamL/FbDcdl1/9rBF2uT03VdvGGP40k=
X-Endpoint-Received: by B4 Relay for matt@boondocker.io/rk3399-rfc-20261113 with auth_id=1517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On RockPro64 the PCIe client correctable-error bit stayed asserted
during link bring-up despite acknowledgment. Its level interrupt
fired at roughly one million interrupts per second on CPU 0 and
starved RCU.

Mask the controller-local notification, which the driver only uses
for a debug message. Standard PCIe AER uses root port status and its
separate interrupt.

Signed-off-by: Matt Thompson <matt@boondocker.io>
---
 drivers/pci/controller/pcie-rockchip-host.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/pcie-rockchip-host.c b/drivers/pci/controller/pcie-rockchip-host.c
index d6c494f..a8c2575 100644
--- a/drivers/pci/controller/pcie-rockchip-host.c
+++ b/drivers/pci/controller/pcie-rockchip-host.c
@@ -746,8 +746,14 @@ err_out:
 
 static void rockchip_pcie_enable_interrupts(struct rockchip_pcie *rockchip)
 {
-	rockchip_pcie_write(rockchip, (PCIE_CLIENT_INT_CLI << 16) &
-			    (~PCIE_CLIENT_INT_CLI), PCIE_CLIENT_INT_MASK);
+	/*
+	 * Leave the client correctable-error notification masked. On RK3399
+	 * it can remain asserted after acknowledgment during link bring-up
+	 * and monopolize the CPU. PCIe AER uses the root port's own status
+	 * and interrupt, which are independent of this client mask.
+	 */
+	rockchip_pcie_write(rockchip, (PCIE_CLIENT_INT_CLI << 16) |
+			    PCIE_CLIENT_INT_CORR_ERR, PCIE_CLIENT_INT_MASK);
 	rockchip_pcie_write(rockchip, (u32)(~PCIE_CORE_INT),
 			    PCIE_CORE_INT_MASK);
 

-- 
Git-155)

