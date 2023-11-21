From: Joel Granados <j.granados@samsung.com>
Date: Tue, 21 Nov 2023 12:35:14 +0100
Subject: [PATCH v2 4/4] coda: Remove the now superfluous sentinel elements
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231121-jag-sysctl_remove_empty_elem_fs-v2-4-39eab723a034@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=826; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=EW/W6zZslOuVBpUJvlaE+2AnAGMLV/WhhzCxxx+6aVM=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlXJYEhjHRDFWxlKQCSEU/qOb5kLqYz6u3U07bi
 5UcDbFrWhKJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZVyWBAAKCRC6l81St5ZB
 T28vC/0S1zrvnTbJB+9oXn+IU0QpNx0mcFoiShnCrNbA/8SKyDultWZ4UpuxummzF7Lp+lD5UN+
 4kqlWdmqD0V15U9xcN+pg38JPAovwP6moJBKy0HxvGy5aKxZ7+Y4R2MALVzBu8ZHTVamwzcZBoQ
 y0Xxbaj4s9W7qSDKOoaeDdm3TElOl7O20irSXZ9xiPuhHRXyCKA3vGE0thmz9U0qY1cg6LkLgPm
 v7Bu7tG7wm6zAxw+5LxN1bNfF50whGqTLF4dxL892xn7dKSHteqNMG72ZipSkLz6DTnnZ16ywxy
 tGL1fmgTYzVDSWs26SDMONstCNERLXUuQgaWOxESQeWhJqyuEmU0SQpHvkMFZvGrrbfBvWc86uV
 UydKbDOAO1UEpnjCajlfO8PErya2zHHi6+08qjXLmzyXf6q6ubr31K9RqsKpvaZ6Ot3MGk/sRDV
 2H+R3PXl3yyyRe8rC/hT8qKksu59/IYAi6vOcEVkAes4tJCtjzMJ4au9zv7osWjoRyWUs=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove empty sentinel from coda_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 fs/coda/sysctl.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/fs/coda/sysctl.c b/fs/coda/sysctl.c
index a247c14aaab7..9f2d5743e2c8 100644
--- a/fs/coda/sysctl.c
+++ b/fs/coda/sysctl.c
@@ -36,7 +36,6 @@ static struct ctl_table coda_table[] = {
 		.mode		= 0600,
 		.proc_handler	= proc_dointvec
 	},
-	{}
 };
 
 void coda_sysctl_init(void)

-- 
2.30.2

