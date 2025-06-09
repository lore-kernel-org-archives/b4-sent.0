From: Koakuma <koachan@protonmail.com>
Date: Mon, 09 Jun 2025 20:53:12 +0700
Subject: [PATCH 2/2] sparc/module: Make it clear that relocation numbers
 are shown in hex
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250609-b4-sparc-relocs-v1-2-aa52631735af@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749477207; l=784;
 i=koachan@protonmail.com; s=20240620; h=from:subject:message-id;
 bh=7SKx1LyVSxb9rnPPXP8b4RhjM/ieyIDEQGTuXHHGuv0=;
 b=7wx6sVYWxVRMZKF1bCXsTh6PwiVpWEyHcpD7XVsKksAbsttXnXku6ruD/sZvYyV3JbeaW8z2W
 nVXopwnT6LFCTJSTfvAdw+TKa0kXc+dB2AxFV+Y5Uj9WJPMrNaP5xNS
X-Developer-Key: i=koachan@protonmail.com; a=ed25519;
 pk=UA59FS3yiAA1cnAAUZ1rehTmr6skh95PgkNRBLcoKCg=
X-Endpoint-Received: by B4 Relay for koachan@protonmail.com/20240620 with auth_id=174
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is to ease debugging by removing the ambiguity of the shown
number base.

Signed-off-by: Koakuma <koachan@protonmail.com>
---
 arch/sparc/kernel/module.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/sparc/kernel/module.c b/arch/sparc/kernel/module.c
index 6e3d4dde4f9ab33040b300c40d5fd5d0584e166d..49740450a6859fda566459ee4679869f9854b760 100644
--- a/arch/sparc/kernel/module.c
+++ b/arch/sparc/kernel/module.c
@@ -142,7 +142,7 @@ int apply_relocate_add(Elf_Shdr *sechdrs,
 			break;
 
 		default:
-			printk(KERN_ERR "module %s: Unknown relocation: %x\n",
+			printk(KERN_ERR "module %s: Unknown relocation: 0x%x\n",
 			       me->name,
 			       (int) (ELF_R_TYPE(rel[i].r_info) & 0xff));
 			return -ENOEXEC;

-- 
2.49.0

