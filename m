From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v6 0/9] Add support for handling PCIe M.2 Key E connectors
 in devicetree
Date: Tue, 17 Mar 2026 09:59:50 +0530
Message-Id: <20260317-pci-m2-e-v6-0-9c898f108d3d@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL7YuGkC/3XRTW7DIBAF4KtErIsFw49NVrlH1QWGcYNUxwk4V
 qsod+84UVUW8Qbpofme0HBjBXPCwva7G8u4pJKmEwX7tmPh6E+fyFOkzECAkVICP4fER+DInbb
 O+OCiNS2j8XPGIX0/qt4/KB9Tmaf882he5Hr7omSRXHDXaqmi7YcO9GEqpblc/VeYxrGhg61dC
 1QeTOWBvIIObETRhmA2vPrzVkgpKq/I68EjtlFE43HD69rX79fkcRg6HSHYCHbDm38PoCtvyMf
 oemeEjEqFF/7+XG7Gy5W+Z35umPW+IF+H0rzfLW0jeA6Shu+/EK+ivNMBAAA=
X-Change-ID: 20251112-pci-m2-e-94695ac9d657
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, 
 "Derek J. Clark" <derekjohn.clark@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-acpi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Hans de Goede <johannes.goede@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5685;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=+nWU70vOvVE7Unqqi6GMuwj93rd1qTWGf37/M1rd6dU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpuNjDrZP8t3iBpZf3IMrj0qPihBo+aMxTpsaJm
 0pPLa5+DS2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCabjYwwAKCRBVnxHm/pHO
 9dF2B/4hd7olKPISxCTRFxQo3nMkhiKvO9H1Gepl7vYYkI4xtavPQmwsoRc3pDwJL1jn0XdTk49
 UuoxiwlaajrBdQ56bc8a3BQEX07wfofLg1H0frt7afiOAS3jWZp7er0zyBRg5Oom70iRE4CbwEe
 cibZhm67h28jJXAd8cRnBghFpQ+ij29OGeAp0VaL6wv+EhRQ0Rt+wdiC3Q+Fs0C0XFPHfw1GOrn
 JgBpM2tQD5OZwpDPsrbP+JNJHw4nv3azpzough2ZsM5zwyjif8Bn7OdXRpul+/ip0Zm6k1tJeUm
 YvnEJtk1VndptlLQae03uBwUtMSf1x2sH/kJXygk6UJAmPbc
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series is the continuation of the series [1] that added the initial support
for the PCIe M.2 connectors. This series extends it by adding support for Key E
connectors. These connectors are used to connect the Wireless Connectivity
devices such as WiFi, BT, NFC and GNSS devices to the host machine over
interfaces such as PCIe/SDIO, USB/UART and NFC. This series adds support for
connectors that expose PCIe interface for WiFi and UART interface for BT. Other
interfaces are left for future improvements.

Serdev device support for BT
============================

Adding support for the PCIe interface was mostly straightforward and a lot
similar to the previous Key M connector. But adding UART interface has proved to
be tricky. This is mostly because of the fact UART is a non-discoverable bus,
unlike PCIe which is discoverable. So this series relied on the PCI notifier to
create the serdev device for UART/BT. This means the PCIe interface will be
brought up first and after the PCIe device enumeration, the serdev device will
be created by the pwrseq driver. This logic is necessary since the connector
driver and DT node don't describe the device, but just the connector. So to make
the connector interface Plug and Play, the connector driver uses the PCIe device
ID to identify the card and creates the serdev device. This logic could be
extended in the future to support more M.2 cards. Even if the M.2 card uses SDIO
interface for connecting WLAN, a SDIO notifier could be added to create the
serdev device.

Testing
=======

This series, together with the devicetree changes [2] was tested on the
Qualcomm X1e based Lenovo Thinkpad T14s Laptop which has the WCN7850 WLAN/BT
1620 LGA card connected over PCIe and UART.

Merge Strategy
==============

