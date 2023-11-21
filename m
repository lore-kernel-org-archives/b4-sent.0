From: Joel Granados <j.granados@samsung.com>
Date: Tue, 21 Nov 2023 12:35:13 +0100
Subject: [PATCH v2 3/4] sysctl: Remove the now superfluous sentinel
 elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231121-jag-sysctl_remove_empty_elem_fs-v2-3-39eab723a034@samsung.com>
References: <20231121-jag-sysctl_remove_empty_elem_fs-v2-0-39eab723a034@samsung.com>
In-Reply-To: <20231121-jag-sysctl_remove_empty_elem_fs-v2-0-39eab723a034@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, willy@infradead.org, 
 josh@joshtriplett.org, Kees Cook <keescook@chromium.org>, 
 David Howells <dhowells@redhat.com>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Benjamin LaHaise <bcrl@kvack.org>, 
 Eric Biederman <ebiederm@xmission.com>, 
 Trond Myklebust <trond.myklebust@hammerspace.com>, 
 Anna Schumaker <anna@kernel.org>, Chuck Lever <chuck.lever@oracle.com>, 
 Jeff Layton <jlayton@kernel.org>, Neil Brown <neilb@suse.de>, 
 Olga Kornievskaia <kolga@netapp.com>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Tom Talpey <tom@talpey.com>, Jan Kara <jack@suse.cz>, 
 Amir Goldstein <amir73il@gmail.com>, Matthew Bobrowski <repnop@google.com>, 
 Anton Altaparmakov <anton@tuxera.com>, Namjae Jeon <linkinjeon@kernel.org>, 
 Mark Fasheh <mark@fasheh.com>, Joel Becker <jlbec@evilplan.org>, 
 Joseph Qi <joseph.qi@linux.alibaba.com>, Iurii Zaikin <yzaikin@google.com>, 
 Eric Biggers <ebiggers@kernel.org>, "Theodore Y. Ts'o" <tytso@mit.edu>, 
 Chandan Babu R <chandan.babu@oracle.com>, 
 "Darrick J. Wong" <djwong@kernel.org>, Jan Harkes <jaharkes@cs.cmu.edu>, 
 coda@cs.cmu.edu
Cc: linux-cachefs@redhat.com, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-aio@kvack.org, linux-mm@kvack.org, 
 linux-nfs@vger.kernel.org, linux-ntfs-dev@lists.sourceforge.net, 
 ocfs2-devel@lists.linux.dev, fsverity@lists.linux.dev, 
 linux-xfs@vger.kernel.org, codalist@coda.cs.cmu.edu, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=1106;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=ep6ig3KsG/haTwVjLCKKm4Kk60+leb3CQTaGMwbdTjg=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlXJYEHrUrJZCSGhRAH7Lq93IX9aUwf0UftJjsH
 7rBKf1mt9qJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZVyWBAAKCRC6l81St5ZB
 TywHC/oCWN+gpATwjEYOkvLgQs27TVMiW82MjN3jvdcXZMVM3RiIEFPafLxsFCdBwi0wrl2QAPR
 RiAym6toTbdpbb2DoFgfjwkJXRTArFWrIK0wUZ70Kf9Wu6/ZqU3YDk99zYO8AaGCBP9XKwfZYyE
 k1wuspuAlGu1hMd7tqNhq+zEU/pbtD/Y1v5z7jZuAyH1RVzMx5rFwJJPo8VZGUJTaXqdZd6yakg
 YetVCecE2qJr8LjTCjPe2z5m0eOkyrV+U1tf/+5yRy0y2awIWn7RH6F6oIY23gjYLL5GPpbcFa5
 5k6LP6S/La0DyWj60nD7VyxoXovlBg+frs5+LF4kZJkmqCFz+JPZasNM5uPdLXIwDpzGOS9KmEq
 OplDLRsQ9bjGeaqLXweriDYZcEinYOCcfbr1hFWokBFpGDeGvbpXvhTfgCHaZtFwmaYfOQNURpu
 8/mUfBR1ImmVaWFIx/D7R8sLihcpD1W1NJJfu19i6TJNLSWpKmp0F/VIzchleIrJg1SaY=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove empty sentinel element from test_table and test_table_unregister.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 lib/test_sysctl.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/lib/test_sysctl.c b/lib/test_sysctl.c
index 8036aa91a1cb..9d71ec5e8a77 100644
--- a/lib/test_sysctl.c
+++ b/lib/test_sysctl.c
@@ -130,7 +130,6 @@ static struct ctl_table test_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_do_large_bitmap,
 	},
-	{ }
 };
 
 static void test_sysctl_calc_match_int_ok(void)
@@ -184,7 +183,6 @@ static struct ctl_table test_table_unregister[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec_minmax,
 	},
-	{}
 };
 
 static int test_sysctl_run_unregister_nested(void)

-- 
2.30.2

