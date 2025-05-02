From: Paul Cacheux <paulcacheux@gmail.com>
Date: Fri, 02 May 2025 15:15:53 +0200
Subject: [PATCH v2 2/2] tracing: protect trace_probe_log with mutex
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250502-fix-trace-probe-log-race-v2-2-511ecc1521ec@gmail.com>
References: <20250502-fix-trace-probe-log-race-v2-0-511ecc1521ec@gmail.com>
In-Reply-To: <20250502-fix-trace-probe-log-race-v2-0-511ecc1521ec@gmail.com>
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Namhyung Kim <namhyung@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 Paul Cacheux <paulcacheux@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746191767; l=1822;
 i=paulcacheux@gmail.com; s=20250422; h=from:subject:message-id;
 bh=JoafqU4uAGl3ydwos4FNrWPAGaAC2MqNPKDgQHWMZCs=;
 b=KcHSfL163DKlJ1NliuUUMQWzwqr+MsVP+H2ve6fE7oWXWJIIhlwtWCk5QHPT/9rTaAJKOXtz9
 bdzZoYkn6hnDJpyf2/hgWq0lNlOdrSgxB9BIXHG4TaBqtYSIu27wspw
X-Developer-Key: i=paulcacheux@gmail.com; a=ed25519;
 pk=8UguSecyECHKHp0YLS7hTEDob0ctFMr3ygBTeAmrFHs=
X-Endpoint-Received: by B4 Relay for paulcacheux@gmail.com/20250422 with auth_id=386
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The shared trace_probe_log variable can be accessed and modified
by multiple processes using tracefs at the same time, this new
mutex will guarantee it's always in a coherent state.

There is no guarantee that multiple errors happening at the same
time will each have the correct error message, but at least this
won't crash.

Fixes: ab105a4fb894 ("tracing: Use tracing error_log with probe events")

Signed-off-by: Paul Cacheux <paulcacheux@gmail.com>
---
 kernel/trace/trace_probe.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/kernel/trace/trace_probe.c b/kernel/trace/trace_probe.c
index 2eeecb6c95eea55502b83af6775b7b6f0cc5ab94..14a7a0b59cd20a8bc43e3e7c653e986081f924c8 100644
--- a/kernel/trace/trace_probe.c
+++ b/kernel/trace/trace_probe.c
@@ -154,9 +154,11 @@ static const struct fetch_type *find_fetch_type(const char *type, unsigned long
 }
 
 static struct trace_probe_log trace_probe_log;
+static DEFINE_MUTEX(trace_probe_log_lock);
 
 void trace_probe_log_init(const char *subsystem, int argc, const char **argv)
 {
+	guard(mutex)(&trace_probe_log_lock);
 	trace_probe_log.subsystem = subsystem;
 	trace_probe_log.argc = argc;
 	trace_probe_log.argv = argv;
@@ -165,11 +167,13 @@ void trace_probe_log_init(const char *subsystem, int argc, const char **argv)
 
 void trace_probe_log_clear(void)
 {
+	guard(mutex)(&trace_probe_log_lock);
 	memset(&trace_probe_log, 0, sizeof(trace_probe_log));
 }
 
 void trace_probe_log_set_index(int index)
 {
+	guard(mutex)(&trace_probe_log_lock);
 	trace_probe_log.index = index;
 }
 
@@ -178,6 +182,8 @@ void __trace_probe_log_err(int offset, int err_type)
 	char *command, *p;
 	int i, len = 0, pos = 0;
 
+	guard(mutex)(&trace_probe_log_lock);
+
 	if (!trace_probe_log.argv)
 		return;
 

-- 
2.49.0

