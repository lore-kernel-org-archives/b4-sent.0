From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v2 0/3] PCI: Add PTM sysfs support
Date: Mon, 24 Mar 2025 15:34:34 +0530
Message-Id: <20250324-pcie-ptm-v2-0-c7d8c3644b4a@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADIu4WcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDI1MDYyMT3YLkzFTdgpJc3VRz0yTLJKO0tOS0JCWg8oKi1LTMCrBR0bG1tQA
 JftiHWgAAAA==
X-Change-ID: 20250324-pcie-ptm-e75b9b2ffcfb
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Jingoo Han <jingoohan1@gmail.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3419;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=2YzndqjPYZtO24UsGSXBDXw/XTK3KIe4lsm6degtopA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBn4S4zvOHOf5c9xVh0GG6JM1Q9A3czgGvOAcZbH
 S1Ll0Aw/ayJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ+EuMwAKCRBVnxHm/pHO
 9cwzB/9uiEOi3CSoNq8pYCiP8oeJJZE5yK15c3WbCVKN52oQujU/KsAh4Aqw0g15hasr5dOkz1j
 DlAaorGqvHxOj7EB4acC4GNGPyHQv13RijpGfEUhWhLDYJsBA/Dps25pZKO/VAbwC83VzseWeuU
 F9+psruO5YtMS5H20UbDTv1nGOjghyXZHW4U++7NnXOSleWZHUiGCX4hF+AICSoQ0GDmVwqufhE
 gZajFxJ4RtrRAf8gTqI4KWKVRx443jYZpVS7ROm+HiBpMSOd1deS2ASGWujXkKrzuDXBE5mPeNg
 /1IqpLwe7+8cTpqWRVVZj4CPQ+8cTQIlhxAvy2SoqQPqHRNw
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds sysfs support to expose the PTM context available in the
capable PCIe controllers. Support for enabling PTM in the requester/responder is
already available in drivers/pci/pcie/ptm.c and this series expands that file to
add sysfs support for the PTM context info.

The controller drivers are expected to call pcie_ptm_create_sysfs() with
'pcie_ptm_ops' callbacks populated to create the sysfs entries and call
pcie_ptm_destroy_sysfs() to destroy them.

Patch 1 adds the necessary code in the drivers/pci/pcie/ptm.c to expose PTM
context over sysfs and patch 2 adds PTM support in the DWC drivers (host and
endpoint). Finally, patch 3 masks the PTM_UPDATING interrupt in the pcie-qcom-ep
driver to avoid processing the interrupt for each PTM context update.

Testing
=======

This series is tested on Qcom SA8775p Ride Mx platform where one SA8775p acts as
RC and another as EP with following instructions:

RC
--

$ echo 1 > /sys/devices/platform/1c10000.pcie/ptm/context_valid

EP
--

$ echo auto > /sys/devices/platform/1c10000.pcie-ep/ptm/context_update

$ cat /sys/devices/platform/1c10000.pcie-ep/ptm/local_clock
159612570424

$ cat /sys/devices/platform/1c10000.pcie-ep/ptm/master_clock
159609466232

$ cat /sys/devices/platform/1c10000.pcie-ep/ptm/t1
159609466112

$ cat /sys/devices/platform/1c10000.pcie-ep/ptm/t4
159609466518

NOTE: To make use of the PTM feature, the host PCIe client driver has to call
'pci_enable_ptm()' API during probe. This series was tested with enabling PTM in
the MHI host driver with a local change (which will be upstreamed later).
Technically, PTM could also be enabled in the pci_endpoint_test driver, but I
didn't add the change as I'm not sure we'd want to add random PCIe features in
the test driver without corresponding code in pci-epf-test driver.

Changes in v2:

* Dropped the VSEC changes that got merged
* Moved the PTM sysfs code from drivers/pci/controller/dwc to
  drivers/pci/pcie/ptm to make it generic so that other controller drivers could
  also benefit from it.
* Rebased on top of pci/controller/dwc

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (3):
      PCI: Add sysfs support for exposing PTM context
      PCI: dwc: Add sysfs support for PTM context
      PCI: qcom-ep: Mask PTM_UPDATING interrupt

 Documentation/ABI/testing/sysfs-platform-pcie-ptm  |  70 ++++++
 MAINTAINERS                                        |   1 +
 drivers/pci/controller/dwc/Makefile                |   2 +-
 drivers/pci/controller/dwc/pcie-designware-ep.c    |   3 +
 drivers/pci/controller/dwc/pcie-designware-host.c  |   3 +
 drivers/pci/controller/dwc/pcie-designware-sysfs.c | 254 +++++++++++++++++++
 drivers/pci/controller/dwc/pcie-designware.c       |   6 +
 drivers/pci/controller/dwc/pcie-designware.h       |  21 ++
 drivers/pci/controller/dwc/pcie-qcom-ep.c          |   8 +
 drivers/pci/pcie/ptm.c                             | 268 +++++++++++++++++++++
 include/linux/pci.h                                |  35 +++
 include/linux/pcie-dwc.h                           |   8 +
 12 files changed, 678 insertions(+), 1 deletion(-)
---
base-commit: 1f5a69f1b3132054d8d82b8d7546d0af6a2ed4f6
change-id: 20250324-pcie-ptm-e75b9b2ffcfb

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

