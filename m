From: Rodrigo Cataldo <rodrigo.cadore@l-acoustics.com>
Date: Mon, 08 Jul 2024 11:31:57 +0200
Subject: [PATCH iwl-net] igc: Ensure PTM request is completed before
 timeout has started
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240708-igc-flush-ptm-request-before-timeout-6-10-v1-1-70e5ebec9efe@l-acoustics.com>
X-B4-Tracking: v=1; b=H4sIAAyyi2YC/x3NSwqDMBRG4a3IHfdCDDal3UrpwMY/ekETm0cVx
 L03dPhNzjkoIQoSPZqDIr6SJPiK9tKQnXo/gmWoJq10p27qyjJadnNJE6954YhPQcr8hgsRnGV
 BKJkNt4qdgdL2bpwZOqq9NcLJ/n89SbaZPTK9zvMHM7PALoQAAAA=
To: Jesse Brandeburg <jesse.brandeburg@intel.com>, 
 Tony Nguyen <anthony.l.nguyen@intel.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Vinicius Costa Gomes <vinicius.gomes@intel.com>, 
 Kurt Kanzenbach <kurt.kanzenbach@linutronix.de>, 
 "Christopher S. Hall" <christopher.s.hall@intel.com>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Rodrigo Cataldo <rodrigo.cadore@l-acoustics.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=11903;
 i=rodrigo.cadore@l-acoustics.com; h=from:subject:message-id;
 bh=Wfg75g71XmXkv4d1mekMWpTpqpPeT5sIegVpLSTXqac=;
 b=owGbwMvMwCGWd67IourLsUDG02pJDGndm4SDe2rWaU5LS9nG91Q5ameo1u2GTUn/a/imP74VF
 7DqSvuljlIWBjEOBlkxRRb933xOq8uUjDgSJ6+EmcPKBDKEgYtTACZSE8bwP1HI4VDd85nKhh//
 LTjbek16i3PDpzXdZ1ds8LjxaeNxkzKGf3Y7eF7fZmVQcktRZ51/WK306uHtpwpNlbwXhigFsT1
 cyAcA
X-Developer-Key: i=rodrigo.cadore@l-acoustics.com; a=openpgp;
 fpr=E0F4E67DE69A235AC356157D2DDD1455748BC38F
X-Endpoint-Received: by B4 Relay for rodrigo.cadore@l-acoustics.com/default with auth_id=109
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a PTM is requested via wr32(IGC_PTM_STAT), the operation may only
be completed by the next read operation (flush). Unfortunately, the next
read operation in the PTM request loop happens after we have already
started evaluating the response timeout.

