From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/2] powerpc: Fix and enforce distinction between
 immediates and registers
Date: Thu, 12 Dec 2024 18:05:45 +0100
Message-Id: <20241212-gpr-checks-v1-0-8c084c5fc0b6@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOkXW2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDQyNL3fSCIt3kjNTk7GLdlFQDA7OUlEQLQ8skJaCGgqLUtMwKsGHRsbW
 1ANxExHNcAAAA
X-Change-ID: 20241129-gpr-checks-de006dda819b
To: Mario Six <mario.six@gdsys.cc>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?Marek_Beh=C3=BAn?= <kabel@kernel.org>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734023157; l=882;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=ZcU6uQ7ejaFY/D4tPICQRF7swS4pWua3gbeiw/SjWxs=;
 b=Fcgm6nOpVyMcjFy4P3CmkabP9WqMwwfBrNAn7qU8IVTpQQNNvYOG+loXXnjEFIthxY1lyMc/O
 FS33e0/s4clA5gug0I7sErGOOT8yTlefokWKHtBY0I7YaPjgvo6O1zq
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset changes the definition r0 etc. to %r0, so that the
assembler can check that registers are only used where expected, and
fixes the fallout.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (2):
      powerpc: Fix 0 vs. r0 confusion in X/D-form instructions
      powerpc: Introduce and enforce assembler checks on GPR usage

 arch/powerpc/config.mk           |  2 +-
 arch/powerpc/cpu/mpc83xx/start.S | 72 ++++++++++++++++++++--------------------
 arch/powerpc/cpu/mpc85xx/start.S | 24 +++++++-------
 arch/powerpc/lib/ppccache.S      |  6 ++--
 include/ppc_asm.tmpl             | 66 ++++++++++++++++++------------------
 5 files changed, 85 insertions(+), 85 deletions(-)
---
base-commit: a75acb55442302aeaca993a5c4337fd130766e58
change-id: 20241129-gpr-checks-de006dda819b

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

