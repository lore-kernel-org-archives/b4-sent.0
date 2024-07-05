From: Yang Li <yang.li@amlogic.com>
Subject: [PATCH 0/4] Add support for Amlogic HCI UART
Date: Fri, 05 Jul 2024 19:20:43 +0800
Message-Id: <20240705-btaml-v1-0-7f1538f98cef@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAvXh2YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDE0ML3aSSxNwc3TTLFPMkQ0tzI5PEJCWg2oKi1LTMCrA50bG1tQA2fFp
 IVwAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720178456; l=1154;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=ljo98Oix0zF4HtbxIYPVKXMO3zcHlaqIjHBPe9TuLUw=;
 b=wVCKzjwrsOMYUCq8ga1twDNQUMMYDrVatd/xEz7R4znyMbF++ttuGYNqnZ85XWj298yrSuLEY
 2yR0llMi5+HDAp7a2s9Z6wUWVBWLVuhsLRU1IfBDsEWuXwBUgzVnG+c
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic HCI UART, including dt-binding, Amlogic Bluetooth driver
and enable HCIUART_AML in defconfig.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Yang Li (4):
      dt-bindings: net: bluetooth: Add support for Amlogic Bluetooth
      Bluetooth: hci_uart: Add support for Amlogic HCI UART
      arm64: defconfig: Enable hci_uart for Amlogic Bluetooth
      MAINTAINERS: Add an entry for Amlogic HCI UART

 .../bindings/net/bluetooth/amlogic,w155s2-bt.yaml  |  62 ++
 MAINTAINERS                                        |   8 +
 arch/arm64/configs/defconfig                       |   1 +
 drivers/bluetooth/Kconfig                          |  13 +
 drivers/bluetooth/Makefile                         |   1 +
 drivers/bluetooth/hci_aml.c                        | 749 +++++++++++++++++++++
 drivers/bluetooth/hci_ldisc.c                      |   8 +-
 drivers/bluetooth/hci_uart.h                       |   8 +-
 8 files changed, 847 insertions(+), 3 deletions(-)
---
base-commit: e3203b17771757fdcd259d6378673f1590e36694
change-id: 20240418-btaml-f9d7b19724ab

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

