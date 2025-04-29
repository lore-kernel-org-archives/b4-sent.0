From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/3] PCI: tegra: Allow building as a module
Date: Mon, 28 Apr 2025 20:05:45 -0500
Message-Id: <20250428-pci-tegra-module-v2-0-c11a4b912446@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOklEGgC/2WNQQ6CMBBFr0Jm7Zi20GBceQ/DorZDmYRS0iLRE
 O5uxaXL95P/3gaZElOGa7VBopUzx6mAOlVgBzN5QnaFQQmlRS1rnC3jQj4ZDNE9R8LWPpy0mlp
 heii3OVHPr0N57woPnJeY3kdhld/1J2uU+JetEgVaYWR/KTHdmJsPhsezjQG6fd8/5O+7HrAAA
 AA=
X-Change-ID: 20250313-pci-tegra-module-7cbd1c5e70af
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745888749; l=921;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=azkGwqj5YKIYK7EJNW3OFVdb6KdfeAoqBb9yl+/OaqA=;
 b=ZE/GiDvh1iRFBMpZV3wJ/hJ4XtBiP7ap/31NXwh8msKIu/JPbjEzCAm0yNaxzMEM7GnGBDgt0
 48lt2rC4jZJDvgW/BX2FCRLedq4JgJ1UqRcJA7H6qV6HKatawbWRQEl
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
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

 drivers/cpuidle/cpuidle-tegra.c    | 1 +
 drivers/pci/controller/Kconfig     | 2 +-
 drivers/pci/controller/pci-tegra.c | 5 ++++-
 kernel/irq/irqdomain.c             | 1 +
 4 files changed, 7 insertions(+), 2 deletions(-)
---
base-commit: 18352e73612d60b81790d2437845276ae499b64a
change-id: 20250313-pci-tegra-module-7cbd1c5e70af

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

