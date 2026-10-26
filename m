From: Enric Balletbo i Serra <eballetb@redhat.com>
Date: Mon, 26 Oct 2026 09:44:34 +0100
Subject: [PATCH 3/3] clocksource/drivers/nxp-stm: Increase min_delta to
 20us for PREEMPT_RT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-nxp-stm-fixes-v1-3-20a64a4ea454@redhat.com>
References: <20261026-nxp-stm-fixes-v1-0-20a64a4ea454@redhat.com>
In-Reply-To: <20261026-nxp-stm-fixes-v1-0-20a64a4ea454@redhat.com>
To: Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Sebastian Andrzej Siewior <bigeasy@linutronix.de>, 
 Clark Williams <clrkwllms@kernel.org>, Steven Rostedt <rostedt@goodmis.org>
Cc: linux-kernel@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-rt-devel@lists.linux.dev, 
 Enric Balletbo i Serra <eballetb@redhat.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793004293; l=1611;
 i=eballetb@redhat.com; s=20261026; h=from:subject:message-id;
 bh=2oVeDkpoG/kZGujP8YpSokhvVMo8D6Pr1tME75FCvYQ=;
 b=oJOj++Ax9eLtn9MXj4cg6VRzFKwnoiO5tNLT0d23izNOmKsdtC/1h8bWWET1Y35f76g/bOVb0
 XhycJ+0Wl1tApeDDk7ptKBEbENZ1EAQRpXw1C/GUzgfGlAMb2CHSQBl
X-Developer-Key: i=eballetb@redhat.com; a=ed25519;
 pk=5zh6xuAxTiQwglL2NXQFqWuyRPmCE8T5KPXLbNXhnKI=
X-Endpoint-Received: by B4 Relay for eballetb@redhat.com/20261026 with auth_id=1324
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Under bus contention on PREEMPT_RT kernels, the 2us min_delta is too
small and the counter can advance past the programmed comparator value
before the overshoot check runs. While the -ETIME fallback handles this
case, repeated retries add latency. Increase min_delta to 20us to reduce
collision probability.

Cc: stable@vger.kernel.org
Signed-off-by: Enric Balletbo i Serra <eballetb@redhat.com>
---
 drivers/clocksource/timer-nxp-stm.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/clocksource/timer-nxp-stm.c b/drivers/clocksource/timer-nxp-stm.c
index ed7662a4e2bc..a0761d7f8b01 100644
--- a/drivers/clocksource/timer-nxp-stm.c
+++ b/drivers/clocksource/timer-nxp-stm.c
@@ -335,14 +335,14 @@ static int nxp_stm_clockevent_starting_cpu(unsigned int cpu)
 	/*
 	 * The timings measurement show reading the counter register
 	 * and writing to the comparator register takes as a maximum
-	 * value 1100 ns at 133MHz rate frequency. The timer must be
-	 * set above this value and to be secure we set the minimum
-	 * value equal to 2000ns, so 2us.
+	 * value 1100 ns at 133MHz rate frequency. However, under bus
+	 * contention on PREEMPT_RT, 2us is too small and causes missed
+	 * matches resulting in 32s wraparounds. Increase to 20us.
 	 *
-	 * minimum ticks = (rate / MICRO) * 2
+	 * minimum ticks = (rate / MICRO) * 20
 	 */
 	clockevents_config_and_register(&stm_timer->ced, stm_timer->rate,
-					(stm_timer->rate / MICRO) * 2, 0x7FFFFFFFU);
+					(stm_timer->rate / MICRO) * 20, 0x7FFFFFFFU);
 
 	return 0;
 }

-- 
2.52.0

