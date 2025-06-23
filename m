From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/3] support for amlogic the new SPI IP
Date: Mon, 23 Jun 2025 16:53:26 +0800
Message-Id: <20250623-spisg-v3-0-c731f57e289c@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAYWWWgC/1WMywqDMBQFf0Xuuil5GI1d9T9KFzGJeqEaSUpoE
 f+9USq0yzmcmQWiC+giXIoFgksY0U8ZxKkAM+ipdwRtZuCUS1pRQeKMsSe16jirFHetNpC/c3A
 dvvbO7Z55wPj04b1nE9vWo1B+C4kRSqRqhG1dYxsprnp8+B7N2fgRtkbiPx6rD49vHtMVlVqVr
 ZX/3rquH0emp13UAAAA
To: Sunny Luo <sunny.luo@amlogic.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750668807; l=1629;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=p18CvQGKMdeKcKL07AwNst72I3d+5bFuKEFexGALk3U=;
 b=tUWAfZEfn6V1qOrLffkQ6+jtjMIJ8GSQGkSDtZa3pD8b3NE9PFhjslDCBCXSmbHrP1rPK1I5g
 y2vNtyOW+8hDK/2v8d+rgFyhL7vnYs3Qhllh1TjbVGWVBzO2Vm/7fhd
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduced support for the new SPI IP (SPISG). The SPISG is
a communication-oriented SPI controller from Amlogic,supporting
three operation modes: PIO, block DMA, and scatter-gather DMA.

Add the drivers and device tree bindings corresponding to the SPISG.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v3:
- Rename of bit definition and fix some issues.
- Enable runtime_suspend function.
- Link to v2: https://lore.kernel.org/r/20250617-spisg-v2-0-51a605a84bd5@amlogic.com

Changes in v2:
- Use regmap to operation register and drop bitfied define.
- Use "SPISG" prefix intead of "SPICC", and declare clock div table in the spisg_device. 
- Delete other power operation functions except for runtime_supspend and runtime_resume.
- Fix some format corrections.
- Link to v1: https://lore.kernel.org/r/20250604-spisg-v1-0-5893dbe9d953@amlogic.com

---
Sunny Luo (2):
      dt-bindings: spi: Add binding document of Amlogic SPISG controller
      spi: Add Amlogic SPISG driver

Xianwei Zhao (1):
      MAINTAINERS: Add an entry for Amlogic spi driver

 .../devicetree/bindings/spi/amlogic,a4-spisg.yaml  |  55 ++
 MAINTAINERS                                        |   9 +
 drivers/spi/Kconfig                                |   9 +
 drivers/spi/Makefile                               |   1 +
 drivers/spi/spi-amlogic-spisg.c                    | 876 +++++++++++++++++++++
 5 files changed, 950 insertions(+)
---
base-commit: bd30b995df8fd053e13d10f78dbc7b2fa5ed1aae
change-id: 20250603-spisg-78f21682ebac

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

