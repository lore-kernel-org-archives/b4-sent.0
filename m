From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 05 May 2025 09:59:01 -0500
Subject: [PATCH v4 4/4] PCI: tegra: Drop unused remove callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250505-pci-tegra-module-v4-4-088b552c4b1a@gmail.com>
References: <20250505-pci-tegra-module-v4-0-088b552c4b1a@gmail.com>
In-Reply-To: <20250505-pci-tegra-module-v4-0-088b552c4b1a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746457141; l=1781;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=miAFNHWEF9RJxGC8gWXehC/2+WRlc/Ou80W+mmEfiFc=;
 b=VxWydBojj4iW1Ijuwovo5IQ9vqX/in+EsYY0WDnypg5xmW4Q2g9vI9d6lUykgCKAtRdZU7OCn
 +owjcHXA2DgCy/zWR1931CqjgR748RFtWhmGo3BmB4Rs668bnJne/OA
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Debugfs cleanup is moved to a new shutdown callback to ensure the
debugfs nodes are properly cleaned up on shutdown and reboot.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/pci/controller/pci-tegra.c | 19 ++-----------------
 1 file changed, 2 insertions(+), 17 deletions(-)

diff --git a/drivers/pci/controller/pci-tegra.c b/drivers/pci/controller/pci-tegra.c
index 1539d172d708c11c3d085721ab9416be3dea6b12..cc9ca4305ea2072b7395ee1f1e979c24fdea3433 100644
--- a/drivers/pci/controller/pci-tegra.c
+++ b/drivers/pci/controller/pci-tegra.c
@@ -2674,27 +2674,12 @@ static int tegra_pcie_probe(struct platform_device *pdev)
 	return err;
 }
 
-static void tegra_pcie_remove(struct platform_device *pdev)
+static void tegra_pcie_shutdown(struct platform_device *pdev)
 {
 	struct tegra_pcie *pcie = platform_get_drvdata(pdev);
-	struct pci_host_bridge *host = pci_host_bridge_from_priv(pcie);
-	struct tegra_pcie_port *port, *tmp;
 
 	if (IS_ENABLED(CONFIG_DEBUG_FS))
 		tegra_pcie_debugfs_exit(pcie);
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
 }
 
 static int tegra_pcie_pm_suspend(struct device *dev)
@@ -2800,7 +2785,7 @@ static struct platform_driver tegra_pcie_driver = {
 		.pm = &tegra_pcie_pm_ops,
 	},
 	.probe = tegra_pcie_probe,
-	.remove = tegra_pcie_remove,
+	.shutdown = tegra_pcie_shutdown,
 };
 builtin_platform_driver(tegra_pcie_driver);
 MODULE_AUTHOR("Thierry Reding <treding@nvidia.com>");

-- 
2.48.1

