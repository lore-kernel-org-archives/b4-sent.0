From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 18 Feb 2025 16:55:51 +0100
Subject: [PATCH] common: board_r: Initialize interrupts before watchdog
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250218-init-v1-1-a1c5bf9e8fb0@posteo.net>
X-B4-Tracking: v=1; b=H4sIAIattGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0ML3cy8zBLdlMQkw7Rkc6PEpBQjJaDSgqLUtMwKsDHRsbW1AIDogUJ
 WAAAA
X-Change-ID: 20250218-init-dab1fc72abd2
To: Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739894152; l=1865;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=T4cIbIiYoRKNkHbTkYfbF9qlEVqdDddNnJIsoKjEF5M=;
 b=5vqu+d/XmpJ3e+jb0E9fpm7ooQJrG39yzWg2yG9TDZuChejCv7UmVvOFPV3eBxL2ZPN4z6hJM
 rXg55bKh7XUCsF4FJaxmZo5LizGdkzuaFjYFdqD2LPxDIAvICTQSnaa
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some platforms, initializing the watchdog driver enables a timer
interrupt. This of course requires the interrupt handlers to be
properly initialized, otherwise U-Boot may crash or run the timer
interrupt handler of a previous bootloader stage.

To account for such systems, always initialize interrupts
(arch_initr_trap) before the watchdog (initr_watchdog).

This problem was observed on a PowerPC MPC83xx board.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
NOTE: This approach seems safe and fine to me, but an argument could be
      made that this should be fixed in the platform-specific drivers
      instead.  Please let me know what you think.


Rough stack trace (not sure if it should be part of the commit message):

  initr_watchdog                (drivers/watchdog/wdt-uclass.c)
    device_probe(wdt@200)
      device_probe(timer)
        mpc8xxx_wdt_start       (drivers/watchdog/mpc8xxx_wdt.c)
          set_msr(get_msr() | MSR_EE);

  arch_initr_trap               (arch/powerpc/lib/traps.c)
    trap_init                   (arch/powerpc/cpu/mpc83xx/start.S)
---
 common/board_r.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/common/board_r.c b/common/board_r.c
index 179259b00de81f7ba9802fc5288e7c2b6e6f381a..f711cd237ae76d80ca2413017bfe131656f44180 100644
--- a/common/board_r.c
+++ b/common/board_r.c
@@ -652,11 +652,11 @@ static init_fnc_t init_sequence_r[] = {
 	serial_initialize,
 	initr_announce,
 	dm_announce,
+	arch_initr_trap,
 #if CONFIG_IS_ENABLED(WDT)
 	initr_watchdog,
 #endif
 	INIT_FUNC_WATCHDOG_RESET
-	arch_initr_trap,
 #if defined(CONFIG_BOARD_EARLY_INIT_R)
 	board_early_init_r,
 #endif

---
base-commit: 064556910e61044f1295162ceaad600582b66cda
change-id: 20250218-init-dab1fc72abd2

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

