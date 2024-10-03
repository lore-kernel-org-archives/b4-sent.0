From: Manas <manas18244@iiitd.ac.in>
Date: Thu, 03 Oct 2024 21:31:06 +0530
Subject: [PATCH] Fixes: null pointer dereference in pfnmap_lockdep_assert
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241003-fix-null-deref-v1-1-0a45df9d016a@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAMG//mYC/x2MSQqAMAwAvyI5G4itKPgV8eCSaKBUaVEKxb9bP
 M7ATIbIQTnCUGUI/GjU0xdo6grWY/Y7o26FwZBpGyKLogn97RxuHFiwW2Qma3uW1UKJriI1/cN
 xet8Pec9y02AAAAA=
To: Andrew Morton <akpm@linux-foundation.org>
Cc: Peter Xu <peterx@redhat.com>, Shuah Khan <skhan@linuxfoundation.org>, 
 Anup Sharma <anupnewsmail@gmail.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+093d096417e7038a689b@syzkaller.appspotmail.com, 
 Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727971281; l=1475;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=x08Dt4D4CnyqFeKnwiqo7wiyGAvva8Affj+d/SXsW+A=;
 b=Cn/tYNqn5B45YcZhsFYQSPD2ldhhhYgc5XE7ctAhBQhf7vIsn/RfiuzQUe+wgjx4v745x3D2z
 V5tBTMz6vKHBV2y4fcqeEqW0KI/UyEl3xFgDdg3DkuZcC0lzWWna4zG
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
 mm/memory.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/mm/memory.c b/mm/memory.c
index 2366578015ad..b152a95e543f 100644
--- a/mm/memory.c
+++ b/mm/memory.c
@@ -6346,6 +6346,9 @@ static inline void pfnmap_args_setup(struct follow_pfnmap_args *args,
 static inline void pfnmap_lockdep_assert(struct vm_area_struct *vma)
 {
 #ifdef CONFIG_LOCKDEP
+	if (!vma->vm_file)
+		return;
+
 	struct address_space *mapping = vma->vm_file->f_mapping;
 
 	if (mapping)

---
base-commit: 9852d85ec9d492ebef56dc5f229416c925758edc
change-id: 20241003-fix-null-deref-6bfa0337efc3

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

