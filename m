From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v3 0/4] IPQ5018: Add and enable GEPHY RX and TX clocks
Date: Fri, 05 Jun 2026 16:41:25 +0400
Message-Id: <20260605-ipq5018-gephy-clocks-v3-0-f232d9ca0966@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNTQrCMBCG4auUrI1kpn+DK+8hLkKatKHV1KQGS
 +ndTbsSQVy+H8wzCwvaWx3YKVuY19EG6+4p8kPGVCfvrea2Sc1QYCUqAdyOj1IA8VaP3czV4FQ
 fuCaJRSGgJilYOh29Nva1s5dr6s6Gyfl5/xJhW/+AEbjg2BhCqmtAlZ/dcxqc64/K3dhGRvxk8
 AeDialKCQYaIjBfzLqub7iRLNcBAQAA
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
 George Moussalem <george.moussalem@outlook.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780663297; l=3562;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=vWoBVXItD2urAe47ImUviMmyYrwl8cRkGI9EK0YXHMU=;
 b=+DJfZpCccG8Uq/Zp3CvuEj60cWvw3CiDrhxFmmI0lC+JkpERrWg5GCD6uP5MnxXqKQMyTqAw1
 FBX737mUwTiBu1Ga7HWn7GQL7pFeYxlrYNLFe8Xw9v+AqBmxC6drmcZ
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

- Patch 1: Moves the clocks property and its restriction out of the
	   generic ethernet-phy.yaml schema to individual bindings files
	   that need it to allow for PHYs that require multiple clocks.
- Patch 2: Add clocks property to qca,ar803x.yaml for the IPQ5018 PHY.
- Patch 3: Appends the missing RX/TX clock definitions into the IPQ5018
           device tree before driver modification to avoid the driver
	   failing to probe.
- Patch 4: Updates the Qualcomm AT803x PHY driver framework to acquire,
	   enable, and gate these clocks upon link state changes for
	   runtime power optimization.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Changes in v3:
- Revert the change to move the clocks property out of the generic
  ethernet-phy.yaml schema and simple increase the maxItems limit to 2.
- Listed clocks, clock-names, and resets as required properties in the
  schema.
- Acquire the RX and TX clock during probe without enabling them. Then
  enable/disable the clocks in the link state change callback to ensure
  they are only active when needed with checks to avoid redundant
  enable/disable calls.
- Re-ran make dt_binding_check on all schemas in net folder without new
  issues.
- Link to v2: https://lore.kernel.org/r/20260602-ipq5018-gephy-clocks-v2-0-65a1f1d881f3@outlook.com

Changes in v2:
- Added patch 1 to move the clocks property and its restriction out of
  the generic ethernet-phy.yaml schema to individual bindings files that
  need it to allow for PHYs that require multiple clocks.
- Reverted splitting out IPQ5018 from the shared qca,ar803x.yaml schema
  and simply added the clocks and clock-names properties to the
  definition of the IPQ5018 PHY.
- Corrected / updated commit title of patch 4 (qca,at803x -> at803x)
- Link to v1: https://lore.kernel.org/r/20260601-ipq5018-gephy-clocks-v1-0-2df8287712c3@outlook.com

---
George Moussalem (4):
      dt-bindings: net: ethernet-phy: increase max clock count to two
      dt-bindings: net: qca,ar803x: Add clocks for IPQ5018 PHY
      arm64: qcom: ipq5018: Add GEPHY RX and TX clocks
      net: phy: at803x: add RX and TX clock management for IPQ5018 PHY

 .../devicetree/bindings/net/ethernet-phy.yaml      |  9 +++--
 .../devicetree/bindings/net/qca,ar803x.yaml        | 19 ++++++++++
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              |  3 ++
 drivers/net/phy/qcom/at803x.c                      | 43 ++++++++++++++++++++++
 4 files changed, 71 insertions(+), 3 deletions(-)
---
base-commit: 7da7f07112610a520567421dd2ffcb51beaefbcc
change-id: 20260601-ipq5018-gephy-clocks-e8a2440178a0

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

