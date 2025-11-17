From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/5] soc: amlogic: Add new Amlogic SoCs info defines
Date: Mon, 17 Nov 2025 18:16:59 +0800
Message-Id: <20251117-soc-info-s6-s7-s7d-v1-0-6ab8aab03dce@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABv2GmkC/x2MuwqAMAwAf6VkNmCK718RB2lTzdJKAyJI/90i3
 HLD3QvKWVhhMS9kvkUlxSrUGHDnHg9G8dXBtrYnIouaHEoMCXVAHSseW3LTMBM5281QwytzkOe
 frlspH9fFvoZkAAAA
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763374620; l=1049;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=aukVyKf6SM/XsCjCWq9eeHkk+NbJxGlbfhudMeFmdm8=;
 b=C0IuzYTEuNE9tlPGIHItE5TtHdWAF8MvDqs2pleu8u+sCdsjEmlnuf6CzmK2OdZvZVkegdu0X
 q7Gb0lwbF1LDbwiOzCNvRMtYZqqsLVGNccYgmYZgm65TmBnot+KP+1S
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add more Amlogic SoCs info defines, include S6, S7, S7D.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (5):
      dt-bindings: arm: amlogic: meson-gx-ao-secure: support more SoCs
      soc: amlogic: meson-gx-socinfo: add new SoCs id
      arm64: dts: amlogic: s6: add ao secure node
      arm64: dts: amlogic: s7: add ao secure node
      arm64: dts: amlogic: s7d: add ao secure node

 .../bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml          | 3 +++
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi                       | 8 ++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7.dtsi                       | 8 ++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7d.dtsi                      | 8 ++++++++
 drivers/soc/amlogic/meson-gx-socinfo.c                            | 7 ++++++-
 5 files changed, 33 insertions(+), 1 deletion(-)
---
base-commit: cb718411c4c05a4a424c2b73790a1648be97a4af
change-id: 20251112-soc-info-s6-s7-s7d-01c86911c249

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

