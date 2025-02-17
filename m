From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/2] PowerPC MPC8xxx compile-time checks
Date: Mon, 17 Feb 2025 16:48:46 +0100
Message-Id: <20250217-immap-size-v1-0-f9be2e9e7b1a@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAF5as2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0Nz3czc3MQC3eLMqlTd5DTLNLM0AzNDY8tUJaCGgqLUtMwKsGHRsbW
 1ANbPozJcAAAA
X-Change-ID: 20250217-immap-size-cf9f6f06139e
To: Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739807332; l=838;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=Vbqt3KOb4chSAnlaTarptv5LOLGhmoTGufJULP+YovI=;
 b=M8VYQwm4N1B06R829rzLytUXY1jBnflXswHipSxUMOA5jut+FwnF998BoXG28SdK6ORM/y7hw
 fchgTDCzhA6D436kcHNGPpWoVdAXwY7cMB6M6JtzrkYb+h6L1/Kvneq
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series happens entirely in the C preprocessor, catching some kinds
of bugs a bit earlier than they otherwise would. Everything has been
compile-tested, and there should be no change to runtime behavior.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (2):
      powerpc: mpc83xx: Check the size of peripheral structs
      powerpc: mpc8xxx_spi: Catch bad chip variants earlier

 arch/powerpc/include/asm/fsl_i2c.h     |  2 ++
 arch/powerpc/include/asm/fsl_lbc.h     |  1 +
 arch/powerpc/include/asm/immap_83xx.h  | 37 ++++++++++++++++++++++++++++++++++
 arch/powerpc/include/asm/mpc8xxx_spi.h |  3 +++
 4 files changed, 43 insertions(+)
---
base-commit: 52ae6d8588ac8d96b7866ecb29029eff375c7171
change-id: 20250217-immap-size-cf9f6f06139e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

