From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH 0/3] arm64: dts: freescale: add Free Mobile Nodebox v3 CPU
 Module (LX2160A)
Date: Mon, 07 Sep 2026 16:27:36 +0200
Message-Id: <20260907-for-upstream-nbxv3-dts-v1-0-f43fd0028b78@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANjJnmoC/x3MMQ6DMAxA0asgz1hyE9SWXgUxJMS0HgjIBoSEu
 DtRxzf8f4KxCht8qhOUdzGZc8GjrmD4hfxllFQMjtyTWnrhOCtui63KYcIcj91jWg1j5CFRQ/4
 dHJR4UR7l+I+7/rpuFKHuYmgAAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788791274; l=1400;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=ziuOeOxSNcqiPfzFdD4nGs0eE7gGvrp2Nr8Qsw9rbZY=;
 b=FqDKCKguM57Z6Ctx3L4bATK3YBeUPX8/dyvlG+82bXhG1o+utV545PQQZUSwUwV4jqpBWixiN
 vn35b0/2Z8+A4b4CmS9yOlqLloRLGGLI39toULxKRizXqC5cvB8UxXJ
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Nodebox v3 is a Free Mobile CPU module built around the NXP LX2160A
(16x Cortex-A72, DPAA2).

The same fsl-lx2160a-nbxv3.dtsi shall be used verbatim by the
U-Boot port, sent in parallel to the U-Boot list, so the two trees
cannot drift.

XXX Dependency:

the DTS uses gpio hogs on the QorIQ GPIO controllers, which
needs the commit
  78c0baf85cd0 ("dt-bindings: gpio: fsl,qoriq-gpio: allow gpio-hog child nodes")
already in gpio/for-next and that will likely arrive in v7.4-rc1.
Until it lands, dtbs_check reports the five hog nodes, the rest of the
tree validates clean against the current schemas.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Vincent Jardin (3):
      dt-bindings: vendor-prefixes: add Free Mobile
      dt-bindings: arm: fsl: add freemobile,nbxv3 board
      arm64: dts: freescale: add Nodebox v3 CPU Module

 Documentation/devicetree/bindings/arm/fsl.yaml     |   6 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/freescale/Makefile             |   2 +
 .../arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dts |  30 ++
 .../boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi      | 342 +++++++++++++++++++++
 5 files changed, 382 insertions(+)
---
base-commit: df2908090cda368b01ff43709f51890076c56157
change-id: 20260907-for-upstream-nbxv3-dts-bbecd04038a2

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