Due to the API dependency, both the serdev and pwrseq patches need to go through
a single tree, maybe through pwrseq tree. So the serdev patches need Ack from
Greg. But Bluetooth patch can be merged separately.

[1] https://lore.kernel.org/linux-pci/20260107-pci-m2-v5-0-8173d8a72641@oss.qualcomm.com
[2] https://github.com/Mani-Sadhasivam/linux/commit/b50f8386900990eed3dce8d91c3b643fb0e8739d

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v6:
- Added a check to bail out if the serdev device was already added during notifier.
- Collected tags
- Link to v5: https://lore.kernel.org/r/20260224-pci-m2-e-v5-0-dd9b9501d33c@oss.qualcomm.com

Changes in v5:
- Incorporated comments in the binding patch by using single endpoint per port,
  reordering port nodes, adding missing properties and using a complete example.
- Incorporated comments in the pwrseq patch (nothing major)
- Fixed the build issue in patch 2
- Collected tags
- Rebased on top of 7.0-rc1
- Link to v4: https://lore.kernel.org/r/20260112-pci-m2-e-v4-0-eff84d2c6d26@oss.qualcomm.com

Changes in v4:
- Switched to dynamic OF node for serdev instead of swnode and dropped all
  swnode related patches
- Link to v3: https://lore.kernel.org/r/20260110-pci-m2-e-v3-0-4faee7d0d5ae@oss.qualcomm.com

Changes in v3:
- Switched to swnode for the serdev device and dropped the custom
  serdev_device_id related patches
- Added new swnode APIs to match the swnode with existing of_device_id
- Incorporated comments in the bindings patch
- Dropped the UIM interface from binding since it is not clear how it should get
  wired
- Incorporated comments in the pwrseq driver patch
- Splitted the pwrseq patch into two
- Added the 1620 LGA compatible with Key E fallback based on Stephan's finding
- Link to v2: https://lore.kernel.org/r/20251125-pci-m2-e-v2-0-32826de07cc5@oss.qualcomm.com

Changes in v2:
- Used '-' for GPIO names in the binding and removed led*-gpios properties
- Described the endpoint nodes for port@0 and port@1 nodes
- Added the OF graph port to the serial binding
- Fixed the hci_qca driver to return err if devm_pwrseq_get() fails
- Incorporated various review comments in pwrseq driver
- Collected Ack
- Link to v1: https://lore.kernel.org/r/20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com

---
Manivannan Sadhasivam (9):
      serdev: Convert to_serdev_*() helpers to macros and use container_of_const()
      serdev: Add an API to find the serdev controller associated with the devicetree node
      serdev: Do not return -ENODEV from of_serdev_register_devices() if external connector is used
      dt-bindings: serial: Document the graph port
      dt-bindings: connector: Add PCIe M.2 Mechanical Key E connector
      dt-bindings: connector: m2: Add M.2 1620 LGA soldered down connector
      Bluetooth: hci_qca: Add M.2 Bluetooth device support using pwrseq
      power: sequencing: pcie-m2: Add support for PCIe M.2 Key E connectors
      power: sequencing: pcie-m2: Create serdev device for WCN7850 bluetooth

 .../bindings/connector/pcie-m2-e-connector.yaml    | 191 ++++++++++++++
 .../devicetree/bindings/serial/serial.yaml         |   3 +
 MAINTAINERS                                        |   1 +
 drivers/bluetooth/hci_qca.c                        |   9 +
 drivers/power/sequencing/Kconfig                   |   3 +-
 drivers/power/sequencing/pwrseq-pcie-m2.c          | 285 ++++++++++++++++++++-
 drivers/tty/serdev/core.c                          |  28 +-
 include/linux/serdev.h                             |  24 +-
 8 files changed, 521 insertions(+), 23 deletions(-)
---
base-commit: 559f264e403e4d58d56a17595c60a1de011c5e20
change-id: 20251112-pci-m2-e-94695ac9d657

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

