From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v2 0/2] arm64: dts: meson-gxbb-odroidc2: eFuse MAC address
 and LED properties
Date: Sun, 11 Oct 2026 21:31:39 +0300
Message-Id: <20261011-odroidc2-dts-v2-0-a3a4a752f2ab@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw7CIBBFf6WZtRig2ocr/8N0QWFox9hioBJNw
 79b6trlSc49d4WAnjDApVjBY6RAbt5AHgrQo5oHZGQ2BsllJbgQzBnvyGjJzBLYuVS8r+SpLLW
 AbfL0aOm9527dj8Orv6NeciMbI4XF+c/+F0X2/qSjYJzZ1nKs61bZprkOk6LHUbsJupTSF81Ij
 8G6AAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791743499; l=2030;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=aWMsxig8K23vnf/R1OjXs+3LeoRMkfmdoowDD+N8d68=;
 b=PY/UhwoUt2ayvSvnBN0VcVMGvOsm5rRv67RWyVsbw8k5cjG13tdXsLE9z+YkyS+AwaqE7IahB
 ICQMtjYTH4IBd8fMvhLxj0QrC+eEizoFKe9HDPV+cSV+oMGJJKr390A
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two small device-tree updates for the Hardkernel ODROID-C2, found while
adding OpenWrt support for the board.

Patch 1 wires the eth_mac eFuse nvmem cell (already described in
meson-gx.dtsi, but so far unused) to the Ethernet controller, narrowed
to the 6 bytes of the address, so the kernel reads the factory MAC
address itself instead of relying on the bootloader or a random
fallback.

Patch 2 converts the blue status LED to the standard color/function
properties.

Both verified on ODROID-C2 hardware and rechecked against this tree
with CHECK_DTBS=y W=1.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
Changes in v2:
- Patch 1: narrow the eth_mac cell to 6 bytes for this board.  The
  16-byte cell from meson-gx.dtsi is rejected by
  of_get_mac_address_nvmem(), so v1 only appeared to work because the
  bootloader had already fixed up local-mac-address.  Reported by the
  Sashiko AI review.
- Patch 1: describe the actual test setup in the commit message.
- Link to v1: https://patch.msgid.link/20261011-odroidc2-dts-v1-0-f9f0e779af88@gmail.com

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Neil Armstrong <neil.armstrong@linaro.org>
To: Kevin Hilman <khilman@baylibre.com>
To: Jerome Brunet <jbrunet@baylibre.com>
To: Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-amlogic@lists.infradead.org
Cc: linux-kernel@vger.kernel.org

---
Fil Dunsky (2):
      arm64: dts: meson-gxbb-odroidc2: read the Ethernet MAC address from eFuse
      arm64: dts: meson-gxbb-odroidc2: use color and function for the status LED

 arch/arm64/boot/dts/amlogic/meson-gxbb-odroidc2.dts | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)
---
base-commit: a5ebb76233b79db01e82e061173cb73c6d2b5c6b
change-id: 20261011-odroidc2-dts-53a0b62433c1

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

