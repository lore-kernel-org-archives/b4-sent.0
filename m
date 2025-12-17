From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 17 Dec 2025 09:04:40 +0100
Subject: [PATCH 2/7] sysctl: clarify proc_douintvec_minmax doc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251217-jag-no-macro-conv-v1-2-6e4252687915@kernel.org>
References: <20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org>
In-Reply-To: <20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1244;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=7AHWEkJrCgJf28XDy4+AhvRex/rKi4omNUzr0zBfAyY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlCZEprGYwzIjqFXNIzbqWohf9ZpLvRFjfwm
 TXFxj+CeH2EjIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpQmRKAAoJELqXzVK3
 lkFPOZIL/RVW9aA+XJmXx7Nf94T6ge8FNJCBqAchqK2bJHb4Q4ij3CzzUn8blh6DGYEx9zo+rIX
 pIIpyJUcV80eSZpSIyRjSobeU18erTqwXcjINtnRBXqdEWsKcOzwRpp42ijWSNZg5eMlRyPf21D
 JKLkkzNYTncImpOjs9kKP02sN3R8UMLzQg0Laq40lG3LXXFcE+zW8nF1MTo0nZMNbtDka5VFDuI
 AeUI2Qt00UFQZYPyhBqNcZlnS4U/ySiOpQWCeyhoitMwbszHC3LQxIhK3aOg8zW+KF0FqyPBvpY
 87RPUF2nz9g5ZcaxK5qZm5vUjNl2Nu2y48+GmaxKY3LgtGTSnVWcUA/cP2sjj3Rv1l12cwghBhZ
 eiuPN3qP8vvBakBeRdsXj1+A6V+EN3tFTl6wp5krSf1Kc9VvoA8e8OZ6zY7N0ZpIT7h+nM9s/Va
 mDeHPRc8l6IGhG1Nvtmk8TdgoX9GahvIcBKYAJXtmfOhUo4fbvNvrQ1A0Lnx+wiXWCpJ7pxFt85
 0U=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Specify that the range check is only when assigning kernel variable

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 84ca24fb1965e97dc9e6f71f42a6c99c01aca3ee..e82716b7c13840cadc3b19a7c9d05b167abebcf6 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -692,10 +692,10 @@ int proc_dointvec_minmax(const struct ctl_table *table, int dir,
  * values from/to the user buffer, treated as an ASCII string. Negative
  * strings are not allowed.
  *
- * This routine will ensure the values are within the range specified by
- * table->extra1 (min) and table->extra2 (max). There is a final sanity
- * check for UINT_MAX to avoid having to support wrap around uses from
- * userspace.
+ * When changing the kernel variable, this routine will ensure the values
+ * are within the range specified by table->extra1 (min) and table->extra2
+ * (max). And Check that the values are less than UINT_MAX to avoid having to
+ * support wrap around uses from userspace.
  *
  * Returns 0 on success or -ERANGE when range check failes and
  * SYSCTL_USER_TO_KERN(dir) == true

-- 
2.50.1

