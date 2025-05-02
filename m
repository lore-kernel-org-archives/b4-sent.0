From: Paul Cacheux <paulcacheux@gmail.com>
Subject: [PATCH v2 0/2] tracing: fix race when creating trace probe log
 error message
Date: Fri, 02 May 2025 15:15:51 +0200
Message-Id: <20250502-fix-trace-probe-log-race-v2-0-511ecc1521ec@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIfFFGgC/3WNwQqDMBBEf0X23C1mUWp76n+Ih7hZdUGNJCIt4
 r83FXrs8Q0zb3aIElQiPLIdgmwa1c8J6JIBD3buBdUlBsqpzAvKsdMXrsGy4BJ8Kzj6Hk9kru6
 ukrJrTQlpvgRJ3VNdN4kHjasP7/NpM9/0J6X/0s2gQUc3qlxBbLl99pPV8cp+guY4jg+FG8taw
 AAAAA==
X-Change-ID: 20250420-fix-trace-probe-log-race-cc89d8e5fb15
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Namhyung Kim <namhyung@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 Paul Cacheux <paulcacheux@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746191767; l=1762;
 i=paulcacheux@gmail.com; s=20250422; h=from:subject:message-id;
 bh=KpVvY39bTMtM8+XE+uRP1OauAipaWPrZAaSpJuBqdO0=;
 b=s8QdfrlRuuLv1kCYAOYbz7sqfW+OGlxZHlYqubZkhTMzCambp3fmi+4UXmyPonECg6Tmq5sz6
 uBRkEVWeSKwAS9oLzA5Dy20Rx4Dh6VcEST8GzIp3WzBUADunE+GSC3D
X-Developer-Key: i=paulcacheux@gmail.com; a=ed25519;
 pk=8UguSecyECHKHp0YLS7hTEDob0ctFMr3ygBTeAmrFHs=
X-Endpoint-Received: by B4 Relay for paulcacheux@gmail.com/20250422 with auth_id=386
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello,

As reported in [1] a race exists in the shared trace probe log
used to build error messages. This can cause kernel crashes
when building the actual error message, but the race happens
even for non-error tracefs uses, it's just not visible.

Reproducer first reported that is still crashing:

  # 'p4' is invalid command which make kernel run into trace_probe_log_err()
  cd /sys/kernel/debug/tracing
  while true; do
    echo 'p4:myprobe1 do_sys_openat2 dfd=%ax filename=%dx flags=%cx mode=+4($stack)' >> kprobe_events &
    echo 'p4:myprobe2 do_sys_openat2' >> kprobe_events &
    echo 'p4:myprobe3 do_sys_openat2 dfd=%ax filename=%dx' >> kprobe_events &
  done;

The original email suggested to use a mutex or to allocate the
trace_probe_log on the stack. This patch implements a simpler
solution suggest during the review of the v1 where we only protect
access to the shared trace_probe_log with a mutex. This will prevent
any crash from happening.

[1] https://lore.kernel.org/all/20221121081103.3070449-1-zhengyejian1@huawei.com/T/

Signed-off-by: Paul Cacheux <paulcacheux@gmail.com>
---
Changes in v2:
- change approach, and use the mutex based solution suggested during
  review
- Link to v1: https://lore.kernel.org/r/20250422-fix-trace-probe-log-race-v1-1-d2728d42cacb@gmail.com

---
Paul Cacheux (2):
      tracing: add missing trace_probe_log_clear for eprobes
      tracing: protect trace_probe_log with mutex

 kernel/trace/trace_eprobe.c | 3 +++
 kernel/trace/trace_probe.c  | 6 ++++++
 2 files changed, 9 insertions(+)
---
base-commit: ebd297a2affadb6f6f4d2e5d975c1eda18ac762d
change-id: 20250420-fix-trace-probe-log-race-cc89d8e5fb15

Best regards,
-- 
Paul Cacheux <paulcacheux@gmail.com>

