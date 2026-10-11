From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH 0/2] arm64: dts: meson-gxbb-odroidc2: eFuse MAC address and
 LED properties
Date: Sun, 11 Oct 2026 20:17:20 +0300
Message-Id: <20261011-odroidc2-dts-v1-0-f9f0e779af88@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDXptFi4iljQDsZCpYNIxN0Vy
 7f4/wKhyCRQZxdEOlg4LAmYZ+CmbhlJsU8Go02FGlEFHwN7Z5TfRJW2031lCmsdQkrWSAOf365
 pf8vez+S29wH3/QBRMK56cAAAAA==
X-Change-ID: 20261011-odroidc2-dts-53a0b62433c1
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791739040; l=1059;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=ae1bPrtDyGrs2a0laMfc/OYJpM4BBJvlclfzCOSwtR0=;
 b=GVJBAWBcJccI7BftcnfSOQBKjaaNNOT8mkWe4pU5mIhBCjmUdbK1NotBESevNbZMlvCPP5WJD
 YvfS4QJfZUVAo8pp02GouscmEfXDjIGElN+Ru7FNwfYLmLpSzeqrrLF
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two small device-tree updates for the Hardkernel ODROID-C2, found while
adding OpenWrt support for the board.

Patch 1 wires the eth_mac eFuse nvmem cell (already described in
meson-gx.dtsi, but so far unused) to the Ethernet controller, so the
kernel reads the factory MAC address itself instead of relying on the
bootloader or a random fallback.

Patch 2 converts the blue status LED to the standard color/function
properties.

Both verified on ODROID-C2 hardware and rechecked against this tree
with CHECK_DTBS=y W=1.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
Fil Dunsky (2):
      arm64: dts: meson-gxbb-odroidc2: read the Ethernet MAC address from eFuse
      arm64: dts: meson-gxbb-odroidc2: use color and function for the status LED

 arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)
---
base-commit: a5ebb76233b79db01e82e061173cb73c6d2b5c6b
change-id: 20261011-odroidc2-dts-53a0b62433c1

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

