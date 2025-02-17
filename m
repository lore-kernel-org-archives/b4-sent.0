From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Mon, 17 Feb 2025 16:48:48 +0100
Subject: [PATCH 2/2] powerpc: mpc8xxx_spi: Catch bad chip variants earlier
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250217-immap-size-v1-2-f9be2e9e7b1a@posteo.net>
References: <20250217-immap-size-v1-0-f9be2e9e7b1a@posteo.net>
In-Reply-To: <20250217-immap-size-v1-0-f9be2e9e7b1a@posteo.net>
To: Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739807332; l=899;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=5W7jFz6beA8z0UvlV/2wBUQm3SnOqHJ13+g3+6jkxJA=;
 b=7KiXl8HcXElruDRQtZri+d0+rX3Ge/7Q5+Y/Xibq8ylGCqZKsQ2eM4NnsZQZS6o3PJYSk1p9T
 Rx7ev36H+yhAHonmpX/lk8uRqOdbke4MPls96LLb6V5pEEu+uPiGYGg
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, enabling the MPC8xxx SPI driver on an unexpected SoC results
in a wall of errors because spi8xxx_t isn't defined. This is quite a bad
experience, so let's catch this kind of issue in mpc8xxx_spi.h.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/include/asm/mpc8xxx_spi.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/powerpc/include/asm/mpc8xxx_spi.h b/arch/powerpc/include/asm/mpc8xxx_spi.h
index 2b2095ad481d19a48e1f8d521626a0356773c0b5..3efd4bdcac2c3725a8065b3bb7faa11c78da0c78 100644
--- a/arch/powerpc/include/asm/mpc8xxx_spi.h
+++ b/arch/powerpc/include/asm/mpc8xxx_spi.h
@@ -28,6 +28,8 @@ typedef struct spi8xxx {
 } spi8xxx_t;
 static_assert(sizeof(spi8xxx_t) == 0x1000);
 
+#else
+#error "SPI register layout not defined: Unknown chip variant"
 #endif
 
 #endif	/* _ASM_MPC8XXX_SPI_H_ */

-- 
2.48.0.rc1.219.gb6b6757d772

