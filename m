From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH RESEND v2 0/5] PowerPC: A few cleanups in MPC83xx
 devicetrees
Date: Tue, 03 Mar 2026 16:50:50 +0100
Message-Id: <20260303-mpc83xx-cleanup-v2-0-187d3a13effa@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772553061; l=1655;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=79m/nJ/QDMP8KLr5bX+4nacC2eKgzRySRWsaV7zH+GM=;
 b=zrNwdxzIbYzU/MGAyY0HR5Ici/8ZnZZKhC/bkSy+egATOEhlLVs9Q8qIji2hiK+Duui3GPCGi
 0UMAJUK79SjD43EpU71/2yC+3eOnMXb+/fK9RPUc0p7Xbco4jcxUGsh
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series contains a few cleanups for mpc8315erdb.dts and other
PowerPC devicetrees, which are hopefully uncontroversial.

Some of the patches were previously part of another, larger series,
titled "powerpc: MPC83xx cleanup and LANCOM NWAPP2 board", but that
series became too unwieldy to carry on. For this reason, this series
starts at version 2.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (5):
      powerpc: dts: mpc8313erdb: Use IRQ_TYPE_* macros
      powerpc: dts: mpc8315erdb: Use IRQ_TYPE_* macros
      powerpc: dts: mpc8315erdb: Rename LED nodes to comply with schema
      powerpc: dts: mpc8315erdb: Add missing #cells properties to SPI bus
      powerpc: dts: mpc83xx: Add unit addresses to /memory

 arch/powerpc/boot/dts/asp834x-redboot.dts |   2 +-
 arch/powerpc/boot/dts/mpc8308_p1m.dts     |   2 +-
 arch/powerpc/boot/dts/mpc8308rdb.dts      |   2 +-
 arch/powerpc/boot/dts/mpc8313erdb.dts     |  61 ++++++++-------
 arch/powerpc/boot/dts/mpc8315erdb.dts     | 119 ++++++++++++++++--------------
 arch/powerpc/boot/dts/mpc832x_rdb.dts     |   2 +-
 arch/powerpc/boot/dts/mpc8349emitx.dts    |   2 +-
 arch/powerpc/boot/dts/mpc8349emitxgp.dts  |   2 +-
 arch/powerpc/boot/dts/mpc8377_rdb.dts     |   2 +-
 arch/powerpc/boot/dts/mpc8377_wlan.dts    |   2 +-
 arch/powerpc/boot/dts/mpc8378_rdb.dts     |   2 +-
 arch/powerpc/boot/dts/mpc8379_rdb.dts     |   2 +-
 12 files changed, 109 insertions(+), 91 deletions(-)
---
base-commit: d3f2d8e7de622d2a2d4283cb545e51745d87f0c5
change-id: 20260101-mpc83xx-cleanup-4de8df290c75

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

