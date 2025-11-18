From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/5] soc: amlogic: Add new Amlogic SoCs info defines
Date: Tue, 18 Nov 2025 13:58:59 +0800
Message-Id: <20251118-soc-info-s6-s7-s7d-v2-0-38e2b31a88d1@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACMLHGkC/22NzQrCMBCEX6Xs2ZVs1P548j2kh3Sbtgu2KVkpS
 um7GwvehLl8A/PNCuqjeIVrtkL0i6iEKYE9ZMCDm3qP0iYGa+yFiCxqYJSpC6g5apHSoiEu84q
 I7bmCNJyj7+S1S+914kH0GeJ7/1jo2/50xT/dQmgwd03pXGNOLfubGx+hFz5yGKHetu0D1mZ4E
 LYAAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763445540; l=1206;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=1QM0t5Ua7sLNTgCR2HCyFI0Jnd2kpNqkgXu1GjfNhHY=;
 b=6aaN2cau58FDKag+CaRCY9OtdEKI+wgC9kmXaJRppovgKuLz5yFuPf3aqOJpLRo4zWGkyj+PD
 R0NlVfv75jSBPv4plZ5B2cpA89fs99xDjoRI2rznjksDCqkur0j8a7q
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add more Amlogic SoCs info defines, include S6, S7, S7D.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Restore the previous accidental deletion of A4.
- Link to v1: https://lore.kernel.org/r/20251117-soc-info-s6-s7-s7d-v1-0-6ab8aab03dce@amlogic.com

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
 drivers/soc/amlogic/meson-gx-socinfo.c                            | 6 ++++++
 5 files changed, 33 insertions(+)
---
base-commit: 8d5b965a53bf6a4e2a2a028b75b2c7067cde5397
change-id: 20251112-soc-info-s6-s7-s7d-01c86911c249

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

