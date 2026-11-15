From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH 0/7] arm64: dts: amlogic: Fix dtc warnings with W=1
Date: Sun, 15 Nov 2026 23:29:35 +0100
Message-Id: <20261115-fix-amlogic-dt-warnings-v1-0-94cbd67a32ea@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE8y+moC/yXMywrCMBCF4Vcps3agCVWxryIuJskYp9i0ZHoRS
 t/dWJcfnPNvoJyFFdpqg8yLqAypwJwq8C9KkVFCMdjaXowxZ3zKB6l/D1E8hglXyklSVLx6R5Y
 adrfQQHmPmcv0KN8ff+vsOvbTLwf7/gWbLGOhewAAAA==
X-Change-ID: 20261115-fix-amlogic-dt-warnings-7cba2a4eb9d4
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1829;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=fJbFmYVki+HyXICr6npVABZfI45eU0/vUz5bVXUuFtM=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9YvoyjJUmvJU9cSilvftfhdY49Ty5vLINazp032/d5Tc
 Y5CKnUdpSwMYlwMsmKKLP1zLU+8u3z0zNc96ikwc1iZQIYwcHEKwESkHjL84TumxJK1bbb403c3
 0zUEigP4xSp0T9kl3Dq3Zvu3/nN9howMD/O9a0986b2Wrh+2w25x3YMpdzginn9MWh+ZxNl24l0
 7LwA=
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Building the Amlogic device trees with W=1 CHECK_DTBS=y currently
produces several dtc warnings, all related to the same pattern:

  Warning (unit_address_vs_reg): /soc/bus@.../pinctrl@XXXX: node has a
  unit name, but no reg or ranges property
  Warning (simple_bus_reg): /soc/bus@.../pinctrl@XXXX: missing or
  empty reg/ranges property

The pinctrl nodes use an empty "ranges;" while having a unit address.

With this series applied, the Amlogic DTBs build without any warning
with:

  make ARCH=arm64 W=1 CHECK_DTBS=y amlogic/

Boot tested on Khadas VIM1 (GXL) and Khadas VIM4 (T7)

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Ronald Claveau (7):
      arm64: dts: amlogic: t7: Add ranges to periphs pinctrl node
      arm64: dts: amlogic: a1: Add ranges to periphs pinctrl node
      arm64: dts: amlogic: axg: Add ranges to periphs pinctrl node
      arm64: dts: amlogic: g12: Add ranges to periphs pinctrl node
      arm64: dts: amlogic: gxbb: Add ranges to periphs pinctrl node
      arm64: dts: amlogic: gxl: Add ranges to periphs pinctrl node
      arm64: dts: amlogic: s4: Add ranges to periphs pinctrl node

 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi       | 2 +-
 arch/arm64/boot/dts/amlogic/meson-a1.dtsi         | 2 +-
 arch/arm64/boot/dts/amlogic/meson-axg.dtsi        | 5 +++--
 arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi | 6 ++----
 arch/arm64/boot/dts/amlogic/meson-gxbb.dtsi       | 5 +++--
 arch/arm64/boot/dts/amlogic/meson-gxl.dtsi        | 5 +++--
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi         | 2 +-
 7 files changed, 14 insertions(+), 13 deletions(-)
---
base-commit: 6d582d78fad9d828e575ca0cdcff8ea47a77220b
change-id: 20261115-fix-amlogic-dt-warnings-7cba2a4eb9d4

Best regards,
--  
Ronald Claveau <linux-kernel-dev@aliel.fr>

