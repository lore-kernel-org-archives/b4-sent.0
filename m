From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 15 Dec 2024 16:18:15 +0100
Subject: [PATCH 3/4] powerpc: mpc83xx: Use defined constant for SPCR[TBEN]
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241215-mpc83xx-misc-v1-3-8cd6daae4f93@posteo.net>
References: <20241215-mpc83xx-misc-v1-0-8cd6daae4f93@posteo.net>
In-Reply-To: <20241215-mpc83xx-misc-v1-0-8cd6daae4f93@posteo.net>
To: Mario Six <mario.six@gdsys.cc>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734275902; l=916;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=kJCUbfAfUkZYqBpxwo4bs9D6hIqE6X1cmBqwutBIAkk=;
 b=5lO0rnYHjYjhu4KCyMhQegxgnI/E9W1mM3XmemGJShLb9Y3bEuwr3Pk+K4c6h3hVOXWe8gYp4
 rEq7R8XMB9NBmYHxbPUD2gu9erlpIbmfcs0SBcfZ2qJvVeyB67Ycig4
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To increase readability, use the defined constant instead of specifying
SPCR[TBEN] as a number.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/cpu/mpc83xx/interrupts.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/powerpc/cpu/mpc83xx/interrupts.c b/arch/powerpc/cpu/mpc83xx/interrupts.c
index af517213f176cf59cc82b54dbe5247800a6c40e6..bb37a1332c877951e766a8891687dae3f05b6ef8 100644
--- a/arch/powerpc/cpu/mpc83xx/interrupts.c
+++ b/arch/powerpc/cpu/mpc83xx/interrupts.c
@@ -12,6 +12,7 @@
 #include <asm/global_data.h>
 #include <asm/processor.h>
 #include <asm/ptrace.h>
+#include "initreg/initreg.h"
 
 DECLARE_GLOBAL_DATA_PTR;
 
@@ -29,7 +30,7 @@ void interrupt_init_cpu (unsigned *decrementer_count)
 
 	/* Enable e300 time base */
 
-	immr->sysconf.spcr |= 0x00400000;
+	immr->sysconf.spcr |= SPCR_TBEN_MASK;
 }
 
 /*

-- 
2.45.2

