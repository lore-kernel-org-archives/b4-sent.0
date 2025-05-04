From: Paul Cacheux <paulcacheux@gmail.com>
Date: Sun, 04 May 2025 20:27:53 +0200
Subject: [PATCH v3 2/2] tracing: protect trace_probe_log with mutex
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250504-fix-trace-probe-log-race-v3-2-9e99fec7eddc@gmail.com>
References: <20250504-fix-trace-probe-log-race-v3-0-9e99fec7eddc@gmail.com>
In-Reply-To: <20250504-fix-trace-probe-log-race-v3-0-9e99fec7eddc@gmail.com>
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Namhyung Kim <namhyung@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 Paul Cacheux <paulcacheux@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746383319; l=2188;
 i=paulcacheux@gmail.com; s=20250422; h=from:subject:message-id;
 bh=JLwkOJEumGD7YD+nexmmI4MTQQL+hh9/f9FKhif6SKY=;
 b=fVewTZB5G2vWsu+/Kz4Ut/he1vI/StVN88Rdda3rjXLMq6aLMqZRKzi5Julu87MoiHFUqbwGK
 KXnbai+dRHTD56OINMEWdcXKsCdj4mMvmKKgRuU/nETJv2mSlto3Dho
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
 kernel/trace/trace_probe.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/kernel/trace/trace_probe.c b/kernel/trace/trace_probe.c
index 2eeecb6c95eea55502b83af6775b7b6f0cc5ab94..d538964c87a52b06646ec1b8c3469be7399f04fa 100644
--- a/kernel/trace/trace_probe.c
+++ b/kernel/trace/trace_probe.c
@@ -153,10 +153,19 @@ static const struct fetch_type *find_fetch_type(const char *type, unsigned long
 	return NULL;
 }
 
+/*
+ * The trace_probe_log_lock only protects against the individual
+ * modification of the trace_probe_log. It does not protect against
+ * the log from producing garbage if two probes use it at the same
+ * time. That would only happen if two admins were trying to add
+ * probes simultaneously which they shouldn't be doing.
+ */
+static DEFINE_MUTEX(trace_probe_log_lock);
 static struct trace_probe_log trace_probe_log;
 
 void trace_probe_log_init(const char *subsystem, int argc, const char **argv)
 {
+	guard(mutex)(&trace_probe_log_lock);
 	trace_probe_log.subsystem = subsystem;
 	trace_probe_log.argc = argc;
 	trace_probe_log.argv = argv;
@@ -165,11 +174,13 @@ void trace_probe_log_init(const char *subsystem, int argc, const char **argv)
 
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
 
@@ -178,6 +189,8 @@ void __trace_probe_log_err(int offset, int err_type)
 	char *command, *p;
 	int i, len = 0, pos = 0;
 
+	guard(mutex)(&trace_probe_log_lock);
+
 	if (!trace_probe_log.argv)
 		return;
 

-- 
2.49.0

