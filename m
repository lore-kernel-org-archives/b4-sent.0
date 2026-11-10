From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:50 +0000
Subject: [PATCH 3/5] iommu/arm-smmu-v3: enable optional clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-smmu-v3-pcie-pd-v1-3-628819ca44b9@gmail.com>
References: <20261110-smmu-v3-pcie-pd-v1-0-628819ca44b9@gmail.com>
In-Reply-To: <20261110-smmu-v3-pcie-pd-v1-0-628819ca44b9@gmail.com>
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Niklas Cassel <cassel@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-rockchip@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294708; l=1852;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=1jSKUYxMXlwd6GjaT82AOfCUOwP/umlQOFLtJr1OQVY=;
 b=NrU8nzbqEB6wQaUAemybLdDL7kdPwIu8BxlTC7zaLyd7fjp+gpXYyH0f5a1eD0GhcLxN6zqQW
 UGlU3FMVIS+CZDY6N1NEw78+vVRiw0iJPL/wm35Eu334rP7gbRSahB3
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some platforms the SMMU's clock is controlled by the OS, and without a
consumer the clock framework gates it as unused late in boot. Any later
register access, for example the CR0 write in the shutdown path, then
stalls the interconnect. This happens on the RK3588 when no PCIe
controller keeps the PCIe MMU-600 clock running.

Get and enable all clocks described in the firmware node before the
registers are first accessed, and keep them enabled while the driver is
bound. Nodes without clocks are not affected.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c b/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c
index 6d4520c47308..cce66db93219 100644
--- a/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c
+++ b/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c
@@ -12,6 +12,7 @@
 #include <linux/acpi.h>
 #include <linux/acpi_iort.h>
 #include <linux/bitops.h>
+#include <linux/clk.h>
 #include <linux/crash_dump.h>
 #include <linux/delay.h>
 #include <linux/err.h>
@@ -5786,6 +5787,7 @@ static int arm_smmu_device_probe(struct platform_device *pdev)
 	resource_size_t ioaddr;
 	struct arm_smmu_device *smmu;
 	struct device *dev = &pdev->dev;
+	struct clk_bulk_data *clks;
 
 	smmu = devm_kzalloc(dev, sizeof(*smmu), GFP_KERNEL);
 	if (!smmu)
@@ -5800,6 +5802,11 @@ static int arm_smmu_device_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
+	/* Optional clocks: keep them running for as long as we are bound */
+	ret = devm_clk_bulk_get_all_enabled(dev, &clks);
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to enable clocks\n");
+
 	smmu = arm_smmu_impl_probe(smmu);
 	if (IS_ERR(smmu))
 		return PTR_ERR(smmu);

-- 
2.55.0

