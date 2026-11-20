From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Subject: [PATCH sched_ext/for-7.5 0/2] sched_ext: idle: Don't stack a sync
 wakee behind a higher-class task
Date: Fri, 20 Nov 2026 16:44:21 +0800
Message-Id: <20261120-scx-fix75-v1-0-254f782ff9b0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MwQqDMBAFf0X27LYmxVj8FSkSk2fdi5aslID47
 waPwwxzkCIJlPrqoIS/qGxrAVNXFBa/fsESC5NtrDPGNqwh8yy5a9m/nXfxZRAwUel/CUXcr4E
 0LIgj8v6ct8Tdo6XPeV6lfDYwbgAAAA==
X-Change-ID: 20261120-scx-fix75-a86a6d31eceb
To: Tejun Heo <tj@kernel.org>, David Vernet <void@manifault.com>, 
 Andrea Righi <arighi@nvidia.com>, Changwoo Min <changwoo@igalia.com>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Shuah Khan <shuah@kernel.org>
Cc: Kuba Piecuch <jpiecuch@google.com>, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>, 
 Hui Su <sh_def@163.com>, sched-ext@lists.linux.dev, 
 linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, 
 Hang Zhengyang <hang.zhengyang1010@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795164273; l=3044;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=+c5iTcPGpkwPWTC0M/a6nppfpfe0VFKGA2gyib/nlzg=;
 b=KW5iaCyxdPLwsuWYUfdcxn+/B/rhaa9ybvCDWxHbFnLzoMGK/ua2uAo1eyZbM26DtaqeMjoNT
 /RSr1OFRAP7C/J88aluS8E8yimXJKoTVA1UpY4PE5aTqlrBvdSYk7EW
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In sched_ext, the default idle CPU selection can put a sync wakee on
the waker's CPU, even when the waker is an RT or DL task that keeps
running. The wakee then waits there, sometimes for more than a second,
while other CPUs are idle. Patch 1 stops this for higher-class wakers.
Patch 2 adds a selftest that fails without patch 1.

Tested on sched_ext/for-7.5 (c6cc52a72055) in an 8 vCPU KVM guest,
non-debug kernel, booting each kernel twice:

                               before               after
  RT waker, pipe               16/16 on CPU 0,      idle CPU,
                               169 ms - 1.5 s       <= 0.6 ms
  same, ALWAYS_ENQ_IMMED       16/16 late by        <= 0.6 ms
                               16-483 ms
  partial, fair waker          16/16 on CPU 0,      <= 0.6 ms
                               half ~930 ms late
  sync_wake_rt, 8/3/2 vCPUs    fails                passes
  other sched_ext selftests    no change            no change

With KASAN and lockdep on v7.4-rc2, sync_wake_rt fails without the fix
and passes with it, with no warnings. If other tasks keep all CPUs
busy, the test passes on both kernels, because the shortcut is only
used when some CPU is idle. On bare metal I could only run an
unpatched distro v7.0 kernel, because of Secure Boot. It has the same
problem: the reader waited 168 ms or more.

The cost: after a sync wakeup from a higher-class task, the wakee no
longer runs on the waker's CPU. WF_SYNC doesn't promise this anyway.
In a pipe ping-pong between an RT task and an EXT task, a round trip
now takes ~9.8 us instead of ~6.5 us, because the EXT task stays on
its own CPU. CFS also takes ~10 us here. The difference can be bigger
on large non-SMT machines [1]. That series detects pairs of tasks that
wake each other. If fair adopts it, we could keep the shortcut for
such pairs.

There is no Fixes tag. The shortcut has been there since sched_ext was
added, and this patch changes where a task runs, not whether the
kernel works correctly.

Hui Su's patch "sched_ext: idle: Honor SCX_PICK_IDLE_CORE in CPU
selection shortcuts" changes the line just before this code. Whichever
patch is applied second will need a small rebase.

I used Claude Code to find the issue, write the patches and run the
tests. I reproduced the issue on bare metal and reviewed the patches.

[1] https://lore.kernel.org/all/20261021-b4-sched-sync-wakeup-v7-1-91995ba5b596@gentwo.org/

---
Hang Zhengyang (2):
      sched_ext: idle: Don't stack a sync wakee behind a higher-class task
      selftests/sched_ext: Test sync wakeups from an RT task

 kernel/sched/ext/idle.c                          |  11 +
 tools/testing/selftests/sched_ext/Makefile       |   1 +
 tools/testing/selftests/sched_ext/sync_wake_rt.c | 257 +++++++++++++++++++++++
 3 files changed, 269 insertions(+)
---
base-commit: c6cc52a72055ef9775b39937d02e39ca358ba042
change-id: 20261120-scx-fix75-a86a6d31eceb

Best regards,
-- 
Hang Zhengyang <hang.zhengyang1010@gmail.com>

