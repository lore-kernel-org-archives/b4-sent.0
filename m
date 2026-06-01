From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH 0/3] IPQ5018: Add and enable GEPHY RX and TX clocks
Date: Mon, 01 Jun 2026 17:19:07 +0400
Message-Id: <20260601-ipq5018-gephy-clocks-v1-0-2df8287712c3@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBsYxUq6SrQQm2ooyhSiiO6et
 HyL/x9IHIUTtMUDkU9Jsm8ZqizAz26bGGXIBk26ppoUSjgqUhYnDvONft39kpCt08aQaqwjyGm
 IPMr1b7v+fT8UZsxAZgAAAA==
X-Change-ID: 20260601-ipq5018-gephy-clocks-e8a2440178a0
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780319950; l=2139;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=97pdXoZiUaNbUg/dCgG8k67el3mw2yrvAWwxG2/xB7E=;
 b=NlWHkSLpvAxs/YmwWdPWhmxX66Jul+YmsKCW5EBMAYOgKHG7r/f6ZLNRlKX8EBD4I2V2bcMSf
 TyI9Kk35NwFDwxTdmAO3aF8TzLdJz7Jva0N9C9gWzyE6dXUhdTe9Zfj
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Greetings,

This patch series addresses a missing hardware description issue for the
Qualcomm IPQ5018 Internal Ethernet PHY, where the data paths fail to
function correctly unless their dedicated RX and TX clocks are
explicitly enabled.

Further testing revealed that leaving these clocks unmanaged by the
kernel, they were inadvertently left enabled by the bootloader / QSDK
platform, which masked the issue. Testing a fresh network configuration
path exposed that the data link fails to work without explicit software
gating.

To correctly introduce the required multi-clock properties, the IPQ5018
binding definition must first be split away from the shared
qca,ar803x.yaml schema. This isolation is required because ar803x
references the generic ethernet-phy.yaml, which enforces a strict
single-clock limit constraint. 

- Patch 1: Splits the IPQ5018 definitions to its own bindings schema 
           to accommodate the multi-clock requirement.
- Patch 2: Appends the missing RX/TX clock definitions into the IPQ5018
           device tree before driver modification to avoid the driver
	   failing to probe.
- Patch 3: Updates the Qualcomm AT803x PHY driver framework to safely
	   acquire, enable, and gate these clocks upon link state
	   changes for runtime power optimization.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
George Moussalem (3):
      dt-bindings: net: qca,ipq5018: Split IPQ5018 PHY bindings from ar803x
      arm64: qcom: ipq5018: Add GEPHY RX and TX clocks
      net: phy: qca,at803x: add RX and TX clock management for IPQ5018 PHY

 .../devicetree/bindings/net/qca,ar803x.yaml        | 43 -------------
 .../devicetree/bindings/net/qca,ipq5018.yaml       | 75 ++++++++++++++++++++++
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              |  3 +
 drivers/net/phy/qcom/at803x.c                      | 23 +++++++
 4 files changed, 101 insertions(+), 43 deletions(-)
---
base-commit: 7da7f07112610a520567421dd2ffcb51beaefbcc
change-id: 20260601-ipq5018-gephy-clocks-e8a2440178a0

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

