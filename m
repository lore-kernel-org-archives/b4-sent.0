From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/4] Misc. PowerPC MPC83xx fixes/cleanups
Date: Sun, 15 Dec 2024 16:18:12 +0100
Message-Id: <20241215-mpc83xx-misc-v1-0-8cd6daae4f93@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADTzXmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDIwMz3dyCZAvjigrd3MziZN00E2OLNPNUA1OTFAsloJaCotS0zAqwcdG
 xtbUA9Ox/jV4AAAA=
X-Change-ID: 20241206-mpc83xx-misc-f438f7e054d8
To: Mario Six <mario.six@gdsys.cc>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734275902; l=843;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=BmfkDjizKG1+Buafa1ZtSkt5nDBG5cY8Hi2KaFJVx+U=;
 b=rTjv5iYzT/+KOIXi4nlFtyufgqv5Ob6HdAXlFkMmWzP9Px5IbsAxqk2jKpOHsIL4Ahl+SZEMi
 H80K8IbMcF5AUzqRnnA9kIiGloOI0sqWrLCwVzyRfOggn1F3d6mSIml
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset contains a few small fixes/cleanups for the MPC83xx
platform.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
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
base-commit: 9bc62c980d418f0a67632ab29cd3501072cdb6f0
change-id: 20241206-mpc83xx-misc-f438f7e054d8

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

