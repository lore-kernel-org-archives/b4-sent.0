From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 10 Feb 2023 17:56:28 -0600
Subject: [PATCH] powerpc/machdep: warn when machine_is() used too early
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230210-warn-on-machine-is-before-probe-machine-v1-1-f0cba57125fb@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAKvZ5mMC/z2OQQrCMBBFr1Jm7UCSWgSvIi5m4sRk0UmZiBVK7
 27qwuX7Dx5/gyZWpMF12MDkXVqp2sGfBoiZ9ClYHp0huDC64B2uZIpVcaaYi3bdkCVVE1yssvz
 38TL5iX06j8zQa0xNkI005qM3U3uJHWIxSeXzu3C77/sXMDRAapIAAAA=
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1676073398; l=1645;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=+nyHN6/MED0UH3QD0vMZ7Uax/BGz0rKLjziCR5coDn4=;
 b=X6JG9xjRueGPp34qaW0+pNjdEnkRZnVpkuriT6oXvbLytM+DCQdowAvmDaymtSd2OpYi+/AsS
 P99hy4AUAUoCl6xxAdf1kM4LCIZfeaCZydWJr2DcX7OadRYYx+7oowA
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

machine_is() can't provide correct results before probe_machine() has
run. Warn when it's used too early in boot.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
Prompted by my attempts to do some pseries-specific setup during
rtas_initialize() and being puzzled for a while that it wasn't
working.
---
 arch/powerpc/include/asm/machdep.h | 12 +++++++-----
 1 file changed, 7 insertions(+), 5 deletions(-)

diff --git a/arch/powerpc/include/asm/machdep.h b/arch/powerpc/include/asm/machdep.h
index 378b8d5836a7..8c0a799d18cd 100644
--- a/arch/powerpc/include/asm/machdep.h
+++ b/arch/powerpc/include/asm/machdep.h
@@ -220,11 +220,13 @@ extern struct machdep_calls *machine_id;
 	EXPORT_SYMBOL(mach_##name);				\
 	struct machdep_calls mach_##name __machine_desc =
 
-#define machine_is(name) \
-	({ \
-		extern struct machdep_calls mach_##name \
-			__attribute__((weak));		 \
-		machine_id == &mach_##name; \
+#define machine_is(name)                                            \
+	({                                                          \
+		extern struct machdep_calls mach_##name             \
+			__attribute__((weak));                      \
+		WARN(!machine_id,                                   \
+		     "machine_is() called before probe_machine()"); \
+		machine_id == &mach_##name;                         \
 	})
 
 static inline void log_error(char *buf, unsigned int err_type, int fatal)

---
base-commit: 0bfb97203f5f300777624a2ad6f8f84aea3e8658
change-id: 20230210-warn-on-machine-is-before-probe-machine-37515b1f43bb

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

