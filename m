From: Joel Granados <j.granados@samsung.com>
Date: Tue, 04 Jun 2024 08:29:25 +0200
Subject: [PATCH 7/8] sysctl: Remove ctl_table sentinel code comments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240604-jag-sysctl_remset-v1-7-2df7ecdba0bd@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=882; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=zTe/Mj/k43FhBaGgdPaFYoMPRIHkDQfZ6H7/ug1O6Cc=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZetGUkSr3CVpnP54k/+9PHKhfTTA69nKuVw
 AbWrpNS33D41YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmXrRlAAoJELqXzVK3
 lkFPCvYMAIUVsRJA74OqhAoo95LSMr9pMo00Icg5tPkk1tZPCHQkgj4cL2Zu2V5jRGwRSkLxp5H
 IR0HctTp2+yGtKeGn8qj4XbwZ1GKTdx2q8M7n61gfVtpwl28bbKBSCCdOBFet1Z/RjdfO7qztoE
 iqAoUGKhJ4gsokBwKCrCTFgKTFDOD+B/B0cVwfcFRYVxtxTf5kmtg7MlAOY+Jtu/e8SLt85+h+G
 qgaRnRK7WRFMhZpfhgYzt02oNXWGlM/cmg/oo5Jbw/oEvgvrEngxgzuwmKQpfugA0KyBDBLyV0J
 xRQlthY/U1hjOXj80QnD1wSXjQe85phvjRlxf36FOsL+TjkQvUf0Qgk1WDbuYwHsJpxk3avhU7n
 iF/b0D1fc+BUB06Ux0PTitZBh39pLgo+UsK2yLw215oBiL9sRILV+rwI03Mr3BOyAsxWImkNmUY
 jVhQLyQ2SE7sBmT6Q6jBK9ea/2wQ2/WOFtIjQk0eGHHJy4Yvc8q3GoGbYPe3jxNFcKzMnX+Iuw6
 GA=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the mention of a "zero terminated entry" from the
__register_sysctl_table function doc.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 fs/proc/proc_sysctl.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/proc/proc_sysctl.c b/fs/proc/proc_sysctl.c
index 2ef23d2c3496..806700b70dea 100644
--- a/fs/proc/proc_sysctl.c
+++ b/fs/proc/proc_sysctl.c
@@ -1306,7 +1306,7 @@ static struct ctl_dir *sysctl_mkdir_p(struct ctl_dir *dir, const char *path)
  * @table_size : The number of elements in table
  *
  * Register a sysctl table hierarchy. @table should be a filled in ctl_table
- * array. A completely 0 filled entry terminates the table.
+ * array.
  *
  * The members of the &struct ctl_table structure are used as follows:
  * procname - the name of the sysctl file under /proc/sys. Set to %NULL to not

-- 
2.43.0

