From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 31 Jul 2026 12:44:11 -0500
Subject: [PATCH 3/4] selinux: reject an unclaimed class value in
 security_get_classes()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-b4-disp-d32e997b-v1-3-0341d038ee47@proton.me>
References: <20260731-b4-disp-d32e997b-v1-0-0341d038ee47@proton.me>
In-Reply-To: <20260731-b4-disp-d32e997b-v1-0-0341d038ee47@proton.me>
To: Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>
Cc: linux-kernel@vger.kernel.org, Ondrej Mosnacek <omosnace@redhat.com>, 
 Kees Cook <kees@kernel.org>, selinux@vger.kernel.org, 
 =?utf-8?q?Christian_G=C3=B6ttsche?= <cgzones@googlemail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785519848; l=2212;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=146rmnAfLEvFW4uw+zlgvifpJzRkQBhtNeevcrvrVxY=;
 b=75DlDjNX2pjUbExZ1Kf+vXP0AyfZVSOzdMKlZr7wbTah/wLkZaJIMQ5BcA7uc31mfFZ5/h4zP
 W17KLxQSHlHCGW3Cb3d6NgzU0UimsXtm8tWZQH6NZ8rdP9d4vfS44UI
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

security_get_classes() sizes an array by p_classes.nprim and fills it at
value - 1, so a class value the policy never defines leaves a NULL.
sel_make_classes() passes every entry to sel_make_dir(), reaching the same
d_alloc_name() dereference as the permission array. The class symbol table
is allowed to be sparse (policydb_class_isvalid() exists to absorb that),
but this getter builds its own array straight from the hash table and has
no such predicate.

Fail the lookup when a value went unclaimed instead of handing out the
NULL. Conforming policies define every class they declare and are
unaffected.

Fixes: 55fcf09b3fe4 ("selinux: add support for querying object classes and permissions from the running policy")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 security/selinux/ss/services.c | 24 +++++++++++++++++++-----
 1 file changed, 19 insertions(+), 5 deletions(-)

diff --git a/security/selinux/ss/services.c b/security/selinux/ss/services.c
index 90e81186cb2e..7afce975436e 100644
--- a/security/selinux/ss/services.c
+++ b/security/selinux/ss/services.c
@@ -3304,6 +3304,7 @@ int security_get_classes(struct selinux_policy *policy,
 			 char ***classes, u32 *nclasses)
 {
 	struct policydb *policydb;
+	u32 i;
 	int rc;
 
 	policydb = &policy->policydb;
@@ -3316,16 +3317,29 @@ int security_get_classes(struct selinux_policy *policy,
 
 	rc = hashtab_map(&policydb->p_classes.table, get_classes_callback,
 			 *classes);
-	if (rc) {
-		u32 i;
+	if (rc)
+		goto err;
 
-		for (i = 0; i < *nclasses; i++)
-			kfree((*classes)[i]);
-		kfree(*classes);
+	/*
+	 * The class symtab may be sparse, which policydb_class_isvalid() exists
+	 * to absorb; the callback fills this array by value, so an unclaimed
+	 * one leaves a NULL that sel_make_classes() hands to sel_make_dir().
+	 */
+	for (i = 0; i < *nclasses; i++) {
+		if (!(*classes)[i]) {
+			rc = -EINVAL;
+			goto err;
+		}
 	}
 
 out:
 	return rc;
+
+err:
+	for (i = 0; i < *nclasses; i++)
+		kfree((*classes)[i]);
+	kfree(*classes);
+	return rc;
 }
 
 static int get_permissions_callback(void *k, void *d, void *args)

-- 
2.55.0

