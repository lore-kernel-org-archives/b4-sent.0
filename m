From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v3 0/2] Bindings and DTS for Apple SoC GPUs
Date: Thu, 10 Jul 2025 00:21:43 +0200
Message-Id: <20250710-sgx-dt-v3-0-299bb3a65109@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHfrbmgC/02MQQqDMBBFryKzbkomaVS66j1KF0lMdKBqSSRYx
 Ls3WhBhNm/47y0QXSAX4V4sEFyiSOOQQV4KsJ0eWseoyQyCC8WVRBbbmTUTu2k0+aQR3EMef4L
 zNO+h5ytzR3Eaw3fvJty+/0SJRyIh46zSiF7WtbIlf7S9pvfVjj1siSTOmjw0kTVvhKkatNL76
 qyt6/oD8URQgdMAAAA=
X-Change-ID: 20250531-sgx-dt-4a1ba1b3b20f
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752099708; l=2111;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=8Py4CsLgnmpWgZRh1uEJmzkqgvbjtzPIElp16HtIFTs=;
 b=foDGSjtL1i/eBdaakPKFBpNpRz+4dnUGdroXFiKgmtpeTraJsuKgTFcqT14/2KXYfD8btZ29F
 VgtSzPatqGjCLkIaADJVX81nV5WUK5aJBdeLBqmWQ1JDECJJphLr7mB
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series adds the DT bindings and tree entries for the GPU
present in Apple M-series SoCs. The driver itself is in Rust and
upstream is currently missing several prerequisite bindings, so will
be sent later.

The kernel and m1n1 (bootloader) that are using those bindings are
available at the following branches:
Kernel: https://github.com/WhatAmISupposedToPutHere/linux/tree/starlight
m1n1: https://github.com/WhatAmISupposedToPutHere/m1n1/tree/bootloader-cal-blobs

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Changes in v3:
- Just adding trailers, effectively a resend
- Link to v2: https://lore.kernel.org/r/20250613-sgx-dt-v2-0-fb2b7d1c3ff7@gmail.com

Changes in v2:
- s/firmware-compat/firmware-abi/
- drop the agx-g13x compatible
- rework reserved regions
- Improved memory region and register descriptions
- Link to v1: https://lore.kernel.org/r/20250611-sgx-dt-v1-0-7a11f3885c60@gmail.com

---
Sasha Finkelstein (2):
      dt-bindings: gpu: Add Apple SoC GPU
      arm64: dts: Add Apple SoC GPU

 Documentation/devicetree/bindings/gpu/apple,agx.yaml | 94 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 MAINTAINERS                                          |  1 +
 arch/arm64/boot/dts/apple/t6000.dtsi                 |  4 ++++
 arch/arm64/boot/dts/apple/t6001.dtsi                 |  4 ++++
 arch/arm64/boot/dts/apple/t6002.dtsi                 |  4 ++++
 arch/arm64/boot/dts/apple/t600x-common.dtsi          | 34 ++++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t600x-die0.dtsi            | 28 ++++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8103.dtsi                 | 62 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112.dtsi                 | 62 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 9 files changed, 293 insertions(+)
---
base-commit: aef17cb3d3c43854002956f24c24ec8e1a0e3546
change-id: 20250531-sgx-dt-4a1ba1b3b20f

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

