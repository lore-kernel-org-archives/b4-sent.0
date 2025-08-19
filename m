From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/6] PCI/pwrctrl: Allow pwrctrl framework to control PERST#
 if available
Date: Tue, 19 Aug 2025 12:44:49 +0530
Message-Id: <20250819-pci-pwrctrl-perst-v1-0-4b74978d2007@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGkkpGgC/x3MTQqAIBBA4avErBsw6Ue6SrRInWogSsaoQLp70
 vJbvJcgkjBF6IsEQhdHPvaMqizArdO+ELLPBq10o0xlMDjGcIs7ZcNAEk9U1nbet9o2tYbcBaG
 Zn/85jO/7ASO6EjdjAAAA
X-Change-ID: 20250818-pci-pwrctrl-perst-0bb7dd62b542
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Saravana Kannan <saravanak@google.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Brian Norris <briannorris@chromium.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6045;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=DUGjIzup/j2PvfhRPAmCy7WU+mBbxRH0A12zCGf2srI=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBopCRr+Z9IFzf6VURGYwhjL+hVNGlOnRTrnlTPV
 hQj2pbZmPqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaKQkawAKCRBVnxHm/pHO
 9Yv1CACg2aNkaU3Tf/1+qZPJSMEPmpakEUkwKuYlFdOrjCl7G3ddlH+VxMbG/6bQ8XBvthn4sYI
 4frNColgu72noLqbfHbiw44NAVzHjDh+WfxULVUrRe8CjrtdmUwjrR71YEWFKJqLjsW6a2LMKY/
 tnkQPtv73EtxRhkQi6Cry79Gfgj/mZQyY/NBM63tLd5JFDOdXlBStNPe0Gbhrr//z1lc4mo97fb
 ZHY6zJ9PZgvtvBwv44P+2LSm3r7x82VphIPbocrRscT07mPHrpRLUkElwxGnwWbrz5f8zNamrm+
 wAwsMdcyJCpenDDHSh9yxRc+KCyvGxX0+I0OquE+v2Id30zJ
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series is the proper version for toggling PERST# from the pwrctrl
framework after the initial RFC posted earlier [1].

Problem statement
=================

Pwrctrl framework is intented to control the supplies to the components on the
PCI bus. However, if the platform supports the PERST# signal, it should be
toggled as per the requirements in the electromechanical specifications like
PCIe CEM, Mini, and M.2. Since the pwrctrl framework is controlling the power
supplies, it should also toggle PERST# as per the requirements in the above
mentioned specifications. Right now, it is just controlling the power to the
components and rely on controller drivers to toggle PERST#, which goes against
the specs. For instance, controller drivers will deassert PERST# even before the
pwrctrl driver enables the supplies. This causes the device to see PERST#
deassert immediately after power on, thereby violating the delay requirements in
the electromechanical specs.

Proposal
========

To fix this issue, the pwrctrl framework has to control the PERST# signal. But
unfortunately, it is not straightforward. This is mostly due to controller
drivers still need to assert PERST# as a part of their own initialization
sequence. The controller drivers will parse PERST# from the devicetree nodes
even before the pwrctrl drivers get probed. So the PERST# control needs to be
shared between both drivers in a logical manner.

This is achieved by adding a new callback, 'pci_host_bridge::toggle_perst'. This
callback if available, will be called by the pwrctrl framework during the power
on and power off scenarios. The callback implementation in the controller driver
has to take care of asserting/deasserting PERST# in an implementation specific
way i.e., if the PERST# signal is a GPIO, then it should be toggled using gpiod
APIs, or if the signal is implemented as a CSR, then the relevant registers
should be written.

Ideally, the PERST# delay requirements should be implemented in the pwrctrl
framework (before/after calling the callback), but some controller drivers
perform some post-link_up operations requiring them to control the delay within
the driver. Those drivers may use this callback to assert/deassert PERST# and
perform post-link_up operations.

For reference, I've implemented the callback in the Qcom RC driver where it just
toggles PERST# and implements the delay as per the CEM spec (which seem to
satisfy the delay requirements of other electromechanical specs also). Since the
Qcom driver supports both legacy DT binding (all Root Port properties in host
bridge node) and new binding (Root Port properies in Root Port node), I've moved
the PERST# handling to pwrctrl driver only if new binding is used. A recently
merged patch to PCI tree [2] makes sure that the pwrctrl slot driver is selected
with the RC driver.

DT binding requirement
======================

This series has some assumptions on the DT binding. But some of them are not
enforced right now:

1. Pwrctrl driver requires the PCIe device node to have atleast one -supply
property. Those supplies are already documented in the dtschema [3], but they
are optional. So if those supplies are not present, pwrctrl driver will not get
probed. For platforms having a fixed power supply to the endpoint, they should
describe those fixed supplies in DT. Otherwise, they cannot use pwrctrl drivers.
(NOT ENFROCED)

2. Optional PERST# GPIO (reset-gpios property) is only allowed in the bridge
node in the DT binding [4]. So for looking up the PERST# for an endpoint node,
the controller driver has to look up the parent node where PERST# would be
available. (ENFORCED)

3. If shared PERST# is implemented, all the bridge nodes (Root port and switch
downstream) should have the same 'reset-gpios' property. This way, the
controller drivers parsing PERST# could know if it is shared and invoke relevant
gpiod APIs/flags. (NOT ENFORCED)

I don't know how we can make sure DT binding enforces option 1 and 3.

Testing
=======

This series is tested on Qcom X1E based T14s laptop, SM8250 based RB5 board, and
QCS6490 based RB3Gen2 board with both legacy and new DT binding.

[1] https://lore.kernel.org/linux-pci/20250707-pci-pwrctrl-perst-v1-0-c3c7e513e312@kernel.org/
[2] https://lore.kernel.org/linux-pci/20250722091151.1423332-2-quic_wenbyao@quicinc.com/
[3] https://github.com/devicetree-org/dt-schema/blob/main/dtschema/schemas/pci/pci-bus-common.yaml#L173
[4] https://github.com/devicetree-org/dt-schema/blob/main/dtschema/schemas/pci/pci-bus-common.yaml#L141

Changes since RFC:

* Implemented PERST# toggling using a callback since GPIO based PERST# is not
  available on all platforms. This also moves all PERST# handling to the
  controller drivers allowing them to add any additional post-link_up logic.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (6):
      PCI: qcom: Wait for PCIE_RESET_CONFIG_WAIT_MS after PERST# deassert
      PCI/pwrctrl: Move pci_pwrctrl_init() before turning ON the supplies
      PCI/pwrctrl: Add support for toggling PERST#
      PCI: of: Add an API to get the BDF for the device node
      PCI: qcom: Parse PERST# from all PCIe bridge nodes
      PCI: qcom: Allow pwrctrl core to toggle PERST# for new DT binding

 drivers/pci/controller/dwc/pcie-qcom.c   | 166 +++++++++++++++++++++++++------
 drivers/pci/of.c                         |  21 ++++
 drivers/pci/pwrctrl/core.c               |  27 +++++
 drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c |   4 +-
 drivers/pci/pwrctrl/slot.c               |   4 +-
 include/linux/of_pci.h                   |   6 ++
 include/linux/pci.h                      |   1 +
 7 files changed, 197 insertions(+), 32 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250818-pci-pwrctrl-perst-0bb7dd62b542

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

