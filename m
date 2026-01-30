From: Ivan Babrou <ivan@cloudflare.com>
Date: Thu, 29 Jan 2026 20:50:09 -0800
Subject: [PATCH] kallsyms: cache bpf symbols to avoid quadratic iteration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260129-ivan-bpf-ksym-cache-v1-1-ca503070dcc0@cloudflare.com>
X-B4-Tracking: v=1; b=H4sIAIA4fGkC/x3MMQqAMAxA0atIZgOaoaJXEYdYUxvEKi2IIr27x
 fEN/7+QJKokGKoXolya9AgFbV2B9RxWQV2KgRoyTUs96sUB59Phlp4dLVsv2HNnFnZEzhKU8oz
 i9P6v45TzB35OvodlAAAA
X-Change-ID: 20260129-ivan-bpf-ksym-cache-9a76daf22fc2
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, 
 John Fastabend <john.fastabend@gmail.com>, KP Singh <kpsingh@kernel.org>, 
 Stanislav Fomichev <sdf@fomichev.me>, Hao Luo <haoluo@google.com>, 
 Jiri Olsa <jolsa@kernel.org>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 kernel-team@cloudflare.com, Ivan Babrou <ivan@cloudflare.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769748610; l=6130;
 i=ivan@cloudflare.com; s=20260129; h=from:subject:message-id;
 bh=avRlwtbPUTu7O0+jWkoiT910bjkizQeh0wXWXc3nVW4=;
 b=N1IWMxMUHHUnVd74gRQtqU90xbq8LlA5QNfBpYnRDcSJeDfy0/LzjPA3aUcsvjjMXcnVNUvVA
 LvOtv03yHXTBJDElP+93zIL3yRyP0Bb8R8YpGtMJ1mmWTtg0BAJoDiS
X-Developer-Key: i=ivan@cloudflare.com; a=ed25519;
 pk=QuczbiE/RJ0pw+SbDTjDyQUEsdy0dZym4mt+5Rp7PtA=
X-Endpoint-Received: by B4 Relay for ivan@cloudflare.com/20260129 with auth_id=621
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The existing code iterates the whole list of bpf ksyms until the right
one is found, which means quadratic complexity on top of linked list
pointer chasing under rcu. This is't noticeable for most installations,
but when one has 10000 bpf programs loaded, things start to add up and
reading from `/proc/kallsyms` slows down a lot.

Instead of doing that, we can cache the list of bpf symbols in linear
time when `/proc/kallsyms` is opened, which makes the whole thing fast.

Reading `/proc/kallsyms` on Apple M3 Pro in a VM and measuring system time:

Before:
* 15 bpf symbols: ~35ms
* 10015 bpf symbols: ~1250ms

After:
* 15 bpf symbols: ~35ms
* 10015 bpf symbols: ~50ms

Testing in production on v6.12 series (with ~10000 bpf ksyms as well):

* On AMD EPYC 9684X (Zen4): ~870ms -> ~100ms
* On Ampere Altra Max M128-30: ~4650ms -> ~70ms

Signed-off-by: Ivan Babrou <ivan@cloudflare.com>
---
 include/linux/filter.h | 16 ++++++++++++++++
 kernel/bpf/core.c      | 46 ++++++++++++++++++++++++++++++++++++++++++++++
 kernel/kallsyms.c      | 34 ++++++++++++++++++++++++++++++++--
 3 files changed, 94 insertions(+), 2 deletions(-)

diff --git a/include/linux/filter.h b/include/linux/filter.h
index 973233b82dc1..bbeef2d1b7f4 100644
--- a/include/linux/filter.h
+++ b/include/linux/filter.h
@@ -648,6 +648,11 @@ static inline bool insn_is_cast_user(const struct bpf_insn *insn)
 		offsetof(TYPE, MEMBER);						\
 	})
 
