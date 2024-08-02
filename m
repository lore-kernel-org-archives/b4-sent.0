From: Yang Li <yang.li@amlogic.com>
Subject: [PATCH v3 0/3] Add support for Amlogic HCI UART
Date: Fri, 02 Aug 2024 17:39:46 +0800
Message-Id: <20240802-btaml-v3-0-d8110bf9963f@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGKprGYC/1WNQQ7CIBBFr9KwFsMMbQBX3sO4KBRaElsMNETT9
 O7Saowu38+8NwtJNnqbyKlaSLTZJx+mAvxQETO0U2+p7woTZFizGiTVczveqFOd0KAE1q0m5fY
 erfOPvXO5Fh58mkN87tkM2/ouCNZ8Chkoo8JBw6VT0lh3LmvovTmaMJKtkfHH+37OWDzgCjVaB
 JD831vX9QXt1AZl1AAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722591623; l=1589;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=CWclPJ4pjk4LvCG6DZIT3d/BBZcJRSdZLLIzy3xSXx8=;
 b=x4vT1adzcphYX0rrutz0CZCP/dHB/HZkjXhHrk8E/y/uNjJi7MiMFh/ChVMNIpDuTz3UhJf2n
 mbxzV5P04axBWe33fisj9pxvwqNDQdjLEhcJyEb9YDhdNyWrcPNRjJ6
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic HCI UART, including dt-binding,
and Amlogic Bluetooth driver.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v3:
- Updated the properties within the device tree binding file.
- Remove the "antenna-number" property.
- Performed code optimization for improved efficiency and readability.
- Link to v2: https://lore.kernel.org/r/20240718-btaml-v2-0-1392b2e21183@amlogic.com

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

 .../bindings/net/bluetooth/amlogic,w155s2-bt.yaml  |  62 ++
 MAINTAINERS                                        |   7 +
 drivers/bluetooth/Kconfig                          |  12 +
 drivers/bluetooth/Makefile                         |   1 +
 drivers/bluetooth/hci_aml.c                        | 756 +++++++++++++++++++++
 drivers/bluetooth/hci_ldisc.c                      |   8 +-
 drivers/bluetooth/hci_uart.h                       |   8 +-
 7 files changed, 851 insertions(+), 3 deletions(-)
---
base-commit: 2360f368524bb817b71bdd2efed53d0c3c3929ad
change-id: 20240418-btaml-f9d7b19724ab

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

