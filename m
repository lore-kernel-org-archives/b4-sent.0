From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 13:19:01 -0500
Subject: [PATCH] eventpoll: wake the next waiter when a woken waiter is
 killed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-epoll-killed-waiter-v1-1-36e08c16b8a2@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwqDMBRG4a3IHfdCorZCt1I6SPRXbw0qiS8Q9
 260w29wzk4BXhDonezksUiQoY/Qj4TK1vQNWKpoSlX60lpljHFwjjtxDhWvRiZ4NrktapspPPO
 CYjl61LLd18/37zDbH8rpWtFxnFu4jhp3AAAA
X-Change-ID: 20261103-epoll-killed-waiter-a4b7fb30e547
To: Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>
Cc: Jan Kara <jack@suse.cz>, David Rientjes <rientjes@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793729940; l=2916;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=E8yisygosXMPs5dY2TbIReZZXoa4ZP3lxybfZT/nZno=;
 b=aPmE12Nzr0ZXZzOHh4n1Njq5Crq6XBaG7njn8SMGIP/JOD/Z9dC6jXRYiGqBowMARDfU0qXSn
 0Y0LS0MWt62BJgfbMUG/9E4thuifNVP9VcCUMfJ3FCiwqBw1O9hHd/d
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Processes sharing an epoll instance can sleep forever while an event is
ready.  An event wakes only one waiter, which then wakes the next one in
ep_done_scan() if events are still ready.  Since commit c257a340ede0
("fs, epoll: short circuit fetching events if thread has been killed"),
ep_send_events() returns before the scan when the waiter has a fatal
signal.  If the woken waiter is killed before it runs, nobody wakes the
next one:

  Task A                     Task B                 Task C
  epoll_wait(ep, -1)         epoll_wait(ep, -1)
                                                    write(efd)
                                                      /* wakes A only */
                                                    kill(A, SIGKILL)
  ep_send_events()
    return -EINTR
      /* skips ep_done_scan() */
                             /* still asleep */

B then sleeps until another file on the instance becomes ready, if ever.
This can hit eg a pre-fork server whose worker gets OOM killed.  Commit
7fab29e35630 ("fs/epoll: restore waking from ep_done_scan()") fixed the
same kind of hang when the wakeup in ep_done_scan() was removed.

Keep the early return so that a dying task still doesn't take events
nobody will see, but wake the next waiter there if events are ready, as
ep_done_scan() would have.  With the fix, B gets the event.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it within about 2s.

Fixes: c257a340ede0 ("fs, epoll: short circuit fetching events if thread has been killed")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/epollkill.c
---
 fs/eventpoll.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/fs/eventpoll.c b/fs/eventpoll.c
index 7a32c70bf2ad..b959af04772c 100644
--- a/fs/eventpoll.c
+++ b/fs/eventpoll.c
@@ -2144,10 +2144,17 @@ static int ep_send_events(struct eventpoll *ep,
 	/*
 	 * Always short-circuit for fatal signals to allow threads to make a
 	 * timely exit without the chance of finding more events available and
-	 * fetching repeatedly.
+	 * fetching repeatedly. The wakeup that got us here may have been the
+	 * only one for the events on ->rdllist, so pass it on to the next
+	 * waiter, as ep_done_scan() would have.
 	 */
-	if (fatal_signal_pending(current))
+	if (fatal_signal_pending(current)) {
+		spin_lock_irq(&ep->lock);
+		if (!list_empty(&ep->rdllist))
+			wake_up(&ep->wq);
+		spin_unlock_irq(&ep->lock);
 		return -EINTR;
+	}
 
 	init_poll_funcptr(&pt, NULL);
 

---
base-commit: a522dd871024a0f065bfa7638afdb929607f58fc
change-id: 20261103-epoll-killed-waiter-a4b7fb30e547

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

