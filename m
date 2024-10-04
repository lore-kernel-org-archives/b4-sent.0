From: Manas <manas18244@iiitd.ac.in>
Date: Fri, 04 Oct 2024 23:12:16 +0530
Subject: [PATCH v4] Fixes: null pointer dereference in
 pfnmap_lockdep_assert
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241004-fix-null-deref-v4-1-d0a8ec01ac85@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAPcoAGcC/33MSwrCMBSF4a1Ixqbk1cp15D7EQZqHvVBSSWqol
 O7dtCOl6PA/cL6ZJBfRJXI+zCS6jAmHUEIdD8R0OtwdRVuaCCYUZ0xSjxMNz76n1kXnadN6zaQ
 8OW8kKadHGXHawOutdIdpHOJr8zNf159U5pRTplVtPVjGG31BxNFW2lQYyIpl8QmoHSAKIKS2w
 ADAWL4H5H9AFsCDqqHlxkDtv4FlWd4ZavzqMAEAAA==
To: Andrew Morton <akpm@linux-foundation.org>
Cc: Peter Xu <peterx@redhat.com>, Shuah Khan <skhan@linuxfoundation.org>, 
 Anup Sharma <anupnewsmail@gmail.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+093d096417e7038a689b@syzkaller.appspotmail.com, 
 Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728063737; l=2269;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=I6Jr34YY5WytSnppfZbbp0DlHGTntvqBvZhYI28pyh8=;
 b=ME9HVvF5BLf+ljmXjMr9EboNjFIhb6RD+gVbB7g2RRx5amHDSoLOzjd2z8J/zMByP+poVufwN
 wdbqRHYDoPoD+JIj9naERulOdKx0/x45vCt8hXKnMzwqnZDLR/Z1MRA
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

syzbot has pointed to a possible null pointer dereference in
pfnmap_lockdep_assert. vm_file member of vm_area_struct is being
dereferenced without any checks.

This fix assigns mapping only if vm_file is not NULL.

Reported-by: syzbot+093d096417e7038a689b@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=093d096417e7038a689b
---
This bug[1] triggers a general protection fault in follow_pfnmap_start
function. An assertion pfnmap_lockdep_assert inside this function
dereferences vm_file member of vm_area_struct. And panic gets triggered
when vm_file is NULL.

This patch assigns mapping only if vm_file is not NULL.

[1] https://syzkaller.appspot.com/bug?extid=093d096417e7038a689b

Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
Changes in v4:
- v4: simplify ternary conditional
- Link to v3: https://lore.kernel.org/r/20241004-fix-null-deref-v3-1-f9459b1cc95f@iiitd.ac.in

Changes in v3:
- v3: use assigned var instead of accessing member again 
- Link to v2: https://lore.kernel.org/r/20241004-fix-null-deref-v2-1-23ad90999cd1@iiitd.ac.in

Changes in v2:
- v2: use ternary operator according to feedback
- Link to v1: https://lore.kernel.org/r/20241003-fix-null-deref-v1-1-0a45df9d016a@iiitd.ac.in
---
 mm/memory.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/mm/memory.c b/mm/memory.c
index 2366578015ad..4e4d598496a8 100644
--- a/mm/memory.c
+++ b/mm/memory.c
@@ -6346,10 +6346,13 @@ static inline void pfnmap_args_setup(struct follow_pfnmap_args *args,
 static inline void pfnmap_lockdep_assert(struct vm_area_struct *vma)
 {
 #ifdef CONFIG_LOCKDEP
-	struct address_space *mapping = vma->vm_file->f_mapping;
+	struct address_space *mapping = NULL;
+
+	if (vma->vm_file)
+		mapping = vma->vm_file->f_mapping;
 
 	if (mapping)
-		lockdep_assert(lockdep_is_held(&vma->vm_file->f_mapping->i_mmap_rwsem) ||
+		lockdep_assert(lockdep_is_held(&mapping->i_mmap_rwsem) ||
 			       lockdep_is_held(&vma->vm_mm->mmap_lock));
 	else
 		lockdep_assert(lockdep_is_held(&vma->vm_mm->mmap_lock));

---
base-commit: 9852d85ec9d492ebef56dc5f229416c925758edc
change-id: 20241003-fix-null-deref-6bfa0337efc3

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

