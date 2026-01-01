From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH RESEND v5 0/4] Freescale Enhanced Local Bus Controller
 (eLBC) binding YAML conversion
Date: Thu, 01 Jan 2026 17:58:13 +0100
Message-Id: <20260101-ppcyaml-elbc-v5-0-251c7f14a06c@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, Crystal Wood <oss@buserror.net>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Naveen N Rao <naveen@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Christophe Leroy <chleroy@kernel.org>
Cc: Frank Li <Frank.Li@nxp.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-mtd@lists.infradead.org, 
 linuxppc-dev@lists.ozlabs.org, dri-devel@lists.freedesktop.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767286712; l=2344;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=ooT2t/4HDi3rmfv8HHUPwediCnOQ2VSqg+dxjAIoQhg=;
 b=tkESbjbCfHLs5ZLrxdB3VqXvHOOr2xcQRyDat/LnJymOrsQM4NuahZvrNrbPDuPcGYByIHfRJ
 b/3TMX2UBp0CjtyXqKUEFj+UbSJHe2OF381erdf/AOfUEnLRQfJJlKN
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series converts the fsl,elbc binding to YAML and adds new bindings
for related devices (particular kinds of chip on the eLBC).

For readability, the existing unit address syntax of <cs>,<offset>
(e.g. nand@1,0) is kept. This results in a few dtc validation warnings,
when combined with other choices in this patchset:

- For compatibility with existing kernels which don't explicitly probe
  under an eLBC controller, the "simple-bus" compatible string is kept
  on eLBC controller nodes. The validation logic requires a linear unit
  address, though (e.g. @100000000 instead of @1,0)

The patches in this series were previously part of the following series,
which turned out to be too large and unwieldy:
[PATCH v2 00/12] YAML conversion of several Freescale/PowerPC DT bindings
https://lore.kernel.org/lkml/20250207-ppcyaml-v2-0-8137b0c42526@posteo.net/

Changelogs are present in the individual patches.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v5:
- Rebase on v6.15-rc1
- Add Rob Herring's reviewed-by tags to patches 1,3
- Fix documentation reference in Documentation/devicetree/bindings/display/ssd1289fb.txt
- Link to v4: https://lore.kernel.org/r/20250313-ppcyaml-elbc-v4-0-55903722d9ea@posteo.net

Changes in v4:
- Reintroduce patch "dt-bindings: mtd: raw-nand-chip: Relax node name pattern"
- Link to v3: https://lore.kernel.org/r/20250226-ppcyaml-elbc-v3-0-a90ed71da838@posteo.net

---
J. Neuschäfer (4):
      dt-bindings: mtd: raw-nand-chip: Relax node name pattern
      dt-bindings: memory-controllers: Add fsl,elbc-gpcm-uio
      dt-bindings: nand: Add fsl,elbc-fcm-nand
      dt-bindings: memory-controllers: Convert fsl,elbc to YAML

 .../devicetree/bindings/display/ssd1289fb.txt      |   2 +-
 .../memory-controllers/fsl,elbc-gpcm-uio.yaml      |  59 ++++++++
 .../bindings/memory-controllers/fsl,elbc.yaml      | 158 +++++++++++++++++++++
 .../devicetree/bindings/mtd/fsl,elbc-fcm-nand.yaml |  68 +++++++++
 .../devicetree/bindings/mtd/raw-nand-chip.yaml     |   2 +-
 .../devicetree/bindings/powerpc/fsl/lbc.txt        |  43 ------
 6 files changed, 287 insertions(+), 45 deletions(-)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250220-ppcyaml-elbc-bb85941fb250

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

