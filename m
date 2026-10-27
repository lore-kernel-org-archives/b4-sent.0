From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 27 Oct 2026 16:09:11 -0400
Subject: [PATCH] smp: use READ_ONCE() for csd flags in the async path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-kcsan-smp-v1-1-57a4949106b2@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDWhUn9XEYuqwRAlHUQi7q5Yf
 snLu4DRETKUwQUOD2JarEccBmAGbXsU1HqDjGQaRzITk2FtBc+raIs0zxKFUuUafL867Oj8XlX
 9m/dmRLO9A7jvB8vwzeltAAAA
X-Change-ID: 20261027-kcsan-smp-d968735e258a
To: Thomas Gleixner <tglx@kernel.org>, 
 Peter Zijlstra <peterz@infradead.org>
Cc: "Paul E. McKenney" <paulmck@kernel.org>, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793131751; l=1644;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=UoFjy57HrPBIOxXCXeP3uYlJT7z/vKDqaE0Wh7LGDd0=;
 b=x7adRW74xgRXMnSNCFytKDR3tGpRQYNd5Xq5Rwgy6uluIYTB0ImYyGIO+yuAAx5uoHCclt+Hi
 /FK6aZPiX2uCqfqOXSXN0V+WJDYE7Y2YLfr1M8M1AqXDRNfUH8j78Vk
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smp_call_function_single_async() checks CSD_FLAG_LOCK without a lock
while the target CPU may be clearing it.  The race is harmless, since a
stale read only sees the flag still set and returns -EBUSY.  Use
READ_ONCE() like the other lockless readers of u_flags in this file.

  [   18.136106] BUG: KCSAN: data-race in __flush_smp_call_function_queue / smp_call_function_single_async

  [   18.136218] write (marked) to 0xff1100002b62b608 of 4 bytes by interrupt on cpu 0:
  [   18.136269]  __flush_smp_call_function_queue+0x36b/0xda0
  [   18.136338]  generic_smp_call_function_single_interrupt+0xf/0x10
  ...

  [   18.139279] read to 0xff1100002b62b608 of 4 bytes by task 235 on cpu 1:
  [   18.139327]  smp_call_function_single_async+0x22/0xb0
  [   18.139396]  enqueue_task+0x25/0xf0
  ...

  [   18.157072] value changed: 0x00000001 -> 0x00000000

Found with KCSAN while fuzzing under a deterministic hypervisor that's
currently under development.

Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 kernel/smp.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/kernel/smp.c b/kernel/smp.c
index 89a30d831ef5..8064652747ea 100644
--- a/kernel/smp.c
+++ b/kernel/smp.c
@@ -822,7 +822,7 @@ int smp_call_function_single_async(int cpu, call_single_data_t *csd)
 
 	preempt_disable();
 
-	if (csd->node.u_flags & CSD_FLAG_LOCK) {
+	if (READ_ONCE(csd->node.u_flags) & CSD_FLAG_LOCK) {
 		err = -EBUSY;
 		goto out;
 	}

---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20261027-kcsan-smp-d968735e258a

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

