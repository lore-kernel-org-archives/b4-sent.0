From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 05 May 2025 18:17:21 -0500
Subject: [PATCH v5 2/3] cpuidle: tegra: Export
 tegra_cpuidle_pcie_irqs_in_use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250505-pci-tegra-module-v5-2-827aaac998ba@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746487040; l=805;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=VxJ9HgkNV4IxH20jYpaAA9e5Ei6kk4ytu1PVu0wpNxM=;
 b=z0W8d1Q64bfmqnl3a4wP5TKAH7EjzkwLbmJxq1UHI5FFF3Kx7RAK2oAK5+8b1qLQQ4rTygQlv
 XNqsbCcZzfqDKnx2o3KR3tU5gQmKhc8Zoqq3x8faYHwniL8tcdYJ7O4
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add export for tegra_cpuidle_pcie_irqs_in_use() so that drivers like
pci-tegra can be loaded as a module.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/cpuidle/cpuidle-tegra.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/cpuidle/cpuidle-tegra.c b/drivers/cpuidle/cpuidle-tegra.c
index b203a93deac5f378572be90e22c73e7417adb99e..aca907a62bb5de4ee4c71c1900eacedd4b90bc0a 100644
--- a/drivers/cpuidle/cpuidle-tegra.c
+++ b/drivers/cpuidle/cpuidle-tegra.c
@@ -336,6 +336,7 @@ void tegra_cpuidle_pcie_irqs_in_use(void)
 	pr_info("disabling CC6 state, since PCIe IRQs are in use\n");
 	tegra_cpuidle_disable_state(TEGRA_CC6);
 }
+EXPORT_SYMBOL_GPL(tegra_cpuidle_pcie_irqs_in_use);
 
 static void tegra_cpuidle_setup_tegra114_c7_state(void)
 {

-- 
2.48.1

