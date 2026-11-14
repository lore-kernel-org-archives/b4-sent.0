From: Igor Velkov <iav@iav.lv>
Subject: [PATCH 0/2] PCI: meson: Add system suspend/resume support
Date: Sat, 14 Nov 2026 22:12:57 +0000
Message-Id: <20261114-b4-pci-meson-suspend-v1-0-be3d04a13304@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOnc+GoC/x3MPQqAMAxA4atIZgO2+FevIg61Rs1gLQ2KULy7x
 fEb3ksgFJkEhiJBpJuFT5+hygLcbv1GyEs26Eq3Sqka5xqDYzxITo9ySSC/oK4609tuNqZpIac
 h0srPvx2n9/0ANe3ZJGYAAAA=
To: Yue Wang <yue.wang@Amlogic.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pci@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1569; i=iav@iav.lv;
 h=from:subject:message-id; bh=WDRaiZdaKfWEl03glQcVn0OXt/DJd9CPRnnp+NTL/5A=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFk/7rxZufzRhJb192SkltcdWJYU2THlgliwe4DGbp7jB
 8wDkxeGdJSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJqFYzMsyucdxqUKj5M+3y
 2bsLl6Ud+el8J6iud4/v0mWiF8tU779m+Gd0g6cyZrKVi8deMcXNF+4YnjU6vlWTafdV55PPxN5
 /escFAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SM1 the PCIe controller loses power in system suspend and the driver
has no PM callbacks, so the first config access after resume hangs the
CPU; on ODROID-HC4 s2idle never returns.

Patch 1 moves the PHY power on and the resets into the host .init and
.deinit callbacks.  Patch 2 adds noirq suspend/resume through the DWC
helpers, for SM1 only.

Tested on ODROID-HC4 (SM1, ASM1061 SATA with two disks behind the port)
on an Armbian v7.4-rc2 kernel with this series, which also carries
Hans Zhang's pending MPS series (v9): 20 s2idle and 20 suspend-to-RAM
cycles, the link back at Gen2 x1 and the disk readable after each.
Suspend-to-RAM woke on the VRTC alarm via a patched BL301; the stock
firmware has no timer wake on this board.

Not tested on G12A, G12B or AXG.  There patch 1 changes probe and
remove, and patch 2 leaves suspend alone.

After a failed resume, dw_pcie_suspend_noirq() calls .deinit a second
time; pci-imx6 and pcie-rcar-gen4 have no guard against it.  Patch 2
guards with a flag; I can fix it in the DWC core instead if preferred.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Igor Velkov (2):
      PCI: meson: Power the PHY on and reset the controller in host .init
      PCI: meson: Add system suspend/resume support

 drivers/pci/controller/dwc/pci-meson.c | 108 +++++++++++++++++++++++++++------
 1 file changed, 89 insertions(+), 19 deletions(-)
---
base-commit: 35f800669ce835aa77364a2ab5b61be19b778d3c
change-id: 20261114-b4-pci-meson-suspend-20798a7b9956

Best regards,
-- 
Igor Velkov <iav@iav.lv>

