From: Alex Roberts <alex.roberts109@outlook.com>
Date: Thu, 11 Jun 2026 13:59:10 -0500
Subject: [PATCH] Add LoadPin support for eBPF program loading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260611-b4-rfc-loadpin-ebpf-v1-1-11a6c8e6170d@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNQQrCMBBFr1Jm7UBSaxCvIi4yk4kdCWlIrAild
 zfq8n1472/QpKo0uAwbVHlp0yV3sIcBePb5LqihM4xmdMZZizRhjYxp8aFoRqES0ZwdTzYIncw
 Rukm+CVL1mefu5jWlPpYqUd+/q+vtz22lh/Dz24d9/wBoSuMPjAAAAA==
X-Change-ID: 20260611-b4-rfc-loadpin-ebpf-086c41deb503
To: Kees Cook <kees@kernel.org>, Paul Moore <paul@paul-moore.com>, 
 James Morris <jmorris@namei.org>, "Serge E. Hallyn" <serge@hallyn.com>
Cc: linux-kernel@vger.kernel.org, linux-security-module@vger.kernel.org, 
 bpf@vger.kernel.org, Alexei Starovoitov <ast@kernel.org>, 
 KP Singh <kpsingh@kernel.org>, Alex Roberts <alex.roberts109@outlook.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6115;
 i=alex.roberts109@outlook.com; h=from:subject:message-id;
 bh=kja/4mgWlMnUqr7hZArx3pkWuFe/YGd2AE8OlioL1Yg=;
 b=owGbwMvMwCEWzZjUEpRpN5nxtFoSQ5Y2a1Py18mKdw6lNof73xXkv/9m/qsTW2v/MIZvU2wrS
 fmo4+3UUcrCIMbBICumyMKnyPP7sYle/asFy6Nh5rAygQxh4OIUgIkIrmZkmCmpFbGhfarsP8mL
 Gx9ynfE+kfGx+UXSqwYTw+15E3WtjRgZjvWZHJCX+HfK+2vSt7Ajv72Wa6s8dT2+o/LWF+OU115
 H2QE=
X-Developer-Key: i=alex.roberts109@outlook.com; a=openpgp;
 fpr=0E210CFBE3342E7FEAA0A75B5B01628452693E93
X-Endpoint-Received: by B4 Relay for alex.roberts109@outlook.com/default with auth_id=817
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add LoadPin LSM hook to bpf_prog_load to prevent loading of BPF
programs from untrusted filesystems

---
There have been several efforts to provide a trust mechanism for eBPF programs –
particularly in the form of a signed program. After many discussions, BPF
Signing became supported [1].

This patch series intends to provide an alternative trust mechanism for eBPF
programs using LoadPin and the LoadPin dm-verity support. The approach is to pin
eBPF userspace loaders to a single filesystem or to one or more dm-verity
integrity protected filesystems. This is similar to the existing  Loadpin+verity
implementation and approach of e.g., loading unsigned kernel modules or kexec
images from a pinned trusted filesystem [2].

When a userspace application attempts to load a BPF program, LoadPin
first checks whether the exe_file is located on the pinned root, if so
bpf_prog_load is allowed. Otherwise, Loadpin denies bpf_prog_load. Additionally,
if verity support is enabled, LoadPin determines whether the exe_file is located
on a verity backed device and whether the root digest of that device is in the
list of trusted digests. bpf_prog_load is allowed if the verity device has a
trusted root digest.

Background:
In a secure boot environment, secure boot can be extended to the root filesystem
by means of dm-verity. Placing userspace eBPF programs on trusted filesystems
and restricting their use to a trusted filesystem implicitly extends the trust
to the underlying BPF program itself, without having to sign the bytecode.
Rather than sign each program and load keys into the kernel keyring, it can be
sufficient to sign the filesystem.

Additional Considerations:
Because the userspace loader itself defines the filesystem to pin from, it
should be acknowledged that this does not necessarily solve the dynamically
generated eBPF usecase. For example, if the pinned filesystem includes bpftrace
or other userspace applications that dynamically generate and load eBPF
bytecode, this trust mechanism does not apply. But for systems that either
   1) remove/do-not-provide dynamically generating programs or
   2) loadpin filesystem(s) that exclude such programs,
then it can be reasoned that only trusted bytecode is loaded.

[1] https://git.kernel.org/pub/scm/linux/kernel/git/bpf/bpf-next.git/commit/?h=for-next&id=58a5820582e4c809dd26b3f2d396cf072411d6e8
[2] https://lore.kernel.org/lkml/20220517163437.v4.2.I01c67af41d2f6525c6d023101671d7339a9bc8b5@changeid/

