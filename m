From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 29 Nov 2024 20:42:28 +0100
Subject: [PATCH 1/2] clk: mpc83xx: Fix typo in "Coherent System Bus"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241129-typo-v1-1-1ac3fef74eee@posteo.net>
References: <20241129-typo-v1-0-1ac3fef74eee@posteo.net>
In-Reply-To: <20241129-typo-v1-0-1ac3fef74eee@posteo.net>
To: Mario Six <mario.six@gdsys.cc>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732909355; l=748;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=d1Imfeaz4mmEu1sdX3Ph06IdWoxZEdhIx3m0qbtgCfM=;
 b=LQ5Kp2MuI9bS+EQwehlTjN/qI/Cgl/84DfOtQp51ryVLtEq48CKlSeVvf9iE+VG6gzvzydwDk
 EwTbbh8p9YJAoVH6l3sLegMdY6WAefyy+t83arkOHhP4vR5atsPbIK9
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cosmetic change.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/clk/mpc83xx_clk.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/mpc83xx_clk.h b/drivers/clk/mpc83xx_clk.h
index c06a51ecd43a426e8ecd4e99a3f8ff3e902f9106..6b74fc5f16b613cec4fbc654644835fbc0dfe3eb 100644
--- a/drivers/clk/mpc83xx_clk.h
+++ b/drivers/clk/mpc83xx_clk.h
@@ -321,7 +321,7 @@ static inline u32 get_pci_sync_in(immap_t *im)
 }
 
 /**
- * get_csb_clk() - Read the CSB (Coheren System Bus) clock speed
+ * get_csb_clk() - Read the CSB (Coherent System Bus) clock speed
  * @im: Pointer to the MPC83xx main register map in question
  *
  * Return: The CSB clock speed value as a 32-bit number.

-- 
2.45.2

