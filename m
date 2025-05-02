From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 02 May 2025 14:00:31 -0500
Subject: [PATCH v3 3/4] PCI: tegra: Allow building as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250502-pci-tegra-module-v3-3-556a49732d70@gmail.com>
References: <20250502-pci-tegra-module-v3-0-556a49732d70@gmail.com>
In-Reply-To: <20250502-pci-tegra-module-v3-0-556a49732d70@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746212443; l=1592;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=ediBwXdejZJpog3kftYSmvTQosQLVWrtV7PiuRz9nKw=;
 b=fyglllN1LQYdTPKsWYdjPwSOuvVIV4KKD8qg16D+m+tf7wg1uxixsLEoVSt6kfqC6bVH7RkdF
 eJc4roXh56OA3OSFyYtJtmoQOpNwkVRFxpGPXAYe5fmMsQgBaDCXRUv
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This changes the module macro back to builtin, which does not define an
exit function. This will prevent the module from being unloaded. There
are concerns with modules not cleaning up IRQs on unload, thus this
needs specifically disallowed.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/pci/controller/Kconfig     | 2 +-
 drivers/pci/controller/pci-tegra.c | 5 ++++-
 2 files changed, 5 insertions(+), 2 deletions(-)

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
index b3cdbc5927de3742161310610dc5dcb836f5dd69..1539d172d708c11c3d085721ab9416be3dea6b12 100644
--- a/drivers/pci/controller/pci-tegra.c
+++ b/drivers/pci/controller/pci-tegra.c
@@ -2802,4 +2802,7 @@ static struct platform_driver tegra_pcie_driver = {
 	.probe = tegra_pcie_probe,
 	.remove = tegra_pcie_remove,
 };
-module_platform_driver(tegra_pcie_driver);
+builtin_platform_driver(tegra_pcie_driver);
+MODULE_AUTHOR("Thierry Reding <treding@nvidia.com>");
+MODULE_DESCRIPTION("NVIDIA PCI host controller driver");
+MODULE_LICENSE("GPL");

-- 
2.48.1

