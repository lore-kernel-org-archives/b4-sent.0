From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 0/2] PCI: {qcom-ep/tegra194}: Move endpoint cleanups to
 PERST# deassert handler
Date: Sat, 17 Aug 2024 11:09:02 +0530
Message-Id: <20240817-pci-qcom-ep-cleanup-v1-0-d6b958226559@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHY3wGYC/x3MQQqAIBBA0avErBtQMZSuEi1CpxooNaUIorsnL
 d/i/wcKZaYCffNAposLx1Ah2wbcOoWFkH01KKG0sNJgcoyHiztSQrfRFM6ERgujO1LSWwO1TJl
 mvv/rML7vB4Z5YAFlAAAA
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Vidya Sagar <vidyas@nvidia.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Thierry Reding <treding@nvidia.com>, 
 linux-tegra@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1346;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=L/27oyOVLbdmCNH9AknEU1c/3ghg8UF/LJ6ONoZ4cx4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmwDd5oSWJNpFaLg/slHpFuZZnWAOUt1u//hPmY
 mKDHR5xbhuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZsA3eQAKCRBVnxHm/pHO
 9d1sB/0WCIUlcJV87RKQ5qCtkHnD2ovZLEYil0rw3RCSmWyK//H4Tzkm9kMpbjxaISonGlWLOnm
 ThYAn02ruelSxvKg7TJOHjpRgtJ6CzXGfSammhX3XpzUgTL3ABNUpUgInAS60cHyyp4J3w4bzp3
 L+FWiGeX2mRVyt34Q1P7NgAiH8v2PGGYamFooJOYWTodSNEObHGoKZlZvrgaR9KrO9ODIox6Qm7
 zfSPmFIoKAO3uqB8ZNjkCGl2OcB26VQA7fKpr/LTqJo/82aU84DvZaqFa2/0r2mvHdiLrZdMOp2
 fMm/7p9QsGr5f3u2IhcFpTtLrxHqijs42qulAHGwT7e6B21a
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series moves the call to endpoint cleanup functions (dw_pcie_ep_cleanup()
pci_epc_deinit_notify()) to PERST# deassert handler in qcom-ep and tegra194
drivers. It aims to fix a crash that is seen with Qcom endpoint SoCs when host
asserts PERST# and the cleanup functions are called without refclk.

During the review of v1 [1], Bjorn suggested fixing up tegra194 driver as well
as both drivers share the same design and require refclk from host for
operation.

Testing
=======

The Qcom patch is tested on SM8450 development board. For tegra194, I'm
expecting someone in the Cc list or the community will do the testing.

[1] https://lore.kernel.org/linux-pci/20240815224717.GA53536@bhelgaas/

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (2):
      PCI: qcom-ep: Move controller cleanups to qcom_pcie_perst_deassert()
      PCI: tegra194: Move controller cleanups to pex_ep_event_pex_rst_deassert()

 drivers/pci/controller/dwc/pcie-qcom-ep.c  | 6 ++++--
 drivers/pci/controller/dwc/pcie-tegra194.c | 7 ++++---
 2 files changed, 8 insertions(+), 5 deletions(-)
---
base-commit: 8400291e289ee6b2bf9779ff1c83a291501f017b
change-id: 20240817-pci-qcom-ep-cleanup-740745e21d87

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

