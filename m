From: Anuj Bolewar <bolewara@gmail.com>
Date: Tue, 04 Aug 2026 22:28:36 +0530
Subject: [PATCH] usb: atm: cxacru: stop polling on device shutdown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-usb-atm-cxacru-stop-polling-on-device-shutdown-v1-1-d7fd757cee31@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQ6CMBBA0auQWTsJNATUqxgXZRhgDLZNp1USw
 t2tunyb/3dQjsIK12qHyC9R8a6gOVVAi3Uzo4zFYGrT1ee6xawD2vRE2izFjJp8wODXVdyM3uF
 YGsSoS06jfzsc6ELd1PdNZ1oo0RB5ku03vN3/1jw8mNL3AsfxAURam6WSAAAA
X-Change-ID: 20260804-usb-atm-cxacru-stop-polling-on-device-shutdown-bc9c6f771624
To: Chas Williams <3chas3@gmail.com>
Cc: accessrunner-general@lists.sourceforge.net, 
 linux-atm-general@lists.sourceforge.net, netdev@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+e4b1171e7c5ae2556f9e@syzkaller.appspotmail.com, 
 Anuj Bolewar <bolewara@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785862715; l=2251;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=8QcyJ5CtzZlRqOs+qCqjWR1tFjois3OdIejw7ulYCm8=;
 b=3l02SODI7MN+59jCpk6x2TdO9IUA1H/5XGGUINn8KHxAjoTChTzCNXCL7zsTibbpz5zVn9UVJ
 0I7BgtWIoQxDXBZC5spgAbkk1qKvU5TFizaRR3ly+JXc3AIWK1WyvuC
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cxacru_unbind() sets poll_state to CXPOLL_SHUTDOWN under
poll_state_serialize and then calls cancel_delayed_work_sync(). If
cxacru_poll_status() is already running it only stops rescheduling when
it observes CXPOLL_STOPPED; CXPOLL_SHUTDOWN is ignored, so a running
worker re-queues itself. cancel_delayed_work_sync() then returns while a
delayed work is still pending, and the work fires after cxacru_unbind()
has freed the instance, causing a use-after-free.

Treat CXPOLL_SHUTDOWN like CXPOLL_STOPPED in the reschedule decision so
a worker that sees the shutdown state stops polling and cannot re-queue
itself after unbind.

Reported-by: syzbot+e4b1171e7c5ae2556f9e@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=e4b1171e7c5ae2556f9e
Assisted-by: deepseek:v4-pro
Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
cxacru_poll_status() reschedules itself with schedule_delayed_work()
unless poll_state is CXPOLL_STOPPED. cxacru_unbind() sets poll_state
to CXPOLL_SHUTDOWN and relies on cancel_delayed_work_sync() to stop
the worker, but a worker that is already running when unbind starts
never observes CXPOLL_STOPPED and re-queues itself, so the delayed
work still fires after the instance has been freed.

Treat CXPOLL_SHUTDOWN like CXPOLL_STOPPED when deciding whether to
reschedule, so a running worker cannot re-queue itself during unbind.
---
 drivers/usb/atm/cxacru.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/atm/cxacru.c b/drivers/usb/atm/cxacru.c
index f1900c567ba..a9902973914 100644
--- a/drivers/usb/atm/cxacru.c
+++ b/drivers/usb/atm/cxacru.c
@@ -923,7 +923,8 @@ static void cxacru_poll_status(struct work_struct *work)
 				instance->line_status == 0) /* down */
 		instance->poll_state = CXPOLL_STOPPED;
 
-	if (instance->poll_state == CXPOLL_STOPPED)
+	if (instance->poll_state == CXPOLL_STOPPED ||
+	    instance->poll_state == CXPOLL_SHUTDOWN)
 		keep_polling = 0;
 	mutex_unlock(&instance->poll_state_serialize);
 

---
base-commit: 848acc8ffe1b7cd5f1bf427b93069becfebc2c9d
change-id: 20260804-usb-atm-cxacru-stop-polling-on-device-shutdown-bc9c6f771624

Best regards,
--  
Anuj Bolewar <bolewara@gmail.com>

