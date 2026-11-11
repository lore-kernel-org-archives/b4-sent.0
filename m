From: Mani Tofigh <mt4022@columbia.edu>
Date: Wed, 11 Nov 2026 16:02:25 -0500
Subject: [PATCH] pipe: keep per-write wakeups for EPOLLEXCLUSIVE consumers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-pipe-epollexclusive-wakeup-v1-1-0af6283e9fda@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTsJbdCgVzEuoPzqaAOTjkUSw
 t2t+nbf5q1kSAKjU7VSwiwm01jgdhWFezfewDIUk6/9wZVYRcHQKUYsIWaTGfzunsjKx9btfVs
 3rm8GKgNNuMrym58vf1vuHwiv75G27QObfYctfgAAAA==
X-Change-ID: 20261111-pipe-epollexclusive-wakeup-981528041b4d
To: Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>
Cc: Jan Kara <jack@suse.cz>, Oleg Nesterov <oleg@redhat.com>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794430945; l=3875;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=AMo3CuUQRFmmdnadGKZpp80pX6RvxZnQfgMh8Vg/BZs=;
 b=vKagOaquZDeNf8CRSF5BrdESHWSEON6SGjDwk4FBb4Vfz1qkjFSxsKl31j4K60lWFb24/LumK
 fWzBA7CejUbDqSjbFj6mS+PWDVzPdCQJYxe3tDV+kqpfafvnMpEKd7r
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A task blocked in read() on a pipe can sleep while the pipe holds data,
when an epoll(EPOLLEXCLUSIVE) watcher of the read end was added before
it.  The watcher's entry on ->rd_wait is exclusive and sits ahead of the
reader, so a write into an empty pipe wakes only the watcher.  The
watcher reads without sleeping in anon_pipe_read() and doesn't pass the
wakeup on.  Since commit f1cebdec9739 ("pipe: only enable the extra
wake_up(rd_wait) for EPOLLET consumers") the next writes into the
non-empty pipe don't wake anyone anymore:

  Task E                   Task A                 Task C
  epoll_wait(ep, -1)
    /* EPOLLEXCLUSIVE */
                           read(p[0])
                                                  write(p[1], "1")
                                                    /* wakes E only */
                                                  write(p[1], "2")
                                                    /* no wakeup */
  read(p[0], 1 byte)
  exit()
                           /* still asleep, "2" is in the pipe */

A then sleeps until the next write into an empty pipe, if ever.  Before
that commit any pipe_poll() enabled the per-write wakeups.  Those
reached A because an EPOLLEXCLUSIVE entry only takes a wakeup while a
task sleeps in epoll_wait().

So EPOLLEXCLUSIVE consumers depend on the per-write wakeups too, for a
different reason than EPOLLET.  Enable them for EPOLLEXCLUSIVE as well
and say why in the comment.  With the fix, A reads the second byte.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 2s.

Fixes: f1cebdec9739 ("pipe: only enable the extra wake_up(rd_wait) for EPOLLET consumers")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/pipeexcl.c

There are a couple of older gaps like this (a single write, and the
write side with EPOLLOUT|EPOLLEXCLUSIVE).  I left both alone here though.
---
 fs/pipe.c                 | 6 +++++-
 include/linux/pipe_fs_i.h | 2 +-
 2 files changed, 6 insertions(+), 2 deletions(-)

diff --git a/fs/pipe.c b/fs/pipe.c
index 4c1122597a3c..8ad792d300c9 100644
--- a/fs/pipe.c
+++ b/fs/pipe.c
@@ -700,9 +700,13 @@ pipe_poll(struct file *filp, poll_table *wait)
 	 * and the ->pseudo_edgetrigger check in anon_pipe_write().
 	 * Currently io_uring sets EPOLLET for multishot polls, so it gets the
 	 * same behaviour.
+	 *
+	 * EPOLLEXCLUSIVE needs them too.  Its entry is an exclusive waiter on
+	 * ->rd_wait that can take the wakeup meant for a blocked reader, and
+	 * unlike a woken reader in anon_pipe_read() it doesn't pass it on.
 	 */
 	if ((filp->f_mode & FMODE_READ) &&
-	    wait && (wait->_key & EPOLLET) &&
+	    wait && (wait->_key & (EPOLLET | EPOLLEXCLUSIVE)) &&
 	    unlikely(!READ_ONCE(pipe->pseudo_edgetrigger)))
 		WRITE_ONCE(pipe->pseudo_edgetrigger, true);
 
diff --git a/include/linux/pipe_fs_i.h b/include/linux/pipe_fs_i.h
index 95f6236c5c5b..6b2e14ec6ef8 100644
--- a/include/linux/pipe_fs_i.h
+++ b/include/linux/pipe_fs_i.h
@@ -90,7 +90,7 @@ struct anon_pipe_prealloc {
  *	@files: number of struct file referring this pipe (protected by ->i_lock)
  *	@r_counter: reader counter
  *	@w_counter: writer counter
- *	@pseudo_edgetrigger: has an EPOLLET consumer, enable per-write wakeups
+ *	@pseudo_edgetrigger: enable per-write wakeups for EPOLLET/EPOLLEXCLUSIVE
  *	@fasync_readers: reader side fasync
  *	@fasync_writers: writer side fasync
  *	@bufs: the circular array of pipe buffers

---
base-commit: b0993210e420f2f1d61e6719fbcd3966b96ff9ed
change-id: 20261111-pipe-epollexclusive-wakeup-981528041b4d

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

