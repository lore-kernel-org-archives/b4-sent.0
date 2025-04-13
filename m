From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v4 0/4] Tegra CEC Updates
Date: Sun, 13 Apr 2025 14:35:31 -0500
Message-Id: <20250413-tegra-cec-v4-0-b6337b66ccad@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAMS/GcC/23MQQ6DIBCF4as0rEsDCKJd9R5NFwgzSlK1AUPaG
 O9edEWaLt9kvn8lEYKHSK6nlQRIPvp5ykOeT8QOZuqBepc3EUwoJpmmC/TBUAuWaqiM7gClqpH
 k/1cA9O+jdX/kPfi4zOFzpBPfr/8qiVNGQSjnWqV1p/DWj8Y/L3YeyV5JopRNKUWWAhmT6LCR0
 PzKqpRtKassW15Lxivu0IhSbtv2BYMczdIWAQAA
X-Change-ID: 20250407-tegra-cec-7e3a7bef456f
To: Hans Verkuil <hverkuil@xs4all.nl>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744572933; l=1886;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=mwG4Cj2Ztv79BD/XS/55Zl5lC0H2/N8fCCGZjwWMhH0=;
 b=wQQLFHjhNIRlAbrNd3iQPtZZrdGAJgPmBlPEX6gwfQAxHvR+FZr+OOkrHNgbZPJ4D8fa/jNc9
 N79fbjQESF+DRnMfJUMIlo+P7Z7b64m905VcjEox5xn2XHfruQsaKug
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series updates Tegra hdmi cec support to be usable out of the box
on Tegra210 through Tegra194.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v4:
- Fix review comment on patch 1
- Link to v3: https://lore.kernel.org/r/20250409-tegra-cec-v3-0-91640131dfa2@gmail.com

Changes in v3:
- Update patch 1 to fix lint warnings
- Link to v2: https://lore.kernel.org/r/20250408-tegra-cec-v2-0-2f004fdf84e8@gmail.com

Changes in v2:
- Dropped patch 2, per request
- Added change to declare fallback compatibles instead, as per request
- Update patch 1 to allow fallback compatibles
- Link to v1: https://lore.kernel.org/r/20250407-tegra-cec-v1-0-e25dd9577b5f@gmail.com

---
Aaron Kling (4):
      media: dt-bindings: Document Tegra186 and Tegra194 cec
      arm64: tegra: Add fallback cec compatibles
      arm64: tegra: Add CEC controller on Tegra210
      arm64: tegra: Wire up cec to devkits

 .../devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml | 14 ++++++++++----
 arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts         |  6 ++++++
 .../boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts     |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra186.dtsi                   |  2 +-
 arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dts         |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra194-p3509-0000.dtsi        |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra194.dtsi                   |  2 +-
 arch/arm64/boot/dts/nvidia/tegra210-p2371-2180.dts         |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts         |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra210.dtsi                   |  9 +++++++++
 10 files changed, 57 insertions(+), 6 deletions(-)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250407-tegra-cec-7e3a7bef456f

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

