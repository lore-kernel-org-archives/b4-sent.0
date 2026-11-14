From: Matt Thompson <matt@boondocker.io>
Date: Fri, 13 Nov 2026 17:52:19 -0700
Subject: [PATCH RFC v2 1/3] PCI: rockchip-host: Skip downstream config
 access while link is down
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-rfc-b4-v2-1-d6b14f95c1d6@boondocker.io>
References: <20261113-rfc-b4-v2-0-d6b14f95c1d6@boondocker.io>
In-Reply-To: <20261113-rfc-b4-v2-0-d6b14f95c1d6@boondocker.io>
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 linux-pci@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794617540; l=2087;
 i=matt@boondocker.io; s=rk3399-rfc-20261113; h=from:subject:message-id;
 bh=dQmkjngK0wLJ2jAFS1PjdlLb7zJkoCy2sJ8WeTsPps4=;
 b=9/6wJ4fyi0li8ktfa0g1y80t+yToemwpZHRpl1FuuUR8wL8NcQvQf5YZ4ISCzVYGGfIX4Nbbp
 60UfS2buuMTDRX0VvcUOUgovZRSmUUdjXveUqPlOyYx8G0qNHPWZfLK
X-Developer-Key: i=matt@boondocker.io; a=ed25519;
 pk=WMnh3kwFFRkrqamL/FbDcdl1/9rBF2uT03VdvGGP40k=
X-Endpoint-Received: by B4 Relay for matt@boondocker.io/rk3399-rfc-20261113 with auth_id=1517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a RockPro64, a PCI bus rescan with the downstream FPGA unavailable
faulted in rockchip_pcie_rd_conf() during a vendor ID read. The rescan
task exited with interrupts disabled and the watchdog reported a lockup.

Check the controller's link-up and link-training status before issuing
downstream config requests. Return PCIBIOS_DEVICE_NOT_FOUND while the
link is unavailable. Root port config access still uses the local
controller registers.

This check cannot prevent the link from dropping during the transaction.

Signed-off-by: Matt Thompson <matt@boondocker.io>
---
 drivers/pci/controller/pcie-rockchip-host.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/pci/controller/pcie-rockchip-host.c b/drivers/pci/controller/pcie-rockchip-host.c
index 5b071bd..35105c1 100644
--- a/drivers/pci/controller/pcie-rockchip-host.c
+++ b/drivers/pci/controller/pcie-rockchip-host.c
@@ -143,12 +143,23 @@ static int rockchip_pcie_wr_own_conf(struct rockchip_pcie *rockchip,
 	return PCIBIOS_SUCCESSFUL;
 }
 
+static bool rockchip_pcie_downstream_ready(struct rockchip_pcie *rockchip)
+{
+	return PCIE_LINK_UP(rockchip_pcie_read(rockchip, PCIE_CLIENT_BASIC_STATUS1)) &&
+	       PCIE_LINK_TRAINING_DONE(rockchip_pcie_read(rockchip, PCIE_CORE_CTRL));
+}
+
 static int rockchip_pcie_rd_other_conf(struct rockchip_pcie *rockchip,
 				       struct pci_bus *bus, u32 devfn,
 				       int where, int size, u32 *val)
 {
 	void __iomem *addr;
 
+	if (!rockchip_pcie_downstream_ready(rockchip)) {
+		*val = ~0U;
+		return PCIBIOS_DEVICE_NOT_FOUND;
+	}
+
 	addr = rockchip->reg_base + PCIE_ECAM_OFFSET(bus->number, devfn, where);
 
 	if (!IS_ALIGNED((uintptr_t)addr, size)) {
@@ -182,6 +193,9 @@ static int rockchip_pcie_wr_other_conf(struct rockchip_pcie *rockchip,
 {
 	void __iomem *addr;
 
+	if (!rockchip_pcie_downstream_ready(rockchip))
+		return PCIBIOS_DEVICE_NOT_FOUND;
+
 	addr = rockchip->reg_base + PCIE_ECAM_OFFSET(bus->number, devfn, where);
 
 	if (!IS_ALIGNED((uintptr_t)addr, size))

-- 
Git-155)

