From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 20 Dec 2024 11:37:52 +0100
Subject: [PATCH v2 2/4] powerpc: mpc83xx: Allow including initreg.h into
 multiple files
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241220-mpc83xx-misc-v2-2-ff4c17ee5fa4@posteo.net>
References: <20241220-mpc83xx-misc-v2-0-ff4c17ee5fa4@posteo.net>
In-Reply-To: <20241220-mpc83xx-misc-v2-0-ff4c17ee5fa4@posteo.net>
To: Mario Six <mario.six@gdsys.cc>, Tom Rini <trini@konsulko.com>
Cc: Sinan Akman <sinan@writeme.com>, u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734691081; l=1760;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=q1aGlwVySHapcSK9VkUtvogioI7EimJ3UdYBFYbqTVw=;
 b=1UyAoOOe3iik9JLSooPLHOgljL7NDG4YSHeMXytOB004rA1hRqqMjEnhEnF3qWlqHhLmdjlEi
 gagVHVbFGVgDdrOZUg2dc+aEeWwJO7h5Xg6oZ/nymqO/cJHCcz7slSv
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Globals defined in headers can result in multiple-definition errors
while linking, if they are visible beyond the current translation unit.

This hasn't been a problem for initreg.h so far, but would become a
problem in the next patch, where I use a constant from initreg.h in a
second C file.

Reviewed-by: Sinan Akman <sinan@writeme.com>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

v2:
- Clarify when the visibility issue becomes a problem
---
 arch/powerpc/cpu/mpc83xx/initreg/initreg.h | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/powerpc/cpu/mpc83xx/initreg/initreg.h b/arch/powerpc/cpu/mpc83xx/initreg/initreg.h
index 63aa5c946696ee0368bb3453b40ff0110f0fbcfd..ea1176e7fe10dbb549125ab6b2706fee05a92734 100644
--- a/arch/powerpc/cpu/mpc83xx/initreg/initreg.h
+++ b/arch/powerpc/cpu/mpc83xx/initreg/initreg.h
@@ -13,7 +13,7 @@
 #define SPCR_TSECBDP_MASK	0x00000C00
 #define SPCR_TSECEP_MASK	0x00000300
 
-	const __be32 spcr_mask =
+	static const __be32 spcr_mask =
 #if defined(CONFIG_SPCR_OPT) && !defined(CONFIG_SPCR_OPT_UNSET)
 		SPCR_OPT_MASK |
 #endif
@@ -27,7 +27,7 @@
 		SPCR_TSEC2EP_MASK |
 #endif
 		0;
-	const __be32 spcr_val =
+	static const __be32 spcr_val =
 #if defined(CONFIG_SPCR_OPT) && !defined(CONFIG_SPCR_OPT_UNSET)
 		CONFIG_SPCR_OPT |
 #endif
@@ -42,7 +42,7 @@
 #endif
 		0;
 
-	const __be32 lcrr_mask =
+	static const __be32 lcrr_mask =
 #if defined(CONFIG_LCRR_DBYP) && !defined(CONFIG_LCRR_DBYP_UNSET)
 		LCRR_DBYP |
 #endif
@@ -60,7 +60,7 @@
 #endif
 		0;
 
-	const __be32 lcrr_val =
+	static const __be32 lcrr_val =
 #if defined(CONFIG_LCRR_DBYP) && !defined(CONFIG_LCRR_DBYP_UNSET)
 		CONFIG_LCRR_DBYP |
 #endif

-- 
2.45.2

