From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 31 Jul 2026 12:44:12 -0500
Subject: [PATCH 4/4] selinux: require every boolean value to be defined
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-b4-disp-d32e997b-v1-4-0341d038ee47@proton.me>
References: <20260731-b4-disp-d32e997b-v1-0-0341d038ee47@proton.me>
In-Reply-To: <20260731-b4-disp-d32e997b-v1-0-0341d038ee47@proton.me>
To: Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>
Cc: linux-kernel@vger.kernel.org, Ondrej Mosnacek <omosnace@redhat.com>, 
 Kees Cook <kees@kernel.org>, selinux@vger.kernel.org, 
 =?utf-8?q?Christian_G=C3=B6ttsche?= <cgzones@googlemail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785519848; l=2108;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=I7aNEIxlzRwFx8VoQh04N3ZU/iwunm3TR1TrNlfSSMw=;
 b=xlN1scXScpwCr94ODTYukby6eRZzCnJ4J8SLTAx69Wrc1Z/ByhoW6GiXq2lXmxnnxj/aTJpCM
 Huj0PC2hY5qA8pV25NA1wYbbzCA/Pv8ZfYRxXH7yKK9ErBS7rtk/qQb
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

p_bools.nprim comes from the policy image independently of how many
booleans follow it, and cond_index_bool() fills bool_val_to_struct[] at
value - 1, so a count larger than the values present leaves NULL entries.
Every user of that array then walks it by index and dereferences each
entry: cond_evaluate_expr() on the access-vector path,
security_get_bools() and security_get_bool_value() behind selinuxfs, and
security_set_bools(). A sparse class value is absorbed by
policydb_class_isvalid() and its siblings; booleans have no such
predicate, and no consumer that could use one.

Reject a boolean value that no boolean defines, once, where the array is
built. Conforming policies define every boolean they declare and are
unaffected.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 security/selinux/ss/policydb.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/security/selinux/ss/policydb.c b/security/selinux/ss/policydb.c
index d358200817bd..d88713201be9 100644
--- a/security/selinux/ss/policydb.c
+++ b/security/selinux/ss/policydb.c
@@ -719,6 +719,7 @@ static inline void symtab_hash_eval(struct symtab *s)
 static int policydb_index(struct policydb *p)
 {
 	int i, rc;
+	u32 v;
 
 	if (p->mls_enabled)
 		pr_debug(
@@ -769,6 +770,24 @@ static int policydb_index(struct policydb *p)
 		if (rc)
 			goto out;
 	}
+
+	/*
+	 * A sparse class value is absorbed by policydb_class_isvalid() and
+	 * its siblings, but no such predicate exists for booleans: every
+	 * user of bool_val_to_struct[] walks it by index and dereferences
+	 * each entry -- cond_evaluate_expr(), the two getters and
+	 * security_set_bools() -- so an unclaimed one has no consumer that
+	 * can tolerate it.
+	 */
+	for (v = 0; v < p->p_bools.nprim; v++) {
+		if (!p->bool_val_to_struct[v]) {
+			pr_err("SELinux:  boolean %u is declared but not defined\n",
+			       v + 1);
+			rc = -EINVAL;
+			goto out;
+		}
+	}
+
 	rc = 0;
 out:
 	return rc;

-- 
2.55.0

