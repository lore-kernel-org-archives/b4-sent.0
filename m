From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/6] PCI/pwrctrl: tc9563: Several fixes and improvements
Date: Sat, 25 Jul 2026 10:59:12 +0200
Message-Id: <20260725-tc9563-fix-v1-0-ec4286e31331@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOF6ZGoC/yXMQQ5AMBCF4avIrDXRQYWriIXWYCxK2hKJuLti+
 b3k/Rd4ckwemuQCRwd7Xm2ETBMwc28nEjxEA2aosgpLEUxdqlyMfApVkK6M1hKxhnjYHMX5i7X
 db7/rhUx4C3DfD2Zcx8xuAAAA
X-Change-ID: 20260725-tc9563-fix-64eb7cbb1229
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alex Elder <elder@riscstar.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1352;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=31NjIQUTeWZLc6fEIFAJVTJ8DcSVltuYCnuiJreAzYM=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqZHr1zcV4JoKB7ZAz2UA4gLrLm9guZhHRTAzpT
 eaWDbd56eqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCamR69QAKCRBVnxHm/pHO
 9ZX3B/4nGwuzQaqqcm7w4n38qxllmFOlJvMCfWYo81HL2K2T2Yfmp5Kw7O5OH3Fm56MtsUgmQh+
 qsuRdYFQwuMmWsByL38GwABeFTgCq3pRXBN8H3TBlMbNDhCmDLDm/8GYVTJ2U9/JWGgA22rZWV0
 xSpbYjnPELIM6MkIUmxIebwrLyXGkwGv9VUNWv96okH/fPzZ/gcuH9txAnQDOrP0mhCZ8bnqdft
 vueLCccD7FQzE0Ep+3JuTVD8ubaNV/prAgxYX2Y8B74pbCDrF39DqytRNefNseFjO84yWn3r+zG
 8PSh95Jm20S9vIfvnzrjPaDhUm5tdW7fSMzB0mT0C2CHXTFM
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series contains several fixes and improvements for the TC9563 Pwrctrl
driver and the switch binding. Most of the fixes are related to ensuring
correctness in parsing the DT properties for the switch ports and the
integrated Endpoint.

More details are in the individual patches.

Testing
=======

This series was validated on the RB3Gen2 board.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (6):
      dt-bindings: PCI: toshiba,tc9563: Restrict Tx Amplitude, DFE and N_FTS to USP, DSP1 and DSP2
      PCI/pwrctrl: tc9563: Fix parsing the integrated Ethernet MAC Endpoint node
      PCI/pwrctrl: tc9563: Power off only the external ports in tc9563_pwrctrl_disable_port()
      PCI/pwrctrl: tc9563: Skip Tx amplitude and DFE tuning for DSP3
      PCI/pwrctrl: tc9563: Rename DSP3 to VDSP
      PCI/pwrctrl: tc9563: Move Integrated MAC Endpoint out of 'tc9563_pwrctrl_ports' enum

 .../devicetree/bindings/pci/toshiba,tc9563.yaml    |  21 +++-
 drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c           | 129 ++++++++++++++-------
 2 files changed, 104 insertions(+), 46 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260725-tc9563-fix-64eb7cbb1229

Best regards,
--  
மணிவண்ணன் சதாசிவம்

