From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH v6 0/3] arm64: dts: freescale: add Free Mobile Nodebox v3
 CPU Module (LX2160A)
Date: Sun, 13 Sep 2026 14:35:23 +0200
Message-Id: <20260913-for-upstream-nbxv3-dts-v6-0-058566b93ba1@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIuYpmoC/43Pz07DMAwG8FeZcibIcf407MR7IA5J47AcaKekR
 ENT3x1vpw6pguNnyb/PvopGtVATx8NVVOqllXni4J4OYjyF6YNkSZwFAjp4gUHmucqvc1sqhU8
 5xUvXMi1NxkhjAgPaBxS8fK6Uy+UOv71zPpW2zPX73tPVbfon2ZUEmY3OCQB9HPxrrkTPuYob2
 PF/CDLiogk5aac8xEdEbxG/i2hGVPI+4qiU8/CImA2i1C5iGEF+ZkjWDjb8usRuEdxFLCMUkgO
 TYnBqg6zr+gOxUopnzgEAAA==
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Vincent Jardin <vjardin@free.fr>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789302928; l=3725;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=dUzCkECkA/OkZoSAB4OMJbUdtyMQr7Up7oJ04mOLJRY=;
 b=vNSvWoYdPC+e05hcI+ayjWu4t4rveFXkMu0MAJ+noGK4CapDkDwFiqM8IYPbwwopZkqRSZNEK
 yqHMlTv6SDbDupweA1cFRW2wSLfzWFYBefNCyMazO0LqZaWYOQ+MA0O
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Nodebox v3 is a Free Mobile CPU module built around the NXP LX2160A
(16x Cortex-A72, DPAA2).

The same fsl-lx2160a-nbxv3.dtsi shall be used verbatim by the
U-Boot port, sent in parallel to the U-Boot list, so the two trees
cannot drift.

Dependency:

the DTS uses gpio hogs on the QorIQ GPIO controllers, which
needs the commit
  78c0baf85cd0 ("dt-bindings: gpio: fsl,qoriq-gpio: allow gpio-hog child nodes")
already in gpio/for-next and that will likely arrive in v7.4-rc1.
Until it lands, dtbs_check reports the five hog nodes, the rest of the
tree validates clean against the current schemas.

About the patch 2, following Krzysztof's question on v5: the CPU module
boots on its own, so it is listed as a plain LX2160A board. It is also
a SoM that will support many carrier boards.

But those carrier boards are still work in progress, so they are not part
of this series yet. When they will be, fsl.yaml should get them (not
included with this series, just for comments and TBC):

      - description: Free Mobile Nodebox v3 CPU Module based Boards
        items:
          - enum:
              - freemobile,nbv30
              - freemobile,nbv31
              - freemobile,nbv32
          - const: freemobile,nbxv3
          - const: fsl,lx2160a

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v6:
- dt-bindings: arm: fsl: freemobile,nbxv3 no 1 entry enum for the
  "LX2160A based Boards" (Krzysztof Kozlowski)
- Link to v5: https://lore.kernel.org/r/20260912-for-upstream-nbxv3-dts-v5-0-ead604dba61b@free.fr

Changes in v5:
- read dts-coding-style: many reorder/cleanup including
  comments from Frank Li without functional changes
- Link to v4: https://lore.kernel.org/r/20260911-for-upstream-nbxv3-dts-v4-0-2fd07d5575ab@free.fr

Changes in v4:
- dt-bindings: arm: fsl: commit message like the other ones (Krzysztof Kozlowski)
- Acked-by on the vendor prefix
- Drop U-Boot comments from the DTS commit message (Frank Li)
- Boot NOR reset: reset-gpios on flash@0 instead of a gpio hog (Frank Li)
- ethsw-mdio-en: regulator-fixed instead of a gpio hog (Frank Li)
- ethsw-reset#: hog dropped (Frank Li)
- pltrst#: platform without consumer node
- Link to v3: https://lore.kernel.org/r/20260908-for-upstream-nbxv3-dts-v3-0-1d88b2c11680@free.fr

Changes in v3:
- Drop the thermtrip hog on gpio1 line 23, should have been clean'd
  before
- Link to v2: https://lore.kernel.org/r/20260907-for-upstream-nbxv3-dts-v2-0-6b4afd36180b@free.fr

Changes in v2: (from Sashiko's comments)
- Makefile: dtb entry in alphabetical order (before qds).
- Move the XSPI1_A_DATA[7:4] GPIO mux group from &fspi to &gpio1, so
  the reset hogs on gpio1 do not depend on the fspi probe.
- gpio hogs: describe ethsw-reset# and ethsw-mdio-en with their
  active-low polarity (GPIO_ACTIVE_LOW), same electrical levels.
- Link to v1: https://lore.kernel.org/r/20260907-for-upstream-nbxv3-dts-v1-0-f43fd0028b78@free.fr

---
Vincent Jardin (3):
      dt-bindings: vendor-prefixes: add Free Mobile
      dt-bindings: arm: fsl: add Free Mobile Nodebox v3 CPU Module
      arm64: dts: freescale: add Nodebox v3 CPU Module

 Documentation/devicetree/bindings/arm/fsl.yaml     |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/freescale/Makefile             |   2 +
 .../arm64/boot/dts/freescale/fsl-lx2160a-nbxv3.dts |  34 +++
 .../boot/dts/freescale/fsl-lx2160a-nbxv3.dtsi      | 330 +++++++++++++++++++++
 5 files changed, 369 insertions(+)
---
base-commit: df2908090cda368b01ff43709f51890076c56157
change-id: 20260907-for-upstream-nbxv3-dts-bbecd04038a2

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

