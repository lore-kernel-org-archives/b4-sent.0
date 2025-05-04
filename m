From: Paul Cacheux <paulcacheux@gmail.com>
Date: Sun, 04 May 2025 20:27:52 +0200
Subject: [PATCH v3 1/2] tracing: add missing trace_probe_log_clear for
 eprobes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250504-fix-trace-probe-log-race-v3-1-9e99fec7eddc@gmail.com>
References: <20250504-fix-trace-probe-log-race-v3-0-9e99fec7eddc@gmail.com>
In-Reply-To: <20250504-fix-trace-probe-log-race-v3-0-9e99fec7eddc@gmail.com>
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Namhyung Kim <namhyung@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 Paul Cacheux <paulcacheux@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746383319; l=788;
 i=paulcacheux@gmail.com; s=20250422; h=from:subject:message-id;
 bh=Nem7XKEmMcHI5glWY7jEUqZtjAQzjhIH+nS5TNvLewM=;
 b=uErPiOew5kdUhskb+0wBgOnfEYN78yNGP/MAUmbu0StBUMwKBsonBomXxZHuwKWM5lfKnafRO
 cAMKUWkwDX+ApWIVlSff2FCh54bhhWFcLZc8sZgwXyZO/w2uej+CsZQ
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

