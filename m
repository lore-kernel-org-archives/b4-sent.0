From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/6] Add new Amlogic SoCs info defines.
Date: Mon, 15 Jul 2024 16:59:18 +0800
Message-Id: <20240715-soc_info-v2-0-3836c8cc27a5@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAObklGYC/0XMQQrCMBCF4auUWRtJolHjyntIkTSZtgM2I4kUp
 eTuxoK4/B+Pb4GMiTDDuVkg4UyZONbQmwb86OKAgkJt0FLv5VEpkdnfKPYsglT2dOh2AaWFen8
 k7Om1Ute29kj5yem9yrP6rj9E/5FZCSmk6Zw1Vttg3MVNdx7Ibz1P0JZSPuPSe8KiAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721033959; l=1350;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=1X1lMeZGpdzV9mt09bNsIQMlalbtKkMui88g6bFSQE0=;
 b=LFT8ReBhEBQbxL20C4GgGLQv5fFEqrxtwgHaVVGjck5SfooLGn+EnlxWoF2LqJjZBeY7w7PB8
 zCkN97YAq1XAmfJKLwQlgbGGi4ymn/3cEaN4DceJdUmDLLQeZpS4Pbj
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add more Amlogic SoCs info defines, include S4, C3
T7, A4, A5.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Add S4,C3,T7,A4 ao-secure bindings.
- Modify ao_secure node using fallback to meson-gx.
- Link to v1: https://lore.kernel.org/r/20240712-soc_info-v1-0-05ba95929d5a@amlogic.com

---
Xianwei Zhao (6):
      dt-bindings: arm: amlogic: meson-gx-ao-secure: support more SoCs.
      soc: amlogic: meson-gx-socinfo: add new SoCs id
      arm64: dts: amlogic: s4: add ao secure node
      arm64: dts: amlogic: c3: add ao secure node
      arm64: dts: amlogic: t7: add ao secure node
      arm64: dts: amlogic: a4: add ao secure node

 .../bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml | 16 ++++++++++++----
 arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi       |  8 ++++++++
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi              |  7 +++++++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi              |  8 ++++++++
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi                |  8 ++++++++
 drivers/soc/amlogic/meson-gx-socinfo.c                   | 10 ++++++++++
 6 files changed, 53 insertions(+), 4 deletions(-)
---
base-commit: db067bd17c0124228c31c5fdfa29ec65239e692a
change-id: 20240711-soc_info-d01986b3de09

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

