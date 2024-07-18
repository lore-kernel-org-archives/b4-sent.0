From: Yang Li <yang.li@amlogic.com>
Subject: [PATCH v2 0/3] Add support for Amlogic HCI UART
Date: Thu, 18 Jul 2024 15:42:18 +0800
Message-Id: <20240718-btaml-v2-0-1392b2e21183@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFrHmGYC/y3MQQ7CIBRF0a00fywGkAZw5D5MB0Ch/YktBhqia
 di7WB3el5ezQ/YJfYZrt0PyBTPGtQU/deBms06e4NgaOOWCCqaI3czyIEGP0jItuTAW2veZfMD
 X4dyH1jPmLab3wRb2XX+CpP1fKIxQIgPrLypo5Xy4tTVO6M4uLjDUWj+mDLEinAAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Yang Li <yang.li@amlogic.com>, 
 Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721288574; l=1309;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=McKO7a2Y9X5UuWrJvOXo6XzO6tf+ZBq08Na/c5RO+zI=;
 b=yaEHvInkvweHp4KULgQoWMx2FfK9VIzp24xUAWtkczpAXykd9ulVlbDUQyyItoTFFdlqpTF+R
 3LBUXfXOZtFBO1nMiiSc+rH13F9K6ssqRZO7fZnUFROqioIQsgUg1xr
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic HCI UART, including dt-binding,
and Amlogic Bluetooth driver.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v2:
- Introduce a regulator for powering up the Bluetooth chip instead of power sequencing.
- Use the GPIO Consumer API to manipulate the GPIO pins instead of the legacy API.
- Minor fixes.
- Link to v1: https://lore.kernel.org/r/20240705-btaml-v1-0-7f1538f98cef@amlogic.com

---
Yang Li (3):
      dt-bindings: net: bluetooth: Add support for Amlogic Bluetooth
      Bluetooth: hci_uart: Add support for Amlogic HCI UART
      MAINTAINERS: Add an entry for Amlogic HCI UART (M: Yang Li)

 .../bindings/net/bluetooth/amlogic,w155s2-bt.yaml  |  66 ++
 MAINTAINERS                                        |   7 +
 drivers/bluetooth/Kconfig                          |  12 +
 drivers/bluetooth/Makefile                         |   1 +
 drivers/bluetooth/hci_aml.c                        | 772 +++++++++++++++++++++
 drivers/bluetooth/hci_ldisc.c                      |   8 +-
 drivers/bluetooth/hci_uart.h                       |   8 +-
 7 files changed, 871 insertions(+), 3 deletions(-)
---
base-commit: 54dd4796336de8ce5cbf344db837f9b8448ebcf8
change-id: 20240418-btaml-f9d7b19724ab

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

