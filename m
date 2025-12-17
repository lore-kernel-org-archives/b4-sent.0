From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 17 Dec 2025 09:04:43 +0100
Subject: [PATCH 5/7] sysctl: Add kernel doc to proc_douintvec_conv
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251217-jag-no-macro-conv-v1-5-6e4252687915@kernel.org>
References: <20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org>
In-Reply-To: <20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1310;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=YsUYwAE1O8XtejvUjAcafWn1iQWbLefNUgR/xrWQ3dg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlCZEzOIecMN2mx42bK519i1J7nELTWI7sEL
 8vcQkkuMTMRdIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpQmRMAAoJELqXzVK3
 lkFPi0UL/3vdQEWjv9RF3GwEf0C6oGVt6CvLyQAEKEz5hafDHtD/ACZ6McjNPiSJuqNQ9RJaD9D
 rh5pttf2Gmw3oQxQJaFCHnqo9pqbsQcJ2vNMI+FFkgsLa/scTH0ZVcGzkyc7GHcJCWRQlbgk55X
 xRUlXR/tqA6QXbgwKAHpqgJ2Hx29l1UoQlNylceBRQextBkYIAC9/ObZlNEe/1dSBU4v71aQ2bg
 rsfJFljvsxvL4wqvMRBH1oGm8Aw47oznvDupXlpDPgi9R1+MlNlpvDKHU5px2R6XoQcDIOlQZPn
 Hq+fMnmG9kjegim7sBRG2vejBq2eD07VeDDJXh7ufwYzeWRya88hb/gqqFUJMGSwp9IGSWf+0DM
 BTghw5eiXfa9/VZQ/J02ne44FUL9tlJ+lrvC4foQrhSYStRVmE4SMjxUaYVx4p+3RmVtmOTAyJW
 hvznxv0s8MoGLjfCNYIXEKGbafKLeiqCuui5tzJeqcNkefGqqygjTcyHX0jOxb0Cc1bTc/lw1U4
 KQ=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit is making sure that all the functions that are part of the
API are documented.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 5901196a52f98cdd5aba4f50899a58d9bd9d10f9..ed2701acc89821e724b5697665f8a795dff8097d 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -656,6 +656,22 @@ static int do_proc_douintvec(const struct ctl_table *table, int dir,
 	return do_proc_douintvec_r(table, buffer, lenp, ppos, conv);
 }
 
+/**
+ * proc_douintvec_conv - read a vector of unsigned ints with a custom converter
+ *
+ * @table: the sysctl table
+ * @dir: %TRUE if this is a write to the sysctl file
+ * @buffer: the user buffer
+ * @lenp: the size of the user buffer
+ * @ppos: file position
+ * @conv: Custom converter call back
+ *
+ * Reads/writes up to table->maxlen/sizeof(unsigned int) unsigned integer
+ * values from/to the user buffer, treated as an ASCII string. Negative
+ * strings are not allowed.
+ *
+ * Returns 0 on success
+ */
 int proc_douintvec_conv(const struct ctl_table *table, int dir, void *buffer,
 			size_t *lenp, loff_t *ppos,
 			int (*conv)(unsigned long *u_ptr, unsigned int *k_ptr,

-- 
2.50.1

