From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 30 Mar 2024 10:57:37 +0100
Subject: [PATCH 01/10] sparc64: Fix prototype warning for init_vdso_image
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240330-sparc64-warnings-v1-1-37201023ee2f@ravnborg.org>
References: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
In-Reply-To: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=1128;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=N9b4/JHlSvx7NLzDXct2fVraabjc7Gt8Q7BQyF6OslM=;
 b=pqCSBh8K2ae9bOOHPujcfnCWfW2c5NPkgwVpUmfkAUcvddT2O83UJiZhFCoDwOvrMIzqVXWX7XJB
 OCUNfTFQDk483lfMK9cJTCWlpEz4kMSy069ZmTRUAiKTkt+BsfeR
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warning:
arch/sparc/vdso/vma.c:246:12: warning: no previous prototype for ‘init_vdso_image’

init_vdso_image has no users outside vma.c, make it static.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 arch/sparc/vdso/vma.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/arch/sparc/vdso/vma.c b/arch/sparc/vdso/vma.c
index 1bbf4335de45..bab7a59575e8 100644
--- a/arch/sparc/vdso/vma.c
+++ b/arch/sparc/vdso/vma.c
@@ -243,8 +243,9 @@ static int stick_patch(const struct vdso_image *image, struct vdso_elfinfo *e, b
  * Allocate pages for the vdso and vvar, and copy in the vdso text from the
  * kernel image.
  */
-int __init init_vdso_image(const struct vdso_image *image,
-			   struct vm_special_mapping *vdso_mapping, bool elf64)
+static int __init init_vdso_image(const struct vdso_image *image,
+				  struct vm_special_mapping *vdso_mapping,
+				  bool elf64)
 {
 	int cnpages = (image->size) / PAGE_SIZE;
 	struct page *dp, **dpp = NULL;

-- 
2.34.1

