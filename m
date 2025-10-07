From: Ali Khan <abdulalikhan1337@gmail.com>
Date: Tue, 07 Oct 2025 12:53:09 +0000
Subject: [PATCH] ARM: OMAP2+: Fix falg->flag typo in omap_smc2()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251007-omap-falg-fix-v1-1-545a1de74a0a@gmail.com>
X-B4-Tracking: v=1; b=H4sIADQN5WgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDAwNz3fzcxALdtMScdN20zArd5ERD0zRDY7NkE0MzJaCegqJUoDDYvOj
 Y2loA1fbSbV8AAAA=
To: Aaro Koskinen <aaro.koskinen@iki.fi>, 
 Andreas Kemnade <andreas@kemnade.info>, Kevin Hilman <khilman@baylibre.com>, 
 Roger Quadros <rogerq@kernel.org>, Tony Lindgren <tony@atomide.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-omap@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Jens Schleusener <Jens.Schleusener@fossies.org>, 
 Ali Khan <abdulalikhan1337@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759841606; l=1869;
 i=abdulalikhan1337@gmail.com; s=20251007; h=from:subject:message-id;
 bh=LO4l4xtXGeg/5kuikNmT+7wW9ZSxcTZ7VwPYOe2JJsc=;
 b=X2XrdnImlsmvmIP+rT9bIf5q8oh9/l/ssN5g7kMwZcb9W2GPAp/bQU6mmsmOCgNYJcnpOYrMR
 zpTqzrk9+cPCmAjP4dclW02HoeYB1Lx2r4qXbIEO9HAdqXxIGuMrSNd
X-Developer-Key: i=abdulalikhan1337@gmail.com; a=ed25519;
 pk=MGvpDjvgp0SIh0jkqpHnh8BE7tUnGwAv3jhzd3o/xS4=
X-Endpoint-Received: by B4 Relay for abdulalikhan1337@gmail.com/20251007 with auth_id=538
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a spelling error in the omap_smc2() function declaration
and in a corresponding comment within the assembly source.
This was reported via bugzilla in 2019.

Reported-by: Jens Schleusener <Jens.Schleusener@fossies.org>
Link: https://bugzilla.kernel.org/show_bug.cgi?id=205891
Signed-off-by: Ali Khan <abdulalikhan1337@gmail.com>
---
 arch/arm/mach-omap2/omap-secure.h | 2 +-
 arch/arm/mach-omap2/omap-smc.S    | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm/mach-omap2/omap-secure.h b/arch/arm/mach-omap2/omap-secure.h
index 2517c4a5a0e2..04b4ba0f59ab 100644
--- a/arch/arm/mach-omap2/omap-secure.h
+++ b/arch/arm/mach-omap2/omap-secure.h
@@ -68,7 +68,7 @@ extern u32 omap_secure_dispatcher(u32 idx, u32 flag, u32 nargs,
 				u32 arg1, u32 arg2, u32 arg3, u32 arg4);
 extern void omap_smccc_smc(u32 fn, u32 arg);
 extern void omap_smc1(u32 fn, u32 arg);
-extern u32 omap_smc2(u32 id, u32 falg, u32 pargs);
+extern u32 omap_smc2(u32 id, u32 flag, u32 pargs);
 extern u32 omap_smc3(u32 id, u32 process, u32 flag, u32 pargs);
 extern int omap_secure_ram_reserve_memblock(void);
 extern u32 save_secure_ram_context(u32 args_pa);
diff --git a/arch/arm/mach-omap2/omap-smc.S b/arch/arm/mach-omap2/omap-smc.S
index 7376f528034d..fe3b5478200a 100644
--- a/arch/arm/mach-omap2/omap-smc.S
+++ b/arch/arm/mach-omap2/omap-smc.S
@@ -32,7 +32,7 @@ ENTRY(_omap_smc1)
 ENDPROC(_omap_smc1)
 
 /**
- * u32 omap_smc2(u32 id, u32 falg, u32 pargs)
+ * u32 omap_smc2(u32 id, u32 flag, u32 pargs)
  * Low level common routine for secure HAL and PPA APIs.
  * @id: Application ID of HAL APIs
  * @flag: Flag to indicate the criticality of operation

---
base-commit: 07e27ad16399afcd693be20211b0dfae63e0615f
change-id: 20251007-omap-falg-fix-ca15f136c416

Best regards,
-- 
Ali Khan <abdulalikhan1337@gmail.com>

