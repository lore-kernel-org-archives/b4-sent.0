From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Apr 2025 21:59:06 -0500
Subject: [PATCH 2/2] PCI: tegra: Allow building as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250420-pci-tegra-module-v1-2-c0a1f831354a@gmail.com>
References: <20250420-pci-tegra-module-v1-0-c0a1f831354a@gmail.com>
In-Reply-To: <20250420-pci-tegra-module-v1-0-c0a1f831354a@gmail.com>
To: Thomas Gleixner <tglx@linutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745204358; l=1330;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=wWrPTvwS8jQlrXtSz5cnnPOard6fs6fh1GhK5NDgNmg=;
 b=8J8tPTGbIDW4YOXuDJAJ/wlyLdpEM1EeTtjZPwF65RK2+uyH0nkKpYQvXP6gbatkV/CONBrRA
 n9uf9hDTxFRBjxFEMCiBqcQbyS1MaVzFb2dT8x3MNUniublfOF/gMAi
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver works fine as a module, so allow building as such.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/pci/controller/Kconfig     | 2 +-
 drivers/pci/controller/pci-tegra.c | 3 +++
 2 files changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/controller/Kconfig b/drivers/pci/controller/Kconfig
index 9800b768105402d6dd1ba4b134c2ec23da6e4201..a9164dd2eccaead5ae9348c24a5ad75fcb40f507 100644
--- a/drivers/pci/controller/Kconfig
+++ b/drivers/pci/controller/Kconfig
@@ -224,7 +224,7 @@ config PCI_HYPERV_INTERFACE
 	  driver.
 
 config PCI_TEGRA
-	bool "NVIDIA Tegra PCIe controller"
+	tristate "NVIDIA Tegra PCIe controller"
 	depends on ARCH_TEGRA || COMPILE_TEST
 	depends on PCI_MSI
 	help
diff --git a/drivers/pci/controller/pci-tegra.c b/drivers/pci/controller/pci-tegra.c
index b3cdbc5927de3742161310610dc5dcb836f5dd69..c260842695f2e983ae48fd52b43f62dbb9fb5dd3 100644
--- a/drivers/pci/controller/pci-tegra.c
+++ b/drivers/pci/controller/pci-tegra.c
@@ -2803,3 +2803,6 @@ static struct platform_driver tegra_pcie_driver = {
 	.remove = tegra_pcie_remove,
 };
 module_platform_driver(tegra_pcie_driver);
+MODULE_AUTHOR("Thierry Reding <treding@nvidia.com>");
+MODULE_DESCRIPTION("NVIDIA PCI host controller driver");
+MODULE_LICENSE("GPL");

-- 
2.48.1

