From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 31 Jul 2025 16:59:26 -0500
Subject: [PATCH v7 3/3] PCI: tegra: Allow building as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250731-pci-tegra-module-v7-3-cad4b088b8fb@gmail.com>
References: <20250731-pci-tegra-module-v7-0-cad4b088b8fb@gmail.com>
In-Reply-To: <20250731-pci-tegra-module-v7-0-cad4b088b8fb@gmail.com>
To: Thomas Gleixner <tglx@linutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753999168; l=2994;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=NwL1zgJJcNaVJMzJ4xbw0cEqWe0gRrA6/IT+IAjXFD0=;
 b=Hx8LT+bsI6wEqRQWtMV1xj/rCHIxQHr0EGrVFgqMOAZ06cbWwoRRXKHoXQuYwJimkhWxRNDBq
 zBC82thbtqnBHEyBd9EIgxwJqnKoUfNVULsJGILBhNI5JvNIZQr8JGJ
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This changes the module macro back to builtin, which does not define an
exit function. This will prevent the module from being unloaded. There
are concerns with modules not cleaning up IRQs on unload, thus this
needs specifically disallowed. The remove callback is also dropped as it
is unused.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/pci/controller/Kconfig     |  2 +-
 drivers/pci/controller/pci-tegra.c | 35 ++++-------------------------------
 2 files changed, 5 insertions(+), 32 deletions(-)

diff --git a/drivers/pci/controller/Kconfig b/drivers/pci/controller/Kconfig
index 886f6f43a895f8f56ce3bcabbea382b6cd3b15c2..abdc17ff7b8f54c6b1cd3ee6556753f68ae546e9 100644
--- a/drivers/pci/controller/Kconfig
+++ b/drivers/pci/controller/Kconfig
@@ -225,7 +225,7 @@ config PCI_HYPERV_INTERFACE
 	  driver.
 
 config PCI_TEGRA
-	bool "NVIDIA Tegra PCIe controller"
+	tristate "NVIDIA Tegra PCIe controller"
 	depends on ARCH_TEGRA || COMPILE_TEST
 	depends on PCI_MSI
 	select IRQ_MSI_LIB
diff --git a/drivers/pci/controller/pci-tegra.c b/drivers/pci/controller/pci-tegra.c
index 467ddc701adce28c5edeb6d1b423ce56068f069a..c020822bdf0b72c4cc56817a9e689256b964e9cd 100644
--- a/drivers/pci/controller/pci-tegra.c
+++ b/drivers/pci/controller/pci-tegra.c
@@ -2546,12 +2546,6 @@ static const struct seq_operations tegra_pcie_ports_sops = {
 
 DEFINE_SEQ_ATTRIBUTE(tegra_pcie_ports);
 
-static void tegra_pcie_debugfs_exit(struct tegra_pcie *pcie)
-{
-	debugfs_remove_recursive(pcie->debugfs);
-	pcie->debugfs = NULL;
-}
-
 static void tegra_pcie_debugfs_init(struct tegra_pcie *pcie)
 {
 	pcie->debugfs = debugfs_create_dir("pcie", NULL);
@@ -2625,29 +2619,6 @@ static int tegra_pcie_probe(struct platform_device *pdev)
 	return err;
 }
 
-static void tegra_pcie_remove(struct platform_device *pdev)
-{
-	struct tegra_pcie *pcie = platform_get_drvdata(pdev);
-	struct pci_host_bridge *host = pci_host_bridge_from_priv(pcie);
-	struct tegra_pcie_port *port, *tmp;
-
-	if (IS_ENABLED(CONFIG_DEBUG_FS))
-		tegra_pcie_debugfs_exit(pcie);
-
-	pci_stop_root_bus(host->bus);
-	pci_remove_root_bus(host->bus);
-	pm_runtime_put_sync(pcie->dev);
-	pm_runtime_disable(pcie->dev);
-
-	if (IS_ENABLED(CONFIG_PCI_MSI))
-		tegra_pcie_msi_teardown(pcie);
-
-	tegra_pcie_put_resources(pcie);
-
-	list_for_each_entry_safe(port, tmp, &pcie->ports, list)
-		tegra_pcie_port_free(port);
-}
-
 static int tegra_pcie_pm_suspend(struct device *dev)
 {
 	struct tegra_pcie *pcie = dev_get_drvdata(dev);
@@ -2751,6 +2722,8 @@ static struct platform_driver tegra_pcie_driver = {
 		.pm = &tegra_pcie_pm_ops,
 	},
 	.probe = tegra_pcie_probe,
-	.remove = tegra_pcie_remove,
 };
-module_platform_driver(tegra_pcie_driver);
+builtin_platform_driver(tegra_pcie_driver);
+MODULE_AUTHOR("Thierry Reding <treding@nvidia.com>");
+MODULE_DESCRIPTION("NVIDIA PCI host controller driver");
+MODULE_LICENSE("GPL");

-- 
2.50.1

