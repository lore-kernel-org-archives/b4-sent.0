From: Manas <manas18244@iiitd.ac.in>
Date: Fri, 04 Oct 2024 18:35:53 +0530
Subject: [PATCH v2] Fixes: null pointer dereference in
 pfnmap_lockdep_assert
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241004-fix-null-deref-v2-1-23ad90999cd1@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIADDo/2YC/3WMywrCMBAAf6Xs2S151Iqe+h/SQ0w2dqGkktRQK
 fl3Y+8eZ2Bmh0SRKcGt2SFS5sRLqKBODdjJhCchu8qghOqkEBo9bxje84yOInnsH94IrS/krYY
 avark7Rjex8oTp3WJn+Of5c/+XWWJEoXpzs5fnZC9GZh5da2xLQcYSylfcLqDk64AAAA=
To: Andrew Morton <akpm@linux-foundation.org>
Cc: Peter Xu <peterx@redhat.com>, Shuah Khan <skhan@linuxfoundation.org>, 
 Anup Sharma <anupnewsmail@gmail.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+093d096417e7038a689b@syzkaller.appspotmail.com, 
 Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728047161; l=1777;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=OEwuLRIdbf6uWYdfndo9PjGAmtyN4VZDWmzer8sLYJ8=;
 b=W2C+cObLrtqqTQu9dKflHQD9t3M4Uc2SCrH7g/8NavfEy9xgTNmwfI3B7b6NGxEDyfpNY9+cG
 h6QICQmopUsB4nmk6WjMlgRk/+afkoAWTEZ1bWxFF4UeeekxbyAp8Ag
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

syzbot has pointed to a possible null pointer dereference in
pfnmap_lockdep_assert. vm_file member of vm_area_struct is being
dereferenced without any checks.

This fix returns if vm_file member in vm_area_struct is NULL.

Reported-by: syzbot+093d096417e7038a689b@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=093d096417e7038a689b
---
This bug[1] triggers a general protection fault in follow_pfnmap_start
function. An assertion pfnmap_lockdep_assert inside this function
dereferences vm_file member of vm_area_struct. And panic gets triggered
when vm_file is NULL.

This patch returns from the assertion pfnmap_lockdep_assert if vm_file
is found to be NULL.

[1] https://syzkaller.appspot.com/bug?extid=093d096417e7038a689b

Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
Changes in v2:
- v2: use ternary operator according to feedback
- Link to v1: https://lore.kernel.org/r/20241003-fix-null-deref-v1-1-0a45df9d016a@iiitd.ac.in
---
 mm/memory.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/mm/memory.c b/mm/memory.c
index 2366578015ad..5ed109a8f02e 100644
--- a/mm/memory.c
+++ b/mm/memory.c
@@ -6346,7 +6346,7 @@ static inline void pfnmap_args_setup(struct follow_pfnmap_args *args,
 static inline void pfnmap_lockdep_assert(struct vm_area_struct *vma)
 {
 #ifdef CONFIG_LOCKDEP
-	struct address_space *mapping = vma->vm_file->f_mapping;
+	struct address_space *mapping = vma->vm_file ? vma->vm_file->f_mapping : NULL;
 
 	if (mapping)
 		lockdep_assert(lockdep_is_held(&vma->vm_file->f_mapping->i_mmap_rwsem) ||

---
base-commit: 9852d85ec9d492ebef56dc5f229416c925758edc
change-id: 20241003-fix-null-deref-6bfa0337efc3

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

