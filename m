From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 05 May 2025 18:17:22 -0500
Subject: [PATCH v5 3/3] PCI: tegra: Allow building as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250505-pci-tegra-module-v5-3-827aaac998ba@gmail.com>
References: <20250505-pci-tegra-module-v5-0-827aaac998ba@gmail.com>
In-Reply-To: <20250505-pci-tegra-module-v5-0-827aaac998ba@gmail.com>
To: Thomas Gleixner <tglx@linutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>
Cc: linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746487040; l=2578;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=HNeyxqklHxYO1Z7cAeod50HxFJLbvD8WnX339dtMaiA=;
 b=fo9TtaSwgnvyZQgGNVox7gBbbZWS5P86hTXhr9PHEDbnBO0nSk1f8JZRc8ZwDeCXX1jrsBORI
 FOCgV6oimC2AAeHSEiboaqMaI+z8Y0mbfnKQSpAIzD3iAmgfdCdhCMD
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
 drivers/pci/controller/pci-tegra.c | 29 ++++-------------------------
 2 files changed, 5 insertions(+), 26 deletions(-)

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
index b3cdbc5927de3742161310610dc5dcb836f5dd69..e2d976c126817808933ca936cf650088157283be 100644
--- a/drivers/pci/controller/pci-tegra.c
+++ b/drivers/pci/controller/pci-tegra.c
@@ -2674,29 +2674,6 @@ static int tegra_pcie_probe(struct platform_device *pdev)
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
@@ -2800,6 +2777,8 @@ static struct platform_driver tegra_pcie_driver = {
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
2.48.1

