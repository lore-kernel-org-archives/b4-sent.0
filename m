From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] arm64: tegra: Clean up serial nodes
Date: Mon, 28 Apr 2025 20:51:46 -0500
Message-Id: <20250428-tegra-serial-fixes-v1-0-4f47c5d85bf6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALIwEGgC/x3LQQqAIBBA0avErBswSbCuEi1ERxsIC40IxLtnL
 T+fVyBTYsowdwUS3Zz5iC2GvgO7mRgI2bUGKaQSo9R4UUgGP2V29PxQxslbZ7V3SkgBDZ6J/tH
 cstb6AtJhidpkAAAA
X-Change-ID: 20250428-tegra-serial-fixes-9fcdc8fd5020
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Thierry Reding <treding@nvidia.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745891537; l=989;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=3rBhkmDwlkecphkN0Dy6r3jKKnMCRAC/bfxsVRUq1Fg=;
 b=XgXqQ+/gz4QT8jWarYRYNvBu3k28rMjaarAS+Pssbc5Lkd9qeoyB89au3NfrY6IasBFIFuAhX
 H0Ttx7rJ6QdBg47ALj40ZFDx9qct4/GWVIW394GCu6BbYI9UIN+iNm8
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several Tegra186 and Tegra194 serial nodes still have invalid properties
and/or are missing dma properties. This series corrects those.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (2):
      arm64: tegra: Drop remaining serial clock-names and reset-names
      arm64: tegra: Add DMA properties for Tegra186 and Tegra194 UARTs

 arch/arm64/boot/dts/nvidia/tegra186-p3310.dtsi     |  2 ++
 .../dts/nvidia/tegra186-p3509-0000+p3636-0001.dts  |  2 ++
 arch/arm64/boot/dts/nvidia/tegra186.dtsi           | 26 ++++++++++----------
 arch/arm64/boot/dts/nvidia/tegra194-p2888.dtsi     |  2 ++
 arch/arm64/boot/dts/nvidia/tegra194-p3668.dtsi     |  2 ++
 arch/arm64/boot/dts/nvidia/tegra194.dtsi           | 28 ++++++++++++----------
 6 files changed, 38 insertions(+), 24 deletions(-)
---
base-commit: ca91b9500108d4cf083a635c2e11c884d5dd20ea
change-id: 20250428-tegra-serial-fixes-9fcdc8fd5020

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

