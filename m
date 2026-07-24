From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 24 Jul 2026 09:47:53 -0500
Subject: [PATCH] selinux: reject a permission value exceeding the class
 permission count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-b4-disp-ec8ac9f6-v1-1-d76d51a69b9d@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTtJqbUFr2JclGGqwwJIR4gJ4
 e4WXL7F/xsoZ2GFe7VB5lVUprGgvlRA7zi+GKUvBmusN8E67Bz2ojMyNZHa5PEWPF1THUI0Dko
 2Z07yPZeP59+6dAPT5/jAvv8AJSDY/3QAAAA=
X-Change-ID: 20260724-b4-disp-ec8ac9f6-576c3f177a04
To: Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>
Cc: Ondrej Mosnacek <omosnace@redhat.com>, selinux@vger.kernel.org, 
 =?utf-8?q?Christian_G=C3=B6ttsche?= <cgzones@googlemail.com>, 
 Kees Cook <kees@kernel.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784904472; l=2709;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=x09qCOc67iye83BfdnhVgxWmQx/htHDGaJ30yFzOV2w=;
 b=lM6mKKeMGO+1H2Ju7gB8MHLYyN971H+gqYdlwgwpwhbj1gcPJFDLYRGbWlvOYA2j8eqqATZ1X
 PlkZ+/nL+KVAq/GAgAfRyj3SLKiiO9N3yjZc6fR76qDtGPHm54XBj2A
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

perm_read() bounds a permission value by SEL_VEC_MAX but never by the
owning class or common's nprim, which is taken verbatim from the policy
image.  security_get_permissions() then writes perms[value - 1] into an
nprim-sized kcalloc() array, so a class declaring fewer permissions than
its largest permission value drives an out-of-bounds heap write.  The
top-level symbol tables are validated this way; the nested per-class
permission table is not.

Reject a permission whose value exceeds nprim, which is already set when
perm_read() runs.  Well-formed policies are unaffected.

Fixes: 55fcf09b3fe4 ("selinux: add support for querying object classes and permissions from the running policy")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reproducer and A/B verification (below the --- so git am drops it):

A binary policy whose "process" class carries permissions.nprim = 1 while
keeping its 31 permissions (values 1..31) is accepted by the parser.  On
load, security_get_permissions() allocates a one-entry array and writes
perms[value - 1] for each permission -- a heap slab-out-of-bounds write.

Tested on a KASAN kernel, loading via /sys/fs/selinux/load:

  Build A (without this patch): loading the malformed policy ->
    BUG: KASAN: slab-out-of-bounds in get_permissions_callback
    Write of size 8 ... security_get_permissions()
    (followed by a GPF once an adjacent object's pointer is overwritten)

  Build B (with this patch): the same policy is rejected at parse time
    (-EINVAL); no KASAN report.

  Control (without this patch): a well-formed policy (nprim = 31) loads
    cleanly, no KASAN report -- the fault is specific to nprim < value.

Reachable by a process with CAP_MAC_ADMIN writing a crafted policy to
/sys/fs/selinux/load; SELinux policy load is not namespaced.
---
 security/selinux/ss/policydb.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/security/selinux/ss/policydb.c b/security/selinux/ss/policydb.c
index ead504a639e3..6973b68d9782 100644
--- a/security/selinux/ss/policydb.c
+++ b/security/selinux/ss/policydb.c
@@ -1175,6 +1175,9 @@ static int perm_read(struct policydb *p, struct symtab *s, struct policy_file *f
 	rc = -EINVAL;
 	if (perdatum->value < 1 || perdatum->value > SEL_VEC_MAX)
 		goto bad;
+	/* the value indexes an nprim-sized array in security_get_permissions() */
+	if (perdatum->value > s->nprim)
+		goto bad;
 
 	rc = str_read(&key, GFP_KERNEL, fp, len);
 	if (rc)

---
base-commit: 48a5a7ab8d6ab7090564339e039c421f315de912
change-id: 20260724-b4-disp-ec8ac9f6-576c3f177a04

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

