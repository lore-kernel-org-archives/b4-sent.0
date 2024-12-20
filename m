From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v2 0/4] Misc. PowerPC MPC83xx fixes/cleanups
Date: Fri, 20 Dec 2024 11:37:50 +0100
Message-Id: <20241220-mpc83xx-misc-v2-0-ff4c17ee5fa4@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAP5IZWcC/1XMQQ6DIBCF4auYWZcGEC111Xs0LggMdRaKAUJsj
 HcvNd10+b/kfTskjIQJhmaHiIUShaWGvDRgJ7O8kJGrDZJLJSTv2bxa3W4bmylZ5lWr/Q15p5y
 GelkjetpO7jnWnijlEN+nXsR3/UGi+4eKYJxp63pnDCp/bx9rSBnDdcEM43EcHzCGzEypAAAA
X-Change-ID: 20241206-mpc83xx-misc-f438f7e054d8
To: Mario Six <mario.six@gdsys.cc>, Tom Rini <trini@konsulko.com>
Cc: Sinan Akman <sinan@writeme.com>, u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734691081; l=1030;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=qW4GQ3pkYGGiECzg5Ro1dOKBOLq139vgdvyYbx5Fq1c=;
 b=Vjmr2pgr/rIjIaR9YYnE30h1xwl4BNYdp8oqmmcvq9c1hXTTa1AFnwj3EkGy+uXO+JVTdit+E
 gexgSZG9TzmDIbBEMZQXoyeK7vXabgn5kosx74HUv0/nU6kkMMM+Dmf
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset contains a few small fixes/cleanups for the MPC83xx
platform.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Address feedback from Sinan Akman by clarifying some commit messages
- Link to v1: https://lore.kernel.org/r/20241215-mpc83xx-misc-v1-0-8cd6daae4f93@posteo.net

---
J. Neuschäfer (4):
      powerpc: mpc83xx: Fix timer value calculation
      powerpc: mpc83xx: Allow including initreg.h into multiple files
      powerpc: mpc83xx: Use defined constant for SPCR[TBEN]
      gpio: mpc8xxx: Preserve pre-init state of outputs

 arch/powerpc/cpu/mpc83xx/initreg/initreg.h |  8 ++++----
 arch/powerpc/cpu/mpc83xx/interrupts.c      |  3 ++-
 drivers/gpio/mpc8xxx_gpio.c                | 12 +++++++++++-
 drivers/timer/mpc83xx_timer.c              |  2 +-
 4 files changed, 18 insertions(+), 7 deletions(-)
---
base-commit: 337bfdce5aa52637b482b182db959b9bb058f4b7
change-id: 20241206-mpc83xx-misc-f438f7e054d8

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