Signed-off-by: Alex Roberts <alex.roberts109@outlook.com>
---
 include/linux/kernel_read_file.h |  1 +
 security/loadpin/Kconfig         | 12 ++++++++++++
 security/loadpin/loadpin.c       | 29 +++++++++++++++++++++++++++++
 3 files changed, 42 insertions(+)

diff --git a/include/linux/kernel_read_file.h b/include/linux/kernel_read_file.h
index d613a7b4dd35..75cbd514562f 100644
--- a/include/linux/kernel_read_file.h
+++ b/include/linux/kernel_read_file.h
@@ -15,6 +15,7 @@
 	id(POLICY, security-policy)		\
 	id(X509_CERTIFICATE, x509-certificate)	\
 	id(MODULE_COMPRESSED, kernel-module-compressed) \
+	id(EBPF, ebpf) \
 	id(MAX_ID, )
 
 #define __fid_enumify(ENUM, dummy) READING_ ## ENUM,
diff --git a/security/loadpin/Kconfig b/security/loadpin/Kconfig
index aef63d3e30df..be0754735d5d 100644
--- a/security/loadpin/Kconfig
+++ b/security/loadpin/Kconfig
@@ -42,3 +42,15 @@ config SECURITY_LOADPIN_VERITY
 
 	  This is followed by the verity digests, with one digest per
 	  line.
+
+config SECURITY_LOADPIN_EBPF
+	bool "Pin ebpf programs to one filesystem"
+	depends on SECURITY_LOADPIN
+	help
+	  eBPF program loading is pinned to the first filesystem from which the
+	  application loading the progam resides. When enabled, applications on
+	  other filesystems that attempt to load an eBPF program will be rejected.
+	  This is best used when applications that load eBPF programs reside on a
+	  read-only filesystem from which tools for dynamically generating eBPF
+	  programs such as bpftrace are not installed. This will not restrict the
+	  kernel from loading a bpf program.
\ No newline at end of file
diff --git a/security/loadpin/loadpin.c b/security/loadpin/loadpin.c
index f71861f98e1a..47fd7e247edb 100644
--- a/security/loadpin/loadpin.c
+++ b/security/loadpin/loadpin.c
@@ -23,6 +23,10 @@
 #include <uapi/linux/loadpin.h>
 #include <uapi/linux/lsm.h>
 
+#ifdef CONFIG_SECURITY_LOADPIN_EBPF
+#include <linux/bpf.h>
+#endif /* CONFIG_SECURITY_LOADPIN_BPF */
+
 #define VERITY_DIGEST_FILE_HEADER "# LOADPIN_TRUSTED_VERITY_ROOT_DIGESTS"
 
 static void report_load(const char *origin, struct file *file, char *operation)
@@ -204,6 +208,28 @@ static int loadpin_load_data(enum kernel_load_data_id id, bool contents)
 	return loadpin_check(NULL, (enum kernel_read_file_id) id);
 }
 
+#ifdef CONFIG_SECURITY_LOADPIN_EBPF
+static int loadpin_bpf_prog_load(struct bpf_prog *prog, union bpf_attr *attr,
+				  struct bpf_token *token, bool is_kernel)
+{
+	int res = 0;
+	struct file *exe_file = NULL;
+	struct mm_struct *mm = current->mm;
+
+	if (is_kernel || !mm)
+		return 0;
+
+	exe_file = get_mm_exe_file(mm);
+	if (!exe_file)
+		return 0;
+
+	res = loadpin_check(exe_file, READING_EBPF);
+	fput(exe_file);
+
+	return res;
+}
+#endif /* CONFIG_SECURITY_LOADPIN_EBPF */
+
 static const struct lsm_id loadpin_lsmid = {
 	.name = "loadpin",
 	.id = LSM_ID_LOADPIN,
@@ -213,6 +239,9 @@ static struct security_hook_list loadpin_hooks[] __ro_after_init = {
 	LSM_HOOK_INIT(sb_free_security, loadpin_sb_free_security),
 	LSM_HOOK_INIT(kernel_read_file, loadpin_read_file),
 	LSM_HOOK_INIT(kernel_load_data, loadpin_load_data),
+#ifdef CONFIG_SECURITY_LOADPIN_EBPF
+	LSM_HOOK_INIT(bpf_prog_load, loadpin_bpf_prog_load),
+#endif /* CONFIG_SECURITY_LOADPIN_EBPF */
 };
 
 static void __init parse_exclude(void)

---
base-commit: 122b52f0bab007ebeb414c8280c1def17b9ed1f4
change-id: 20260611-b4-rfc-loadpin-ebpf-086c41deb503

Best regards,
--  
Alex Roberts <alex.roberts109@outlook.com>

