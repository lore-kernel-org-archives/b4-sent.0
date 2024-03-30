From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 30 Mar 2024 10:57:43 +0100
Subject: [PATCH 07/10] sparc64: Fix prototype warnings in adi_64.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240330-sparc64-warnings-v1-7-37201023ee2f@ravnborg.org>
References: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
In-Reply-To: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=1998;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=4x3bdFE7JXKdL9191J0m+VT2gS8HRbYF0N4eZvrNsnU=;
 b=KqifCim/T+astHCsES+LmkrKBcWtdEitfmvxz1BoClBokgS1XQlcr/JHLjv9RGX/Od9w5o4aOkH0
 f0LJ8jV5CPZjNphmsQqyVbM3ErgZW6krl3I5AYTISzKCQum0oi8T
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warnings:
arch/sparc/kernel/adi_64.c:124:21: warning: no previous prototype for ‘find_tag_store’
arch/sparc/kernel/adi_64.c:156:21: warning: no previous prototype for ‘alloc_tag_store’
arch/sparc/kernel/adi_64.c:299:6: warning: no previous prototype for ‘del_tag_store’

None of the functions were used outside the file, so declare them static.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 arch/sparc/kernel/adi_64.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/arch/sparc/kernel/adi_64.c b/arch/sparc/kernel/adi_64.c
index ce332942de2d..e0e4fc527b24 100644
--- a/arch/sparc/kernel/adi_64.c
+++ b/arch/sparc/kernel/adi_64.c
@@ -121,9 +121,9 @@ void __init mdesc_adi_init(void)
 		mdesc_release(hp);
 }
 
-tag_storage_desc_t *find_tag_store(struct mm_struct *mm,
-				   struct vm_area_struct *vma,
-				   unsigned long addr)
+static tag_storage_desc_t *find_tag_store(struct mm_struct *mm,
+					  struct vm_area_struct *vma,
+					  unsigned long addr)
 {
 	tag_storage_desc_t *tag_desc = NULL;
 	unsigned long i, max_desc, flags;
@@ -153,9 +153,9 @@ tag_storage_desc_t *find_tag_store(struct mm_struct *mm,
 	return tag_desc;
 }
 
-tag_storage_desc_t *alloc_tag_store(struct mm_struct *mm,
-				    struct vm_area_struct *vma,
-				    unsigned long addr)
+static tag_storage_desc_t *alloc_tag_store(struct mm_struct *mm,
+					   struct vm_area_struct *vma,
+					   unsigned long addr)
 {
 	unsigned char *tags;
 	unsigned long i, size, max_desc, flags;
@@ -296,7 +296,7 @@ tag_storage_desc_t *alloc_tag_store(struct mm_struct *mm,
 	return tag_desc;
 }
 
-void del_tag_store(tag_storage_desc_t *tag_desc, struct mm_struct *mm)
+static void del_tag_store(tag_storage_desc_t *tag_desc, struct mm_struct *mm)
 {
 	unsigned long flags;
 	unsigned char *tags = NULL;

-- 
2.34.1

