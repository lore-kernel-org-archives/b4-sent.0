From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] PCI: tegra: Allow building as a module
Date: Sun, 20 Apr 2025 21:59:04 -0500
Message-Id: <20250420-pci-tegra-module-v1-0-c0a1f831354a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHm0BWgC/x3MQQqAIBBA0avIrBvQIoSuEi1MJxsoFa0IorsnL
 d/i/wcKZaYCg3gg08WFY6hQjQC7muAJ2VVDK9tedqrDZBkP8tngHt25EWo7O2V70tIsULOUaeH
 7X47T+35omWfOYgAAAA==
X-Change-ID: 20250313-pci-tegra-module-7cbd1c5e70af
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745204358; l=521;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=R9f74YRgz6IRKppd90adUHI/amHmTouOI9UziGWcAyg=;
 b=oPIZvsec7gz9+Yjz6nVopaeusWi4sC2rXNfF4YLwe/3YlkRuaGmDo7ET7bXC2NEttI69zAzRs
 ro2SrwYOeDHD0FsEymlQ4goP2h5ZazxAB3qsPNxnwaNkAzz3HSFg+CA
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (2):
      irqdomain: Export irq_domain_free_irqs
      PCI: tegra: Allow building as a module

 drivers/pci/controller/Kconfig     | 2 +-
 drivers/pci/controller/pci-tegra.c | 3 +++
 kernel/irq/irqdomain.c             | 1 +
 3 files changed, 5 insertions(+), 1 deletion(-)
---
base-commit: e3a854b577cb05ceb77c0eba54bfef98a03278fa
change-id: 20250313-pci-tegra-module-7cbd1c5e70af

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

