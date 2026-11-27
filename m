From: Igor Velkov <iav@iav.lv>
Subject: [PATCH RFC 00/10] coresight: cpu-debug: Sample CPUs that ignore a
 backtrace request
Date: Fri, 27 Nov 2026 08:38:37 +0200
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-0-69d3ad1e0fc8@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG0lCWsC/x3MSwqDMBAA0KvIrDtghvqh20IP4La40HEShxYTk
 qYI4t0bunybd0CSqJLgVh0Q5atJ/VZgLhXwOm1OUJdioJpaY6jD+YrsoyR16wc5ZFxkzg7fnl8
 5oAix7S031NZQjhDF6v7/nzA87jCe5w8AweO2dAAAAA==
To: Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Mike Leach <mike.leach@arm.com>, James Clark <james.clark@linaro.org>, 
 Leo Yan <leo.yan@arm.com>, Andrew Morton <akpm@linux-foundation.org>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>
Cc: coresight@lists.linaro.org, linux-arm-kernel@lists.infradead.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Douglas Anderson <dianders@chromium.org>, Petr Mladek <pmladek@suse.com>, 
 Feng Tang <feng.tang@linux.alibaba.com>, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3489; i=iav@iav.lv;
 h=from:subject:message-id; bh=gXgmcxVrhW5A349eiU5DHHZZZboqxKqUTaFzFTfYD+g=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNmcqvmvhBccvul/xsgszyM0T225kmO4EZeQvVHkWgWGs
 DMtb451lLIwiHExyIopskw4pHErY8nVv/4e5g9g5rAygQxh4OIUgIl88mH473hLprH6aOZV43tP
 nhhIZVtUCko9Vpz1ZULV7gv5L6wmujMyHH/QPiN2oX1D9dblcoqy2l8Y3kWceqpX0L5HsqaZXdO
 HEwA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A CPU locked up with interrupts masked does not answer a backtrace IPI
unless the IPI is an NMI. This series samples its PC through the
external debug interface where nmi_trigger_cpumask_backtrace() gives up
on it, as discussed with Leo [1], and removes the panic notifier: a
panic alone no longer prints the dump, panic_sys_info=all_bt gives it
for the CPUs that do not respond.

Patches 1-4 fix the driver as it is: the documentation, two runtime PM
issues, and an unbounded loop hit at panic today and on a running
system after patch 8. They do not depend on the rest and can go
separately with Fixes: tags. Patch 5 adds the EDPRSR.R check that 8
relies on, 6 prepares 8, 7 adds the notification to lib/nmi_backtrace.c,
8 adds the hook, 9 removes the panic notifier, 10 lowers the log level.

lib/nmi_backtrace.c has no maintainer entry. I would expect the series
to go through the coresight tree with an ack for patch 7, or patch 7
through mm-nonmm first, whichever you prefer.

Tested on RK3399 (helios64), the series applied on 7.4-rc4, buddy hard
lockup detector, no pseudo-NMI: LKDTM HARDLOCKUP on an A53 and on an A72
gives "EDPCSR: lkdtm_HARDLOCKUP+0x14/0x38". SysRq-l with a CPU spinning
in an IPI handler dumps that CPU and the system keeps running; so does
a panic with panic_sys_info=all_bt. With pseudo-NMI the CPU answers and
nothing is dumped. Not tested: the idle path, the notifier in NMI
context, other SoCs, ACPI; arm32 is only built.

In every run idle_cpu() was 0 for the stuck CPU at the time of the
notification, also for a CPU that entered the spin from its idle task
with all movable tasks moved away, so the idle path was never taken. A
test module running the register sequence of debug_read_regs() on an
idle core raises an SError on RK3399. Should the idle path (with the
EDPRCR power request) and skip_idle stay? Without them patch 7 needs
only the cpumask, debug_force_cpu_powered_up() goes away, and a CPU is
sampled only if EDPRSR shows it accessible. skip_idle defaults to 0 as
proposed in [1]; on RK3399 it would have to be 1.

[1] https://lore.kernel.org/r/20261118104917.GW9176@e132581.arm.com

---
Igor Velkov (10):
      Documentation: coresight: cpu-debug: Fix the module parameter name
      coresight: cpu-debug: Make the enable parameter read-only in sysfs
      coresight: cpu-debug: Publish the per-CPU data under debug_lock
      coresight: cpu-debug: Bound the power up retries
      coresight: cpu-debug: Do not sample a core that is in reset
      coresight: cpu-debug: Factor out debug_read_pcsr()
      lib/nmi_backtrace: notify about CPUs that ignore a backtrace request
      coresight: cpu-debug: Dump CPUs that ignore a backtrace request
      coresight: cpu-debug: Remove the panic notifier
      coresight: cpu-debug: Print the dump at the warning level

 Documentation/admin-guide/kernel-parameters.txt    |  10 +
 .../trace/coresight/coresight-cpu-debug.rst        |  55 +++--
 drivers/hwtracing/coresight/Kconfig                |   8 +-
 drivers/hwtracing/coresight/coresight-cpu-debug.c  | 244 +++++++++++++--------
 include/linux/nmi.h                                |  28 +++
 lib/nmi_backtrace.c                                |  56 +++++
 6 files changed, 283 insertions(+), 118 deletions(-)
---
base-commit: b7d7462c7f973b65de511db6bebb99fb29946ed8
change-id: 20261127-b4-coresight-cpu-debug-lockup-ee2cf8fc5260

Best regards,
-- 
Igor Velkov <iav@iav.lv>

