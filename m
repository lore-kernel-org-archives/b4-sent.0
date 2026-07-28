From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 27 Jul 2026 20:30:59 -0500
Subject: [PATCH v2 2/2] selinux: reject a class permission count below its
 inherited common
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-b4-disp-eed1276a-v2-2-82d58cf5f882@proton.me>
References: <20260727-b4-disp-eed1276a-v2-0-82d58cf5f882@proton.me>
In-Reply-To: <20260727-b4-disp-eed1276a-v2-0-82d58cf5f882@proton.me>
To: Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>
Cc: Kees Cook <kees@kernel.org>, Ondrej Mosnacek <omosnace@redhat.com>, 
 =?utf-8?q?Christian_G=C3=B6ttsche?= <cgzones@googlemail.com>, 
 selinux@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785202257; l=1793;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=axntQSnIG2WGrQfpV5GsiSNroNNW1F4YZJy6q4kqSWo=;
 b=arKPlgG7oPTYXLAfp1enS/EjTgKbG3UmWih2wc5fSmK2n/OQqcKFed7RlYri0uXTHDL6xPznl
 rZMlFod9ug4DBb0XY+xqoZHRE8au8msOaMaZ5WC2/uAKX3rVcclkrMv
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

security_get_permissions() maps an inherited common's permissions into
an array sized by the class's own permissions.nprim, but class_read()
takes that nprim verbatim from the policy image and never checks that it
covers the common.  A class that inherits a common of N permissions while
declaring a smaller nprim is accepted, and on load the common's
permissions are written past the class-sized array -- an out-of-bounds
heap write.

Reject a class whose permission count is below its inherited common's.
Well-formed policies, where the class count already includes the
inherited permissions, are unaffected.

Fixes: 55fcf09b3fe4 ("selinux: add support for querying object classes and permissions from the running policy")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 security/selinux/ss/policydb.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/security/selinux/ss/policydb.c b/security/selinux/ss/policydb.c
index 6973b68d9782..c6f55f0b4cb5 100644
--- a/security/selinux/ss/policydb.c
+++ b/security/selinux/ss/policydb.c
@@ -1422,6 +1422,18 @@ static int class_read(struct policydb *p, struct symtab *s, struct policy_file *
 			       cladatum->comkey);
 			goto bad;
 		}
+
+		/*
+		 * security_get_permissions() maps the common's permissions
+		 * into an array sized by this class's nprim, so a class must
+		 * declare at least as many as the common it inherits.
+		 */
+		if (cladatum->permissions.nprim <
+		    cladatum->comdatum->permissions.nprim) {
+			pr_err("SELinux:  class %s has fewer permissions than common %s\n",
+			       key, cladatum->comkey);
+			goto bad;
+		}
 	}
 	for (i = 0; i < nel; i++) {
 		rc = perm_read(p, &cladatum->permissions, fp);

-- 
2.55.0

