From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/4] memory: tegra210-emc: Support Device Tree EMC
 Tables
Date: Thu, 08 May 2025 01:07:37 -0500
Message-Id: <20250508-tegra210-emc-dt-v2-0-d33dc20a1123@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAClKHGgC/2WNQQ6CMBBFr0Jm7Zi2IDquvIdh0bQDTGKpaQnRE
 O5uJe5cvpf891fInIQzXKsVEi+SJU4FzKECN9ppYBRfGIwyJ9UYwpmHZI1WyMGhn5HO3nFLyvq
 GoayeiXt57cV7V3iUPMf03g8W/bW/Vq3+WotGjUQXanvbUt3o2xCsPI4uBui2bfsAPz21Hq4AA
 AA=
X-Change-ID: 20250429-tegra210-emc-dt-97dce690ad4e
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-tegra@vger.kernel.org, 
 devicetree@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746684461; l=1217;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=h+pfeE2YEuEkhstsQ/EywIS3qHB3FnGPIcU0/7ZAPTU=;
 b=2sbjpz0NHNUxabBRxSPI3YxFl2lApicoZ+XOPwEzfS+fRBYBmvSKFAQVP6HGDOZW4jdMz3iCh
 WEfRWwRIuxGBjZoADeWJnDqLPX8JjbqochzUpo/8/ZcN2dOBOHsDUR2
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Add patch to describe the emc table bindings
- Add patch to allow a fallback compatible on the tegra210 emc device to
  match firmware expectations
- Add a patch to include the baseline emc tables on p2180
- Link to v1: https://lore.kernel.org/r/20250430-tegra210-emc-dt-v1-1-99896fa69341@gmail.com

---
Aaron Kling (4):
      dt-bindings: memory-controllers: Describe Tegra210 EMC Tables
      dt-bindings: memory-controllers: tegra210: Allow fallback compatible
      arm64: tegra: Add EMC timings to P2180
      memory: tegra210-emc: Support Device Tree EMC Tables

 .../nvidia,tegra21-emc-table.yaml                  |  1692 +
 .../memory-controllers/nvidia,tegra210-emc.yaml    |    44 +-
 arch/arm64/boot/dts/nvidia/tegra210-p2180-emc.dtsi | 49749 +++++++++++++++++++
 arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi     |     1 +
 drivers/memory/tegra/tegra210-emc-core.c           |   246 +-
 5 files changed, 51721 insertions(+), 11 deletions(-)
---
base-commit: 8bac8898fe398ffa3e09075ecea2be511725fb0b
change-id: 20250429-tegra210-emc-dt-97dce690ad4e

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

