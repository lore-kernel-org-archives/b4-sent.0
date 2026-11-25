From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/4] PCI: qcom: Recalibrate the PHY on temperature drift
Date: Wed, 25 Nov 2026 11:17:40 +0100
Message-Id: <20261125-glymur-thermal-fix-v1-0-b93a9feae156@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMS1BmsC/yXM3QpAQBCG4VvRHJvaXUW5FTlYazDy1ywiuXeLw
 +er773AkzB5yKMLhHb2PE8BOo7AdXZqCbkOBqNMqpVOsB3OcRNcO5LRDtjwgTprapdYZbPUQDg
 uQmH+okX5229VT259S3DfDzAArdl2AAAA
X-Change-ID: 20261013-glymur-thermal-fix-17fdc3a0a762
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2723;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=HgrmnZrPJ03VUOGr7acN3x0L+JRf71NfChjXIGvBIFI=;
 b=owEBbAGT/pANAwAKAVWfEeb+kc71AcsmYgBrBrXJN0nx0VuywW13Z9P5yu8BfPQgfO99OfSiF
 NpXFGodvkaJATIEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCawa1yQAKCRBVnxHm/pHO
 9Y3KB/i2GophMZJQXPNfRUIqmFp7Af4cCz0vRGPONdERPpK8uIZobxvZyQ55b86iy2gt4z7Wrlh
 PpQQCgB3OnFqVkd3uC3IVbsMUC73LjQMWrcBWuoh8L6Fs8+CTWJxyadQR8JJhQEPBg8FuN62FRm
 KWeoWjWA2DkDymTW5d0MqpnmYofjpHBRzk1BwnIL3jizZfApARfb7sgZNBwK/zv8FJ2eWSciaMh
 rt4FTGVf57sYWGLdhWLQ/fOUAh9RBYyHQszHolrm0R+2iNcXn9RcFSZ3T/uA1waJvkpzqEAxwuL
 EcYzRdUIAal2GHmHSaaqCrvYcCXgtMiJOhq0brfJWnWX9wU=
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Problem Statement
=================

Some PCIe PHY instances on SoCs like Glymur benefit from periodic
recalibration to compensate for temperature-related drift and maintain
stable link operation. Otherwise there is a potential for a link drop.

The PHY gets calibrated when the link trains and it cannot recalibrate
itself while the link is up, so the recalibration has to be driven by
software.

Proposal
========

The PCIe controller driver triggers the recalibration with a PCIe link
speed switch once the temperature change on a polled sensor exceeds the
defined threshold. For this purpose, the driver needs to know which
sensors track the PHY temperature and the drift temperature. Both of them
vary per platform, so they come from DT.

Once a zone has drifted far enough, the driver performs the link speed
switching by scaling down the Target Link Speed to 2.5 GT/s and then
restoring the original Target Link Speed. This forces the link to run
Equalization again, which recalibrates the PHY against the current
temperature, thereby maintaining stable link operation. Equalization only
runs on a speed change to 8.0 GT/s or above.

Patch 1 adds a lookup from a DT node to its thermal zone, which the driver
needs for resolving the phandles it is handed. Patch 2 adds the new DT
binding property to specify the tuples of thermal zones and their drift
temperature. Patch 3 adds support for reading those zones on an interval
and recalibrating the PHY once one of them has drifted far enough.

Finally, patch 4 wires up the two Glymur PCIe controllers that use this,
pointing each one at the sensor that tracks the temperature of the PHY it
feeds.

Testing
=======

Tested on the Glymur CRD, on the two controllers patch 4 describes.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (4):
      thermal/of: Add thermal_zone_get_zone_by_node() API
      dt-bindings: PCI: qcom,pcie-x1e80100: Add qcom,pcie-recalibration-thermal-zones
      PCI: qcom: Recalibrate the PHY on temperature drift
      arm64: dts: qcom: glymur: Describe the PCIe thermal inputs

 .../bindings/pci/qcom,pcie-x1e80100.yaml           |  31 +++
 arch/arm64/boot/dts/qcom/glymur.dtsi               |   4 +
 drivers/pci/controller/dwc/pcie-qcom.c             | 224 +++++++++++++++++++++
 drivers/thermal/thermal_of.c                       |  21 ++
 include/linux/thermal.h                            |   8 +
 5 files changed, 288 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261013-glymur-thermal-fix-17fdc3a0a762

Best regards,
--  
மணிவண்ணன் சதாசிவம்

