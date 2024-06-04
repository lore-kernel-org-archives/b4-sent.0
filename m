From: Joel Granados <j.granados@samsung.com>
Date: Tue, 04 Jun 2024 08:29:23 +0200
Subject: [PATCH 5/8] sysctl: Remove superfluous empty allocations from
 sysctl internals
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240604-jag-sysctl_remset-v1-5-2df7ecdba0bd@samsung.com>
References: <20240604-jag-sysctl_remset-v1-0-2df7ecdba0bd@samsung.com>
In-Reply-To: <20240604-jag-sysctl_remset-v1-0-2df7ecdba0bd@samsung.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Will Deacon <will@kernel.org>, Waiman Long <longman@redhat.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Suren Baghdasaryan <surenb@google.com>, 
 Kent Overstreet <kent.overstreet@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Luis Chamberlain <mcgrof@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Joel Granados <j.granados@samsung.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 linux-fsdevel@vger.kernel.org, netdev@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1905;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=dykX5g3MqGx15MATEKwwLa2ClmbIRatln9uC2eazckc=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZetGR3E2qjUjAS4q9w+HjZ+miKQrmluWXXn
 C0vkfATqOvX1okBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmXrRkAAoJELqXzVK3
 lkFPwCwL/jqnIEcEWutsOWB1UQTKFkNA7cz4uGlz1RuXDsLJxTehHd+yxHkXH/uC4QSeWlaJMhI
 y/M6hBaSMqyknpSMeXjgwML0myqcwanvUI52qQez7GuzEmaMStbuewJp4fIOopCHSV3fAefx++0
 OYitv3k2B/txIQBpMqoHWgB9DejZcZzzB/KygVZrRs/vDrkWdIl5uMR3J/Ehw3MmcW+b2pU2os2
 pXUQCyBxpa+rOAvWTm7MXOBOHZJnXlIKajR4RLbfGSvkNXJfLmHwY4XuCv2N9BXGX0RgCoMEYSM
 C5UiFki4U0ojWqyKLxg5Lj8T0XgxNjRvgtXo/ao/vdejeY7STem/sCXWVka8SWuXRY2YAFfBlcr
 mU7T+yqjI8JVf6MTCkQYPk9ueo5YHbqWt+oGCXPDUfFfELnkSsWHAsH0S782t4zi4XrmyP3bUZ9
 KAkFDTj8PBaGvHxjxnIsU0ZxjNwxosVnynxuCAKNSU4szTgMzcl76Ck2/It8V8v3qnnHktCQJU7
 uE=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the sentinels have been removed from ctl_table arrays, there is
no need to artificially append empty ctl_table elements at ctl_table
registration. Remove superfluous empty allocation from new_dir and
new_links.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 fs/proc/proc_sysctl.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/fs/proc/proc_sysctl.c b/fs/proc/proc_sysctl.c
index 1babb54347a4..29d40f0ff3ff 100644
--- a/fs/proc/proc_sysctl.c
+++ b/fs/proc/proc_sysctl.c
@@ -951,14 +951,14 @@ static struct ctl_dir *new_dir(struct ctl_table_set *set,
 	char *new_name;
 
 	new = kzalloc(sizeof(*new) + sizeof(struct ctl_node) +
-		      sizeof(struct ctl_table)*2 +  namelen + 1,
+		      sizeof(struct ctl_table) +  namelen + 1,
 		      GFP_KERNEL);
 	if (!new)
 		return NULL;
 
 	node = (struct ctl_node *)(new + 1);
 	table = (struct ctl_table *)(node + 1);
-	new_name = (char *)(table + 2);
+	new_name = (char *)(table + 1);
 	memcpy(new_name, name, namelen);
 	table[0].procname = new_name;
 	table[0].mode = S_IFDIR|S_IRUGO|S_IXUGO;
@@ -1163,7 +1163,7 @@ static struct ctl_table_header *new_links(struct ctl_dir *dir, struct ctl_table_
 
 	links = kzalloc(sizeof(struct ctl_table_header) +
 			sizeof(struct ctl_node)*head->ctl_table_size +
-			sizeof(struct ctl_table)*(head->ctl_table_size + 1) +
+			sizeof(struct ctl_table)*head->ctl_table_size +
 			name_bytes,
 			GFP_KERNEL);
 
@@ -1172,7 +1172,7 @@ static struct ctl_table_header *new_links(struct ctl_dir *dir, struct ctl_table_
 
 	node = (struct ctl_node *)(links + 1);
 	link_table = (struct ctl_table *)(node + head->ctl_table_size);
-	link_name = (char *)&link_table[head->ctl_table_size + 1];
+	link_name = (char *)(link_table + head->ctl_table_size);
 	link = link_table;
 
 	list_for_each_table_entry(entry, head) {

-- 
2.43.0

