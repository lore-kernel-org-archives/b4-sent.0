From: Joel Granados <j.granados@samsung.com>
Date: Tue, 07 Nov 2023 14:44:20 +0100
Subject: [PATCH 1/4] cachefiles: Remove the now superfluous sentinel
 element from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231107-jag-sysctl_remove_empty_elem_fs-v1-1-7176632fea9f@samsung.com>
References: <20231107-jag-sysctl_remove_empty_elem_fs-v1-0-7176632fea9f@samsung.com>
In-Reply-To: <20231107-jag-sysctl_remove_empty_elem_fs-v1-0-7176632fea9f@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=923; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=SGTnhgVPbRkVEntdcKFq1I6E3blB6PSwrb9JaawnFFQ=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlSj9M2ig+1rzDK3f26PkGfrXWs+L3sZHbcxuLZ
 iLSqjCt04yJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZUo/TAAKCRC6l81St5ZB
 TyqTC/9Uoc1Mimxa39eNT1hPi8AUMLHAwsLHAs/0Njg/O4yNK+y9soM5dgjUElmwbiilSzCoF96
 KOrLzOVWdrT8x5EiJajBmIczrpnvFo2XR1q59Tdg8+dVfzfdBKf9810BUXm22LDrhR5GCrfUjIe
 WI/w8QEvhxTRKvMJ5RUVl2jeeid8nF4ujb09LKlQMcj8mWT2+Dky7Y7C1J+AYI6fUSkT1SYRCGh
 ffoxN9L3S8Z/p3QRid2gFhunhJR3srSt3zGaLSwjJ/uQem0RFk0bHeGNq6mtq7H9PGnx7WrBq2Q
 X38P2PTXPDPOJW1aJJo3JV4J6I9ZJXvvc9ICJ3Wwd4yjd6sC199Oyu5j8fs9zXXlGKMoJbR+6Ua
 U//6ZueugQgAELb5QYH2rbjFeKAdSEJMotieMRJX/EXowVpmwUtie1sugGTqE0lBeQj7YcSl0It
 omT8aMtMmJ7/fay2nrRV3e63CCMFfc9EOjGkjEX1MMFnzzyQv14byTNJhE303H6qq5M4A=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the empty
elements at the end of the ctl_table arrays (sentinels) which will reduce the
overall build time size of the kernel and run time memory bloat by ~64 bytes
per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from cachefiles_sysctls

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 fs/cachefiles/error_inject.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/fs/cachefiles/error_inject.c b/fs/cachefiles/error_inject.c
index 18de8a876b02..1715d5ca2b2d 100644
--- a/fs/cachefiles/error_inject.c
+++ b/fs/cachefiles/error_inject.c
@@ -19,7 +19,6 @@ static struct ctl_table cachefiles_sysctls[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_douintvec,
 	},
-	{}
 };
 
 int __init cachefiles_register_error_injection(void)

-- 
2.30.2

