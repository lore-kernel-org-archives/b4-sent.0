From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/9] Add support for handling PCIe M.2 Key E connectors in
 devicetree
Date: Wed, 12 Nov 2025 20:15:12 +0530
Message-Id: <20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHidFGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0Mj3YLkTN1cI91UXUsTM0vTxGTLFDNTcyWg8oKi1LTMCrBR0bG1tQB
 YQKlsWgAAAA==
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
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5716;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=fcOLB6aV+fb9mRzie6Oop52h19x8OdlUrwUv/AKoKFg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpFJ2G7KlzBgIqqLqxlA+KZvF2LQnt5o2J4sC6m
 5T22DpFW/+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaRSdhgAKCRBVnxHm/pHO
 9QjrB/9XHscvM2AZEr4cvvGDU7LjMbW+6OH13K8HChauuQQq1sQCyda01k1+C75y7jgDegnxjIn
 r/fanARmC5BGZzRB7ZqmyhtHbsc6bfXuHVAYY9mf21mbN04Yt15eeIDlBTlrblXStHlXP14Iu7H
 gjw3GxZ8oMZM/6oaqpcjJjFUNGRC1TWsWnL1V84Ao9qRMJ75TN2fLZyG+4Pd7m803HQEDmIjFZR
 qvZfU3tT96zNXbmmhFkxKgPsvOk9XV104b84AvbJlgjDhuYnU7Y2j4x7J1Y5kdZGUa6zIHnXUiD
 OUpq3nlOAZCKUrLvb5zIfglGBLIUYTafIbPLj2me6+pJP+Cg
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

Open questions
==============

Though this series adds the relevant functionality for handling the M.2 Key M
connectors, there are still a few open questions exists on the design. 

1. I've used the M.2 card model name as the serdev device name. This is found
out by comparing the PCIe VID:PID in the notifier. Is this approach acceptable?
I did not use the PID as the serdev name since it will vary if the SDIO
interface is used in the future.

2. PCIe client drivers of some M.2 WLAN cards like the Qcom QCA6390, rely on
the PCIe device DT node to extract properties such as
'qcom,calibration-variant', 'firmware-name', etc... For those drivers, should we
add the PCIe DT node in the Root Port in conjunction with the Port node as
below?

pcie@0 {
	wifi@0 {
		compatible = "pci17cb,1103";
		...
		qcom,calibration-variant = "LE_X13S";
	};

	port {
		pcie4_port0_ep: endpoint {
			remote-endpoint = <&m2_e_pcie_ep>;
		};
	};
};

This will also require marking the PMU supplies optional in the relevant ath
bindings for M.2 cards.

3. Some M.2 cards require specific power up sequence like delays between
regulator/GPIO and such. For instance, the WCN7850 card supported in this series
requires 50ms delay between powering up an interface and driving it. I've just
hardcoded the delay in the driver, but it is a pure hack. Since the pwrseq
driver doesn't know anything about the device it is dealing with before powering
it ON, how should it handle the device specific power requirements? Should we
hardcode the device specific property in the connector node? But then, it will
no longer become a generic M.2 connector and sort of defeats the purpose of the
connector binding.

I hope to address these questions with the help of the relevant subsystem
maintainers and the community. Until then, this series is *not* mergeable as a
whole.

Testing
=======

This series, together with the devicetree changes [2] was tested on the
Qualcomm X1e based Lenovo Thinkpad T14s Laptop which has the WCN7850 WLAN/BT M.2
card connected over PCIe and UART.

[1] https://lore.kernel.org/linux-pci/20251108-pci-m2-v2-0-e8bc4d7bf42d@oss.qualcomm.com
[2] https://github.com/Mani-Sadhasivam/linux/commit/d39b81b3ff1ecfb0d423b4da0771925d41648b5a

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (9):
      serdev: Convert to_serdev_device() and to_serdev_controller() helpers to macros
      serdev: Add serdev device based driver match support
      serdev: Allow passing the serdev device name to serdev_device_add()
      serdev: Add an API to find the serdev controller associated with the devicetree node
      serdev: Add modalias support for serdev client devices
      serdev: Skip registering serdev devices from DT is external connector is used
      dt-bindings: connector: Add PCIe M.2 Mechanical Key E connector
      Bluetooth: hci_qca: Add support for WCN7850 PCIe M.2 card
      power: sequencing: pcie-m2: Add support for PCIe M.2 Key E connectors

 .../bindings/connector/pcie-m2-e-connector.yaml    | 154 +++++++++++++++
 MAINTAINERS                                        |   1 +
 drivers/bluetooth/hci_qca.c                        |  20 ++
 drivers/platform/x86/dell/dell-uart-backlight.c    |   2 +-
 .../x86/lenovo/yoga-tab2-pro-1380-fastcharger.c    |   2 +-
 drivers/platform/x86/x86-android-tablets/core.c    |   2 +-
 drivers/power/sequencing/Kconfig                   |   1 +
 drivers/power/sequencing/pwrseq-pcie-m2.c          | 218 ++++++++++++++++++++-
 drivers/tty/serdev/core.c                          |  77 +++++++-
 include/linux/mod_devicetable.h                    |   8 +
 include/linux/serdev.h                             |  25 ++-
 scripts/mod/devicetable-offsets.c                  |   3 +
 scripts/mod/file2alias.c                           |   8 +
 13 files changed, 494 insertions(+), 27 deletions(-)
---
base-commit: db81ec30672bb228cd7cd809edeeae661d621f2d
change-id: 20251112-pci-m2-e-94695ac9d657

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