+struct bpf_ksym_cache_entry {
+	unsigned long value;
+	char name[KSYM_NAME_LEN];
+};
+
 /* A struct sock_filter is architecture independent. */
 struct compat_sock_fprog {
 	u16		len;
@@ -1378,6 +1383,9 @@ int __bpf_address_lookup(unsigned long addr, unsigned long *size,
 bool is_bpf_text_address(unsigned long addr);
 int bpf_get_kallsym(unsigned int symnum, unsigned long *value, char *type,
 		    char *sym);
+
+int bpf_get_all_kallsyms(struct bpf_ksym_cache_entry **cache_ptr,
+			 unsigned int *count_ptr);
 struct bpf_prog *bpf_prog_ksym_find(unsigned long addr);
 
 static inline int
@@ -1446,6 +1454,14 @@ static inline int bpf_get_kallsym(unsigned int symnum, unsigned long *value,
 	return -ERANGE;
 }
 
+static inline int bpf_get_all_kallsyms(struct bpf_ksym_cache_entry **cache_ptr,
+				       unsigned int *count_ptr)
+{
+	*cache_ptr = NULL;
+	*count_ptr = 0;
+	return 0;
+}
+
 static inline struct bpf_prog *bpf_prog_ksym_find(unsigned long addr)
 {
 	return NULL;
diff --git a/kernel/bpf/core.c b/kernel/bpf/core.c
index d595fe512498..4b04865441e0 100644
--- a/kernel/bpf/core.c
+++ b/kernel/bpf/core.c
@@ -806,6 +806,52 @@ int bpf_get_kallsym(unsigned int symnum, unsigned long *value, char *type,
 	return ret;
 }
 
+int bpf_get_all_kallsyms(struct bpf_ksym_cache_entry **cache_ptr,
+			 unsigned int *count_ptr)
+{
+	struct bpf_ksym_cache_entry *cache;
+	struct bpf_ksym *ksym;
+	unsigned int count = 0;
+	unsigned int i = 0;
+
+	if (!bpf_jit_kallsyms_enabled()) {
+		*cache_ptr = NULL;
+		*count_ptr = 0;
+		return 0;
+	}
+
+	rcu_read_lock();
+	list_for_each_entry_rcu(ksym, &bpf_kallsyms, lnode)
+		count++;
+	rcu_read_unlock();
+
+	if (count == 0) {
+		*cache_ptr = NULL;
+		*count_ptr = 0;
+		return 0;
+	}
+
+	cache = kvmalloc_array(count, sizeof(*cache), GFP_KERNEL);
+	if (!cache)
+		return -ENOMEM;
+
+	rcu_read_lock();
+	list_for_each_entry_rcu(ksym, &bpf_kallsyms, lnode) {
+		if (i >= count) {
+			/* List grew since we counted, oh well */
+			break;
+		}
+		strscpy(cache[i].name, ksym->name, KSYM_NAME_LEN);
+		cache[i].value = ksym->start;
+		i++;
+	}
+	rcu_read_unlock();
+
+	*cache_ptr = cache;
+	*count_ptr = i;
+	return 0;
+}
+
 int bpf_jit_add_poke_descriptor(struct bpf_prog *prog,
 				struct bpf_jit_poke_descriptor *poke)
 {
diff --git a/kernel/kallsyms.c b/kernel/kallsyms.c
index 1e7635864124..a41706a0b298 100644
--- a/kernel/kallsyms.c
+++ b/kernel/kallsyms.c
@@ -563,6 +563,8 @@ struct kallsym_iter {
 	char module_name[MODULE_NAME_LEN];
 	int exported;
 	int show_value;
+	struct bpf_ksym_cache_entry *bpf_cache;
+	unsigned int bpf_cache_count;
 };
 
 static int get_ksymbol_mod(struct kallsym_iter *iter)
@@ -600,11 +602,27 @@ static int get_ksymbol_ftrace_mod(struct kallsym_iter *iter)
 
 static int get_ksymbol_bpf(struct kallsym_iter *iter)
 {
+	unsigned int index = iter->pos - iter->pos_ftrace_mod_end;
 	int ret;
 
+	if (iter->bpf_cache) {
+		if (index >= iter->bpf_cache_count) {
+			iter->pos_bpf_end = iter->pos;
+			return 0;
+		}
+
+		strscpy(iter->module_name, "bpf", MODULE_NAME_LEN);
+		iter->exported = 0;
+		strscpy(iter->name, iter->bpf_cache[index].name, KSYM_NAME_LEN);
+		iter->value = iter->bpf_cache[index].value;
+		iter->type = BPF_SYM_ELF_TYPE;
+
+		return 1;
+	}
+
 	strscpy(iter->module_name, "bpf", MODULE_NAME_LEN);
 	iter->exported = 0;
-	ret = bpf_get_kallsym(iter->pos - iter->pos_ftrace_mod_end,
+	ret = bpf_get_kallsym(index,
 			      &iter->value, &iter->type,
 			      iter->name);
 	if (ret < 0) {
@@ -859,9 +877,21 @@ static int kallsyms_open(struct inode *inode, struct file *file)
 	 * the result here at open time.
 	 */
 	iter->show_value = kallsyms_show_value(file->f_cred);
+
+	bpf_get_all_kallsyms(&iter->bpf_cache, &iter->bpf_cache_count);
+
 	return 0;
 }
 
+static int kallsyms_release(struct inode *inode, struct file *file)
+{
+	struct seq_file *m = file->private_data;
+	struct kallsym_iter *iter = m->private;
+
+	kvfree(iter->bpf_cache);
+	return seq_release_private(inode, file);
+}
+
 #ifdef	CONFIG_KGDB_KDB
 const char *kdb_walk_kallsyms(loff_t *pos)
 {
@@ -886,7 +916,7 @@ static const struct proc_ops kallsyms_proc_ops = {
 	.proc_open	= kallsyms_open,
 	.proc_read	= seq_read,
 	.proc_lseek	= seq_lseek,
-	.proc_release	= seq_release_private,
+	.proc_release	= kallsyms_release,
 };
 
 static int __init kallsyms_init(void)

---
base-commit: 7d0a66e4bb9081d75c82ec4957c50034cb0ea449
change-id: 20260129-ivan-bpf-ksym-cache-9a76daf22fc2

Best regards,
-- 
Ivan Babrou <ivan@cloudflare.com>

