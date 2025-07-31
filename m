From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v7 0/3] PCI: tegra: Allow building as a module
Date: Thu, 31 Jul 2025 16:59:23 -0500
Message-Id: <20250731-pci-tegra-module-v7-0-cad4b088b8fb@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADzni2gC/4XPQWrDMBAF0KsErasijTSSnFXvUboYy2NHEMdBT
 k1L8N0rp4ua2NDlH5j3+Xcxck48iuPhLjJPaUzDpQT/chDxRJeOZWpKFqAAldFGXmOSN+4yyX5
 oPs8sfawbHZG9olaUt2vmNn09yPePkk9pvA35+9Ew6eX6i1lQW2zSUsmoSLehlKGlt66ndH6NQ
 y8WbII1EHYAWACtydaVBmvdM2D+AFSwA5gCIDqylTfQePUM2DWAO4AtgAqhRoRoa72ZgP8BWIA
 AnohiVYV6A7g14HcAt0xo2TjDREbBGpjn+QcAOCpn9QEAAA==
X-Change-ID: 20250313-pci-tegra-module-7cbd1c5e70af
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753999168; l=1947;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=VTivWzBig8qO+f9kiueL0YgCcL2cFIHpCmHWMnbJp1Q=;
 b=KNtTCfJzfNcIdkIiqUNgC5pYjwVCbgCsyt3Nc1YILP491nrjHJS8VDoZD1RNGygiRZ8ix5rcj
 FUGA10pVnL9Dn+gVPl0fIO2uAY6mXjMAnv18S5+kITIONZ8ck7l9fQl
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v7:
- Rebased on 6.16
- Updated mailing address list
- Link to v6: https://lore.kernel.org/r/20250507-pci-tegra-module-v6-0-5fe363eaa302@gmail.com

Changes in v6:
- Remove unused debugfs cleanup function, as caught by kernel ci
- Link to v5: https://lore.kernel.org/r/20250505-pci-tegra-module-v5-0-827aaac998ba@gmail.com

Changes in v5:
- Copy commit message exactly word for word on patch 1, as required by reviewer
- Delete remove callback in patch 3, per request
- Don't clean up debugfs, per request, which drops patch 4 entirely
- Link to v4: https://lore.kernel.org/r/20250505-pci-tegra-module-v4-0-088b552c4b1a@gmail.com

Changes in v4:
- Updated commit messages for patches 1 and 2, per review
- Link to v3: https://lore.kernel.org/r/20250502-pci-tegra-module-v3-0-556a49732d70@gmail.com

Changes in v3:
- Add patch to drop remove callback, per request
- Link to v2: https://lore.kernel.org/r/20250428-pci-tegra-module-v2-0-c11a4b912446@gmail.com

Changes in v2:
- Add patch to export tegra_cpuidle_pcie_irqs_in_use as required when
  building pci-tegra as a module for arm
- Drop module exit to prevent module unloading, as requested
- Link to v1: https://lore.kernel.org/r/20250420-pci-tegra-module-v1-0-c0a1f831354a@gmail.com

---
Aaron Kling (3):
      irqdomain: Export irq_domain_free_irqs
      cpuidle: tegra: Export tegra_cpuidle_pcie_irqs_in_use
      PCI: tegra: Allow building as a module

 drivers/cpuidle/cpuidle-tegra.c    |  1 +
 drivers/pci/controller/Kconfig     |  2 +-
 drivers/pci/controller/pci-tegra.c | 35 ++++-------------------------------
 kernel/irq/irqdomain.c             |  1 +
 4 files changed, 7 insertions(+), 32 deletions(-)
---
base-commit: 038d61fd642278bab63ee8ef722c50d10ab01e8f
change-id: 20250313-pci-tegra-module-7cbd1c5e70af

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

