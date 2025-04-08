From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/4] Tegra CEC Updates
Date: Tue, 08 Apr 2025 15:29:57 -0500
Message-Id: <20250408-tegra-cec-v2-0-2f004fdf84e8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEWH9WcC/23MQQ7CIBCF4as0s3YMxSLRlfcwXVAY6CS2NNAQT
 dO7i127/F9evg0yJaYM92aDRIUzx7mGPDVgRzMHQna1QQqpRCc0rhSSQUsWNV2MHsh36uqh/pd
 Ent+H9exrj5zXmD4HXdrf+k8pLQokqZy7Ka0H5R9hMvw62zhBv+/7FzTJHCGiAAAA
X-Change-ID: 20250407-tegra-cec-7e3a7bef456f
To: Hans Verkuil <hverkuil@xs4all.nl>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744144221; l=1593;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=pSNYHP17o7Fgq2T92jXtQMIX7yPDgExcuj9fOGXUZ58=;
 b=/4oHnJM10rg/wTNM5JAmmK5r0+5IGk+KmssuLjFh/kfOcHrWh4LaIoENtPMl5ameemKTJqILk
 OqKaVGF4L6kBQ29G4NSP/Yy4pj+691Mm1WKhTo9o5wPCMlhCjyYuvN/
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series updates Tegra hdmi cec support to be usable out of the box
on Tegra210 through Tegra194.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
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

 .../bindings/media/cec/nvidia,tegra114-cec.yaml           | 15 +++++++++++----
 arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts        |  6 ++++++
 .../boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts    |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra186.dtsi                  |  2 +-
 arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dts        |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra194-p3509-0000.dtsi       |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra194.dtsi                  |  2 +-
 arch/arm64/boot/dts/nvidia/tegra210-p2371-2180.dts        |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts        |  6 ++++++
 arch/arm64/boot/dts/nvidia/tegra210.dtsi                  |  9 +++++++++
 10 files changed, 58 insertions(+), 6 deletions(-)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250407-tegra-cec-7e3a7bef456f

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

