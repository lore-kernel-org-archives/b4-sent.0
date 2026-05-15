From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/3] arm64: tegra: Add iommu and dma properties for
 Tegra194 QSPI
Date: Fri, 15 May 2026 15:35:26 -0500
Message-Id: <20260515-tegra194-qspi-iommu-v1-0-57dfb63cd3d6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBvIGIW6SrSIHG0WaWlFEN09a
 fkW/z+QOQln6KsHEl+SJYYCVVcwL1PwjGKLoW1a02il8WCfJtUR7nkTlLiuJzIxGSKrnXVQyi2
 xk/u/DuP7fgRpoz1lAAAA
X-Change-ID: 20260515-tegra194-qspi-iommu-e4e4644d5fdf
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778877338; l=904;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Tp/WyJ9SuV++kB1/ECxssyYjII+IBNRjHnQoniBaOW0=;
 b=4QKrUmyw8OB12fTPNgswQKz/NOJUvCF8pFGN5F24/IJctgZRkBmS26CSDh2hbTcCXH4FSQE+e
 H0SxcZaxGoKBabxGuHSZX9loqaxCcviBAMgO2uqVJGR6vKfIsYBUM84
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reason for this is to properly support the spi nor chip on the
Jetson Xavier NX module. Prior to this, it would time out on all
transfers and sometimes even trigger a cbb fault, locking up the entire
unit. With this, reading and writing to the flash memory works as
expected.

---
Aaron Kling (3):
      spi: dt-bindings: tegra: Support IOMMU property for Tegra194 QSPI
      spi: dt-bindings: tegra: Support dma-coherent property for QSPI
      arm64: tegra: Add iommu and dma properties for Tegra194 QSPI

 Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml | 6 +++++-
 arch/arm64/boot/dts/nvidia/tegra194.dtsi                        | 8 ++++++++
 2 files changed, 13 insertions(+), 1 deletion(-)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260515-tegra194-qspi-iommu-e4e4644d5fdf

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

