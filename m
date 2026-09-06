From: =?utf-8?q?Juan_Carlos_Guti=C3=A9rrez_Lavado?= <jcarlosgl96@proton.me>
Subject: [PATCH 0/2] Add SPC Glee 10.1 A64 board support
Date: Sun, 06 Sep 2026 16:05:48 +0000
Message-Id: <20260906-b4-spc-glee-a64-v1-v1-0-621df2155e31@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxG4auQrm0yIDbqVYyLzvCLNQbJVAkJ4
 e6MuvwW7y3kyAanc7VQxmRur6Gg3lWU7jr0YOuKqQmNhFMQji37mLh/AqzS8lSzQLqo+6PqAVT
 CMeNm8296uf7tn/hAen9PtK4bB62QmnYAAAA=
X-Change-ID: 20260906-b4-spc-glee-a64-v1-6e6dba38aa5e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Juan_Carlos_Guti=C3=A9rrez_Lavado?= <jcarlosgl96@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788710758; l=2104;
 i=jcarlosgl96@proton.me; s=20260906; h=from:subject:message-id;
 bh=caba7iV0TFn9M6TC++uiQpGXS0aTWxbFXW99xT02rXE=;
 b=cUKSRkx9BBgLI4AuGvEDwoNpcMTdkYV58Xmaj6UZcfvXlzlAK8ArFCy9pzbq80RVCo9egA26X
 Aq3u7moAyvdDQAy+zqk/n567UIa1341g5SC92dPzSkH2U3EMre99Vq6
X-Developer-Key: i=jcarlosgl96@proton.me; a=ed25519;
 pk=2/GzZfrbHAiuUrsA5A4A9ixfHKnypfDfzyE+fToY4Io=
X-Endpoint-Received: by B4 Relay for jcarlosgl96@proton.me/20260906 with auth_id=1008
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add initial mainline support for the SPC Glee 10.1 tablet, based on the
Allwinner A64 and AXP803 PMIC.

The board description covers the 2 GiB DRAM configuration, essential
CPU and system rails, microSD, UART, battery monitoring and USB device
mode. Other peripherals remain disabled until independently validated.

The microSD slot deliberately uses broken-cd and a conservative 25 MHz
limit because its card-detect wiring and higher-speed modes have not been
validated independently. USB is limited to the tested peripheral role.

The exact DTB produced by this series was cold-booted from microSD with
Linux 7.3.0-rc1. The kernel detected all four CPU cores and 2 GiB RAM,
probed the AXP803 over RSB, detected the microSD card, mounted the ext4
root filesystem and started systemd. The boot command line did not use
regulator_ignore_unused. No eMMC access was required.

Validation was run against sunxi/for-next at commit 913f7eda9f3e:

  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image \
       allwinner/sun50i-a64-spc-glee.dtb
  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
       DT_SCHEMA_FILES=Documentation/devicetree/bindings/arm/sunxi.yaml \
       dt_binding_check
  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- W=1 \
       CHECK_DTBS=y allwinner/sun50i-a64-spc-glee.dtb

Signed-off-by: Juan Carlos Gutiérrez Lavado <jcarlosgl96@proton.me>
---
Juan Carlos Gutiérrez Lavado (2):
      dt-bindings: arm: sunxi: Add SPC Glee 10.1 A64
      arm64: dts: allwinner: Add SPC Glee 10.1 A64

 Documentation/devicetree/bindings/arm/sunxi.yaml   |   5 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/allwinner/Makefile             |   1 +
 .../boot/dts/allwinner/sun50i-a64-spc-glee.dts     | 123 +++++++++++++++++++++
 4 files changed, 131 insertions(+)
---
base-commit: 913f7eda9f3e3fb1c67285e144e202494d440049
change-id: 20260906-b4-spc-glee-a64-v1-6e6dba38aa5e

Best regards,
--  
Juan Carlos Gutiérrez Lavado <jcarlosgl96@proton.me>

