From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Subject: [PATCH 0/4] Subject: [PATCH v2 0/4] staging: octeon: Clean up PHY
 interfaces and fix race conditions
Date: Sat, 07 Nov 2026 20:07:54 -0600
Message-Id: <20261107-octeon-phy-series-v2-v1-0-d7ab0b4b3f17@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqAIBBA0avIrBtQoYSuEi2yxpyNikYU0t2TW
 v7F+xUKZaYCo6iQ6eTCMbRQnYDVL2En5K01aKkHpaTBuB4UAyZ/40/x1OjI9tYsSm69g0ZTJsf
 Xt53m53kBR0ZPVGYAAAA=
X-Change-ID: 20261107-octeon-phy-series-v2-feb5b7a10d5f
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794103676; l=2143;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=v1Ib2YX7z7cOuwFzAUWIynBIV1qydc12UgH8Jji2kcg=;
 b=UFT5vAyrlET82+eVIbq5Lj4REzY4pffvSd3SB95Ey75CjM87XHHqdiTcCAvwrNL+MkAcO/qdE
 4dRoOV8FaBXDw94teMoaX3/qXzYugR3B30wZ1BO6DMBBuxR8LPUlaid
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series provides a comprehensive clean-up, documentation alignment, and 
critical bug fixes for the Cavium Octeon staging ethernet PHY interfaces 
(SGMII, MDIO, RGMII, and SPI).

- v2: Consolidated the individual floating patches into a single 
  well-ordered patch series as requested by the maintainer.
- Investigation: Patches were identified through manual code analysis of the 
  staging driver directory, inspecting resource lifetimes on initialization 
  routines, checking error rollback pathways, and reviewing compliance with 
  kernel-doc scripting definitions.
- Testing: All patches in this series were successfully verified and built 
  via cross-compilation for the MIPS architecture using the mips64-linux-gnu- 
  toolchain with explicit W=1 compilation flags, ensuring zero compilation 
  warnings or errors. Style formatting was audited via scripts/checkpatch.pl --strict.

Oscar Alejandro Sánchez Lucero (4):
  staging: octeon: add kernel-doc to ethernet-sgmii.c functions
  staging: octeon: fix OF node leak and kernel-doc in ethernet-mdio.c
  staging: octeon: fix race condition and log macro in ethernet-rgmii.c
  staging: octeon: fix IRQ leak error path and remove dst.h from ethernet-spi.c

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Oscar Alejandro Sánchez Lucero (4):
      staging: octeon: add kernel-doc to ethernet-sgmii.c functions
      staging: octeon: fix OF node leak and kernel-doc in ethernet-mdio.c
      staging: octeon: fix race condition and log macro in ethernet-rgmii.c
      staging: octeon: fix IRQ leak error path and remove dst.h from ethernet-spi.c

 drivers/staging/octeon/ethernet-mdio.c  |  6 ++++--
 drivers/staging/octeon/ethernet-rgmii.c | 12 +++++-------
 drivers/staging/octeon/ethernet-sgmii.c | 12 ++++++++++++
 drivers/staging/octeon/ethernet-spi.c   | 10 ++++++++--
 4 files changed, 29 insertions(+), 11 deletions(-)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-octeon-phy-series-v2-feb5b7a10d5f

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

