From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v4 0/4] PCI: tegra: Allow building as a module
Date: Mon, 05 May 2025 09:58:57 -0500
Message-Id: <20250505-pci-tegra-module-v4-0-088b552c4b1a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADHSGGgC/23NTQ6CMBRG0a2Qjq3pLwVH7sM4KG2BJkBJi42Gs
 HcLDiTK8L7knW8GwXhrArhkM/Am2mDdkIKdMqBaOTQGWp0aEEQ4opjCUVk4mcZL2Dv96AwUqtJ
 YcSOQrEF6G72p7XMjb/fUrQ2T869tIeL1+sEYQf9YxBBBhSSuizTGmbw2vbTdWbkerFgke6A4A
 MgKYCxZVWLCWP4L0C/AETkAaAI4zyUrBSVaoD2wLMsbQH+4AjIBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746457141; l=1327;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=HnQHwXod2wutRRoHv2wgXPVJV7pOW/ivP71cpImY1i4=;
 b=/3JyDtE7aHyipMrD8Ry8sTJ7wN5U14qjqgqGMloBCJNHtRtCyeXCnybsSN8Wx5CJfndayNX5H
 WoU+oOZShmJDpcV2sYryLPabyII2xUyxKebLTZAkaEhGg1ILTVcemQu
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
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
Aaron Kling (4):
      irqdomain: Export irq_domain_free_irqs
      cpuidle: tegra: Export tegra_cpuidle_pcie_irqs_in_use
      PCI: tegra: Allow building as a module
      PCI: tegra: Drop unused remove callback

 drivers/cpuidle/cpuidle-tegra.c    |  1 +
 drivers/pci/controller/Kconfig     |  2 +-
 drivers/pci/controller/pci-tegra.c | 24 ++++++------------------
 kernel/irq/irqdomain.c             |  1 +
 4 files changed, 9 insertions(+), 19 deletions(-)
---
base-commit: 18352e73612d60b81790d2437845276ae499b64a
change-id: 20250313-pci-tegra-module-7cbd1c5e70af

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

