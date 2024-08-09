From: Yang Li <yang.li@amlogic.com>
Subject: [PATCH v4 0/3] Add support for Amlogic HCI UART
Date: Fri, 09 Aug 2024 13:42:23 +0800
Message-Id: <20240809-btaml-v4-0-376b284405a7@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD+stWYC/2WNyw6CMBREf4V0bU3vbbGtK//DuKClhSYCBkijI
 fy7BZ/R5UzmnJnI4PrgBrLPJtK7GIbQtSmITUZsXbSVo6FMmSBDwQQoasaiOVOvS2lASxSFIWl
 76Z0P19VzPKVch2Hs+tuqjbC0D4Nk+dMQgTIqPeRcea2s84fUdlWwW9s1ZHFE/OLezxETB1yjQ
 YcAiv9z/MMphi+OJ65UAMx4rXf852+e5ztXixtvDAEAAA==
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
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723182152; l=1806;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=1doFq/GnmGNBeEeQE2d1SwDuwG+592umTPSGO46ePAc=;
 b=0q9QHXQQT+97DRCpC8JpU+3Hk1di8rDs6Me7TZ2w+4gHo9wNNFlY8IT+DNFYpcl08yRf1ruKq
 7PIGy+afjfhBVOZqjzbSyfXYQgkgWcuM8kgr2UsdqpfXmeZHP1NL/dn
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic HCI UART, including dt-binding,
and Amlogic Bluetooth driver.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v4:
- Modified the compatible list in the DT binding.
- Reduced the boot delay from 350ms to 60ms.
- Minor fixes.
- Link to v3: https://lore.kernel.org/r/20240802-btaml-v3-0-d8110bf9963f@amlogic.com

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

 .../bindings/net/bluetooth/amlogic,w155s2-bt.yaml  |  63 ++
 MAINTAINERS                                        |   7 +
 drivers/bluetooth/Kconfig                          |  12 +
 drivers/bluetooth/Makefile                         |   1 +
 drivers/bluetooth/hci_aml.c                        | 755 +++++++++++++++++++++
 drivers/bluetooth/hci_ldisc.c                      |   8 +-
 drivers/bluetooth/hci_uart.h                       |   8 +-
 7 files changed, 851 insertions(+), 3 deletions(-)
---
base-commit: bd0b4dae74b0f0ee9ea37818e1c132b56a26d6dd
change-id: 20240418-btaml-f9d7b19724ab

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

