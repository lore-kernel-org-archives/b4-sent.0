From: Koakuma <koachan@protonmail.com>
Date: Mon, 09 Jun 2025 20:53:11 +0700
Subject: [PATCH 1/2] sparc/module: Add R_SPARC_UA64 relocation handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250609-b4-sparc-relocs-v1-1-aa52631735af@protonmail.com>
References: <20250609-b4-sparc-relocs-v1-0-aa52631735af@protonmail.com>
In-Reply-To: <20250609-b4-sparc-relocs-v1-0-aa52631735af@protonmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <nick.desaulniers+lkml@gmail.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: sparclinux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, Koakuma <koachan@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749477207; l=1232;
 i=koachan@protonmail.com; s=20240620; h=from:subject:message-id;
 bh=zZw7JuY1ThhmEZ0ymDbJ7RVlj2O2wrZSNN0ELhatlwE=;
 b=pHlzGFwzlR+zbyyljMmoJCIWTRSZ1KYty5KLvm70wsrv8QhaNHteqxP6kWlGWfp2pGhYWm5bF
 YgNEPBUbhgXBD3RU8jEfojmrWWyKjf72glTLmx/evMhRBhF2V5aqBCf
X-Developer-Key: i=koachan@protonmail.com; a=ed25519;
 pk=UA59FS3yiAA1cnAAUZ1rehTmr6skh95PgkNRBLcoKCg=
X-Endpoint-Received: by B4 Relay for koachan@protonmail.com/20240620 with auth_id=174
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is needed so that the kernel can handle R_SPARC_UA64 relocations,
which is emitted by LLVM's IAS.

Signed-off-by: Koakuma <koachan@protonmail.com>
---
 arch/sparc/include/asm/elf_64.h | 1 +
 arch/sparc/kernel/module.c      | 1 +
 2 files changed, 2 insertions(+)

diff --git a/arch/sparc/include/asm/elf_64.h b/arch/sparc/include/asm/elf_64.h
index 8fb09eec8c3e796a9a79aa0a7877842ceb7ea6d3..694ed081cf8d99adf70be25e5dc0e30a45f70398 100644
--- a/arch/sparc/include/asm/elf_64.h
+++ b/arch/sparc/include/asm/elf_64.h
@@ -58,6 +58,7 @@
 #define R_SPARC_7		43
 #define R_SPARC_5		44
 #define R_SPARC_6		45
+#define R_SPARC_UA64		54
 
 /* Bits present in AT_HWCAP, primarily for Sparc32.  */
 #define HWCAP_SPARC_FLUSH       0x00000001
diff --git a/arch/sparc/kernel/module.c b/arch/sparc/kernel/module.c
index b8c51cc23d96944037494f13d2d65a43bb187729..6e3d4dde4f9ab33040b300c40d5fd5d0584e166d 100644
--- a/arch/sparc/kernel/module.c
+++ b/arch/sparc/kernel/module.c
@@ -87,6 +87,7 @@ int apply_relocate_add(Elf_Shdr *sechdrs,
 			break;
 #ifdef CONFIG_SPARC64
 		case R_SPARC_64:
+		case R_SPARC_UA64:
 			location[0] = v >> 56;
 			location[1] = v >> 48;
 			location[2] = v >> 40;

-- 
2.49.0

