From: Paul Cacheux <paulcacheux@gmail.com>
Date: Fri, 02 May 2025 15:15:52 +0200
Subject: [PATCH v2 1/2] tracing: add missing trace_probe_log_clear for
 eprobes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250502-fix-trace-probe-log-race-v2-1-511ecc1521ec@gmail.com>
References: <20250502-fix-trace-probe-log-race-v2-0-511ecc1521ec@gmail.com>
In-Reply-To: <20250502-fix-trace-probe-log-race-v2-0-511ecc1521ec@gmail.com>
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Namhyung Kim <namhyung@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 Paul Cacheux <paulcacheux@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746191767; l=788;
 i=paulcacheux@gmail.com; s=20250422; h=from:subject:message-id;
 bh=Nem7XKEmMcHI5glWY7jEUqZtjAQzjhIH+nS5TNvLewM=;
 b=KYKG2TOWU5FBONQSxiwPiN1wLq7a9XhDN50L9Kbh9e7FpkO6aMz3g23Ztn47NNi6e7iybcHGw
 7Hp1gCDmBfCDcnoXyC04q2UmUHOAg1G6R6PbulVP2t8ZQYh/FD0XP/4
X-Developer-Key: i=paulcacheux@gmail.com; a=ed25519;
 pk=8UguSecyECHKHp0YLS7hTEDob0ctFMr3ygBTeAmrFHs=
X-Endpoint-Received: by B4 Relay for paulcacheux@gmail.com/20250422 with auth_id=386
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure trace_probe_log_clear is called in the tracing
eprobe code path, matching the trace_probe_log_init call.

Signed-off-by: Paul Cacheux <paulcacheux@gmail.com>
---
 kernel/trace/trace_eprobe.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/kernel/trace/trace_eprobe.c b/kernel/trace/trace_eprobe.c
index c08355c3ef32b4124ac944d7e3a03efb66492269..916555f0de811f03feed9d923c63078b0e4c993b 100644
--- a/kernel/trace/trace_eprobe.c
+++ b/kernel/trace/trace_eprobe.c
@@ -969,10 +969,13 @@ static int __trace_eprobe_create(int argc, const char *argv[])
 			goto error;
 		}
 	}
+	trace_probe_log_clear();
 	return ret;
+
 parse_error:
 	ret = -EINVAL;
 error:
+	trace_probe_log_clear();
 	trace_event_probe_cleanup(ep);
 	return ret;
 }

-- 
2.49.0

