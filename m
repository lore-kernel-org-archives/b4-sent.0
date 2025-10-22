From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/2] arm64: tegra: Add CPU OPP tables for
 Tegra186/Tegra194
Date: Tue, 21 Oct 2025 20:13:40 -0500
Message-Id: <20251021-tegra186-icc-p3-v3-0-68184ee8a89c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMQv+GgC/3WNyw6CMBBFf4XM2jEt5aUr/8OwKGWASeRhi42G9
 N+tuHDl8pzknruBI8vk4JxsYMmz43mKoA4JmEFPPSG3kSEVaS5FKnGl3mpZFcjG4KJQdUWWZ63
 OyWQQV4uljp978Vp/2dL9EcPrTw7s1tm+9lcvP/b/gZcoUBgl1amomrJsLv2o+XY08wh1COENE
 8N3oMMAAAA=
X-Change-ID: 20251021-tegra186-icc-p3-3f6454da5ec4
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761095624; l=1210;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=8iY7QoUBS9qHAKKfcMb8SKuucgQX30enphMOTq2KRCU=;
 b=zngQlbTPr7Su0Nwf9Imc8H+YBaO/p5OJ/TlvMqvNunoNrJinC7veEAYlCUcjoagLIDPEPXA7A
 95mvtZ052mUB1bbFP+UWRp+WtRtlcdD+JmjMEIIo2p1jGRQ35uFcmAS
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bindings Dependencies:
- https://lore.kernel.org/r/20251021-tegra186-icc-p2-v3-0-1a50b526dd40@gmail.com

Logical Dependencies:
- https://lore.kernel.org/r/20251021-tegra186-icc-p1-v3-1-7e6db3b070c4@gmail.com

Merge Strategy:
- Merge all patches only after all dependencies are picked up

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v3:
- Split series
- Link to v2: https://lore.kernel.org/r/20250909-tegra186-icc-v2-0-09413724e781@gmail.com

Changes in v2:
- Use opp scoped free in patch 3
- Cleanup as requested in patch 3
- Move patch 3 to the start of the series to keep subsystems grouped
- Link to v1: https://lore.kernel.org/r/20250831-tegra186-icc-v1-0-607ddc53b507@gmail.com

---
Aaron Kling (2):
      arm64: tegra: Add CPU OPP tables for Tegra186
      arm64: tegra: Add CPU OPP tables for Tegra194

 arch/arm64/boot/dts/nvidia/tegra186.dtsi | 317 +++++++++++++++
 arch/arm64/boot/dts/nvidia/tegra194.dtsi | 636 +++++++++++++++++++++++++++++++
 2 files changed, 953 insertions(+)
---
base-commit: 211ddde0823f1442e4ad052a2f30f050145ccada
change-id: 20251021-tegra186-icc-p3-3f6454da5ec4

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