Thus, the following behavior has been observed::

  phc2sys-1655  [010]   103.233752: funcgraph_entry:                    |  igc_ptp_getcrosststamp() {
  phc2sys-1655  [010]   103.233754: funcgraph_entry:                    |    igc_phc_get_syncdevice_time() {
  phc2sys-1655  [010]   103.233755: funcgraph_entry:                    |      igc_rd32() {
  phc2sys-1655  [010]   103.233931: preempt_disable: caller=irq_enter_rcu+0x14 parent=irq_enter_rcu+0x14
  phc2sys-1655  [010]   103.233932: local_timer_entry: vector=236
  phc2sys-1655  [010]   103.233932: hrtimer_cancel: hrtimer=0xffff8edeef526118
  phc2sys-1655  [010]   103.233933: hrtimer_expire_entry: hrtimer=0xffff8edeef526118 now=103200127876 function=tick_nohz_handler/0x0

  ... tick handler ...

  phc2sys-1655  [010]   103.233971: funcgraph_exit:       !  215.559 us |      }
  phc2sys-1655  [010]   103.233972: funcgraph_entry:                    |      igc_rd32() {
  phc2sys-1655  [010]   103.234135: funcgraph_exit:       !  164.370 us |      }
  phc2sys-1655  [010]   103.234136: funcgraph_entry:         1.942 us   |      igc_rd32();
  phc2sys-1655  [010]   103.234147: console:              igc 0000:03:00.0 enp3s0: Timeout reading IGC_PTM_STAT register

Based on the (simplified) code::

	ctrl = rd32(IGC_PTM_CTRL);
        /* simplified: multiple writes here */
	wr32(IGC_PTM_STAT, IGC_PTM_STAT_VALID);

	err = readx_poll_timeout(rd32, IGC_PTM_STAT, stat,
				 stat, IGC_PTM_STAT_SLEEP,
				 IGC_PTM_STAT_TIMEOUT);
	if (err < 0) {
		netdev_err(adapter->netdev, "Timeout reading IGC_PTM_STAT register\n");
		return err;
	}

Where readx_poll_timeout() starts the timeout evaluation before calling
the rd32() parameter (rd32() is a macro for igc_rd32()).

In the trace shown, the read operation of readx_poll_timeout() (second
igc_rd32()) took so long that the timeout (IGC_PTM_STAT_VALID) has expired
and no sleep has been performed.

With this patch, a write flush is added (which is an additional
igc_rd32() in practice) that can wait for the write before the timeout
is evaluated::

  phc2sys-1615  [010]    74.517954: funcgraph_entry:                    |  igc_ptp_getcrosststamp() {
  phc2sys-1615  [010]    74.517956: funcgraph_entry:                    |    igc_phc_get_syncdevicetime() {
  phc2sys-1615  [010]    74.517957: funcgraph_entry:                    |      igc_rd32() {
  phc2sys-1615  [010]    74.518127: preempt_disable: caller=irq_enter_rcu+0x14 parent=irq_enter_rcu+0x14
  phc2sys-1615  [010]    74.518128: local_timer_entry: vector=236
  phc2sys-1615  [010]    74.518128: hrtimer_cancel: hrtimer=0xffff96466f526118
  phc2sys-1615  [010]    74.518128: hrtimer_expire_entry: hrtimer=0xffff96466f526118 now=74484007229 function=tick_nohz_handler/0x0

  ... tick handler ...

  phc2sys-1615  [010]    74.518180: funcgraph_exit:       !  222.282 us |      }
  phc2sys-1615  [010]    74.518181: funcgraph_entry:                    |      igc_rd32() {
  phc2sys-1615  [010]    74.518349: funcgraph_exit:       !  168.160 us |      }
  phc2sys-1615  [010]    74.518349: funcgraph_entry:         1.970 us   |      igc_rd32();
  phc2sys-1615  [010]    74.518352: hrtimer_init: hrtimer=0xffffa6f9413a3940 clockid=CLOCK_MONOTONIC mode=0x0
  phc2sys-1615  [010]    74.518352: preempt_disable: caller=_raw_spin_lock_irqsave+0x28 parent=hrtimer_start_range_ns+0x56
  phc2sys-1615  [010]    74.518353: hrtimer_start: hrtimer=0xffffa6f9413a3940 function=hrtimer_wakeup/0x0 expires=74484232878 softexpires=74484231878

  .. hrtimer setup and return ...

  kworker/10:1-242   [010]    74.518382: sched_switch: kworker/10:1:242 [120] W ==> phc2sys:1615 [120]
  phc2sys-1615  [010]    74.518383: preempt_enable: caller=schedule+0x36 parent=schedule+0x36
  phc2sys-1615  [010]    74.518384: funcgraph_entry:      !  100.088 us |      igc_rd32();
  phc2sys-1615  [010]    74.518484: funcgraph_entry:         1.958 us   |      igc_rd32();
  phc2sys-1615  [010]    74.518488: funcgraph_entry:         2.019 us   |      igc_rd32();
  phc2sys-1615  [010]    74.518490: funcgraph_entry:         1.956 us   |      igc_rd32();
  phc2sys-1615  [010]    74.518492: funcgraph_entry:         1.980 us   |      igc_rd32();
  phc2sys-1615  [010]    74.518494: funcgraph_exit:       !  539.386 us |    }

Now the sleep is called as expected, and the operation succeeds.
Therefore, regardless of how long it will take for the write to be
completed, we will poll+sleep at least for the time specified in
IGC_PTM_STAT_TIMEOUT.

Fixes: a90ec8483732 ("igc: Add support for PTP getcrosststamp()")
Signed-off-by: Rodrigo Cataldo <rodrigo.cadore@l-acoustics.com>
---
I have been searching for the proper solution for this PTM issue for a long
time. The issue was observed on a 13700 (Raptor Lake). We also use a 8500
(Coffee Lake) that is much less susceptible for this issue, but still
happens. Both are using I225-LM cards.

For a 24 hours test, idle system, I have observed with 13700::

	number of timeouts in 86400 seconds: 2509

The same test on a 8500::

        number of timeouts in 86400 seconds: 9

Where one PTM request is sent per second. Test was done this script::

  record_multiple_timeout_param()
  {
  	local taskset_cpu=$1
  	local cur_limit=$((SECONDS + LIMIT_SECONDS ))
  	local timeouts=0
  
  	while [ $SECONDS -lt $cur_limit ]
  	do
  		REL_TO=$((cur_limit - SECONDS))
  
  		timeout $REL_TO taskset $taskset_cpu \
  			phc2sys -c $ITF_NAME -s CLOCK_REALTIME -O 37 -m 1>/dev/null
  		if [ $? -eq 255 ]; then
  			timeouts=$((timeouts + 1))
  		fi
  	done
  	printf "\tnumber of timeouts in %s seconds: %d\n" $LIMIT_SECONDS $timeouts
  }

  record_multiple_timeout_param $NON_ISOLCPU_MASK

Firmware version for the cards::

  # lshw -class network -json | jq '.[0].product,.[0].configuration.firmware'
  "Ethernet Controller I225-LM"
  "1057:8754"

  # lshw -class network -json | jq '.[2].product,.[2].configuration.firmware'
  "Ethernet Controller I225-LM"
  "1057:8754

A couple of attempts were made that did not lead to solving the
issue (disabling ASPM in kernel and boot, using periodic tick), and a couple
of solutions that worked but that were subpar:

1. The issue was not observed for a phc2sys(8) running on a fully
   isolated nohz_full core. We do not have the luxury of dedicating a a
   core for it.
2. Bumping the IGC_PTM_STAT_TIMEOUT value. Other machines may need
   another value though.
3. Retry (multiple times) readx_poll_timeout() in case of failure. This may
   significantly increase the function latency, because each
   readx_poll_timeout() can take more than 100 us.
4. Disabling preemption during the PTM request. Horrible.

For the Coffee Lake machine, the issue tends to be avoided because the
read does not take so long. Here is basically the same trace using the
Cofee Lake machine::

  phc2sys-1204  [002]  1778.220288: funcgraph_entry:                    |  igc_ptp_getcrosststamp() {
  phc2sys-1204  [002]  1778.220290: funcgraph_entry:                    |    igc_phc_get_syncdevicetime() {
  phc2sys-1204  [002]  1778.220291: funcgraph_entry:                    |      igc_rd32() {
  phc2sys-1204  [002]  1778.220373: preempt_disable: caller=irq_enter_rcu+0x14 parent=irq_enter_rcu+0x14
  phc2sys-1204  [002]  1778.220374: local_timer_entry: vector=236
  phc2sys-1204  [002]  1778.220375: hrtimer_cancel: hrtimer=0xffff894027326118
  phc2sys-1204  [002]  1778.220376: hrtimer_expire_entry: hrtimer=0xffff894027326118 now=1778228034802 function=tick_nohz_handler/0x0

  ... tick handler ...

  phc2sys-1204  [002]  1778.220411: funcgraph_exit:       !  119.843 us |      }
  phc2sys-1204  [002]  1778.220412: funcgraph_entry:                    |      igc_rd32() {
  phc2sys-1204  [002]  1778.220492: funcgraph_exit:       + 80.094 us   |      }
  phc2sys-1204  [002]  1778.220493: funcgraph_entry:        2.951 us    |      igc_rd32();
  phc2sys-1204  [002]  1778.220497: hrtimer_init: hrtimer=0xffffa504c0d83aa0 clockid=CLOCK_MONOTONIC mode=0x0
  phc2sys-1204  [002]  1778.220498: preempt_disable: caller=_raw_spin_lock_irqsave+0x28 parent=hrtimer_start_range_ns+0x56
  phc2sys-1204  [002]  1778.220499: hrtimer_start: hrtimer=0xffffa504c0d83aa0 function=hrtimer_wakeup/0x0 expires=1778228158866 softexpires=1778228157866

  ... timer setup ....

  phc2sys-1204  [002]  1778.220509: preempt_enable: caller=_raw_spin_unlock_irqrestore+0x2b parent=hrtimer_start_range_ns+0x12d
  phc2sys-1204  [002]  1778.220511: funcgraph_entry:        7.338 us   |      igc_rd32();
  phc2sys-1204  [002]  1778.220519: funcgraph_entry:        2.769 us   |      igc_rd32();
  phc2sys-1204  [002]  1778.220522: funcgraph_entry:        2.798 us   |      igc_rd32();
  phc2sys-1204  [002]  1778.220525: funcgraph_entry:        2.736 us   |      igc_rd32();
  phc2sys-1204  [002]  1778.220529: funcgraph_entry:        2.750 us   |      igc_rd32();
  phc2sys-1204  [002]  1778.220532: funcgraph_exit:       !  242.656 us |    }

For both machines, I observed that the first igc_rd32() after an idle
period (more than 10us) tends to take significantly more time. I assume
this is a hardware power-saving technique, but I could not find any
mention in the manuals. This is very easily observable with an idle
system running phc2sys, since it will request only once every second.

This is the typical trace of the operation::

  phc2sys-1204  [002]  1749.209397: funcgraph_entry:                   |  igc_ptp_getcrosststamp() {
  phc2sys-1204  [002]  1749.209398: funcgraph_entry:                   |    igc_phc_get_syncdevicetime() {
  phc2sys-1204  [002]  1749.209400: funcgraph_entry:      + 81.491 us  |      igc_rd32();
  phc2sys-1204  [002]  1749.209482: funcgraph_entry:        3.691 us   |      igc_rd32();
  phc2sys-1204  [002]  1749.209487: funcgraph_entry:        2.942 us   |      igc_rd32();
  phc2sys-1204  [002]  1749.209490: hrtimer_init: hrtimer=0xffffa504c0d83a00 clockid=CLOCK_MONOTONIC mode=0x0
  phc2sys-1204  [002]  1749.209491: preempt_disable: caller=_raw_spin_lock_irqsave+0x28 parent=hrtimer_start_range_ns+0x56
  ... timer setup and it goes on like before ...

The preemption needs to happen for this issue, so that this power-saving
mode is triggered, making the igc_rd32 'slow enough' so that all of the
timeout is consumed before the card has time to answer.

I believe flushing the write solves the issue definitely, since the
write should be completed before the timeout has started. So that, even
if the timeout is consumed by a slow read operation, the write has been
received before and the card had time to process the request.
---
 drivers/net/ethernet/intel/igc/igc_ptp.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/ethernet/intel/igc/igc_ptp.c b/drivers/net/ethernet/intel/igc/igc_ptp.c
index 1bb026232efc..d7269e4f1a21 100644
--- a/drivers/net/ethernet/intel/igc/igc_ptp.c
+++ b/drivers/net/ethernet/intel/igc/igc_ptp.c
@@ -1005,6 +1005,10 @@ static int igc_phc_get_syncdevicetime(ktime_t *device,
 		 * VALID bit.
 		 */
 		wr32(IGC_PTM_STAT, IGC_PTM_STAT_VALID);
+		/* Ensure the hardware receives the ptm request before the
+		 * response timeout starts.
+		 */
+		wrfl();
 
 		err = readx_poll_timeout(rd32, IGC_PTM_STAT, stat,
 					 stat, IGC_PTM_STAT_SLEEP,

---
base-commit: 0005b2dc43f96b93fc5b0850d7ca3f7aeac9129c
change-id: 20240705-igc-flush-ptm-request-before-timeout-6-10-f6e02c96f6d4

Best regards,
-- 
Rodrigo Cataldo <rodrigo.cadore@l-acoustics.com>

