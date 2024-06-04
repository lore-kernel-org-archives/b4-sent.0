From: Joel Granados <j.granados@samsung.com>
Date: Tue, 04 Jun 2024 08:29:24 +0200
Subject: [PATCH 6/8] sysctl: Remove "child" sysctl code comments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240604-jag-sysctl_remset-v1-6-2df7ecdba0bd@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2907;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=0XKCBtKXUsaQ3icltpQ/GcT4z/xTnWSxXkUvgvEAqjc=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZetGSx+J2DsW2akHI1bXUBxwZLWJOp+r/vp
 Mjc/iI3BpjvEIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmXrRkAAoJELqXzVK3
 lkFP5qIL/1mam3EXhTaxS41hy26Dmq0UjeoUbnRZYhSzHmbvW3UT9tGd0CEzkRmrmeO5pdUckpq
 /Xdt4dyVI2zsF1mpS0/senLUoeACPSh46rmxp5ymGQQZ999WnsOewsF44Mjh/agSxFKYLIMWhTu
 HP0QK15UKiFYjQVS/IcARz0Rq96i8bWVETbMGfCvTSh9swmqxWj7VqNDY1mXl1MIHr+Mzh6tdB1
 AHaTV/HasD29w/8TIBI7J+II662XOod/LWhfuSYUKtkxKQgMCOw8wqIouOv1s9sdsnFR/6uaxEC
 GOHVm1t4sQ7GsSyaRwvEVP/aB5SnRGWn6408TrOz7E/Jn2sabbqUB9Ordb2H8FP0Ss88mW8kE2O
 GNFLoqO6pDYyWYSvXKLsugRX5f17Zhth9sYOdKExC+60DIQg2SFQoQRXHGGSVPBDFu/eLBCxlx9
 jOHJAUn2H18r9Amtf/jCtQG51NN+gJH/ndYTe9NkwKnQpjhiITpmpMdb6QjPMrDMs8MnrpY0xV6
 tI=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Erase the code comments mentioning "child" that were forgotten when the
child element was removed in commit 2f2665c13af48 ("sysctl: replace
child with an enumeration").

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 fs/proc/proc_sysctl.c | 26 ++++++++++----------------
 1 file changed, 10 insertions(+), 16 deletions(-)

diff --git a/fs/proc/proc_sysctl.c b/fs/proc/proc_sysctl.c
index 29d40f0ff3ff..2ef23d2c3496 100644
--- a/fs/proc/proc_sysctl.c
+++ b/fs/proc/proc_sysctl.c
@@ -1298,28 +1298,23 @@ static struct ctl_dir *sysctl_mkdir_p(struct ctl_dir *dir, const char *path)
  * __register_sysctl_table - register a leaf sysctl table
  * @set: Sysctl tree to register on
  * @path: The path to the directory the sysctl table is in.
- * @table: the top-level table structure without any child. This table
- * 	 should not be free'd after registration. So it should not be
- * 	 used on stack. It can either be a global or dynamically allocated
- * 	 by the caller and free'd later after sysctl unregistration.
+ *
+ * @table: the top-level table structure. This table should not be free'd
+ *         after registration. So it should not be used on stack. It can either
+ *         be a global or dynamically allocated by the caller and free'd later
+ *         after sysctl unregistration.
  * @table_size : The number of elements in table
  *
  * Register a sysctl table hierarchy. @table should be a filled in ctl_table
  * array. A completely 0 filled entry terminates the table.
  *
  * The members of the &struct ctl_table structure are used as follows:
- *
  * procname - the name of the sysctl file under /proc/sys. Set to %NULL to not
  *            enter a sysctl file
- *
- * data - a pointer to data for use by proc_handler
- *
- * maxlen - the maximum size in bytes of the data
- *
- * mode - the file permissions for the /proc/sys file
- *
- * child - must be %NULL.
- *
+ * data     - a pointer to data for use by proc_handler
+ * maxlen   - the maximum size in bytes of the data
+ * mode     - the file permissions for the /proc/sys file
+ * type     - Defines the target type (described in struct definition)
  * proc_handler - the text handler routine (described below)
  *
  * extra1, extra2 - extra pointers usable by the proc handler routines
@@ -1327,8 +1322,7 @@ static struct ctl_dir *sysctl_mkdir_p(struct ctl_dir *dir, const char *path)
  * [0] https://lkml.kernel.org/87zgpte9o4.fsf@email.froward.int.ebiederm.org
  *
  * Leaf nodes in the sysctl tree will be represented by a single file
- * under /proc; non-leaf nodes (where child is not NULL) are not allowed,
- * sysctl_check_table() verifies this.
+ * under /proc; non-leaf nodes are not allowed.
  *
  * There must be a proc_handler routine for any terminal nodes.
  * Several default handlers are available to cover common cases -

-- 
2.43.0

