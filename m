From: Paul Cacheux <paulcacheux@gmail.com>
Date: Tue, 22 Apr 2025 20:33:13 +0200
Subject: [PATCH] tracing: fix race when creating trace probe log error
 message
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250422-fix-trace-probe-log-race-v1-1-d2728d42cacb@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOjgB2gC/x3MQQqAIBCF4avErBswSbCuEi3SJhsIjTEikO6et
 Pzgf69AJmHKMDYFhG7OnGJF1zbg9yUGQl6rQSttVK8VbvzgJYsnPCU5wiMF/Om9HVZLZnOdgTo
 /hWr7X0/z+37sLDWIagAAAA==
X-Change-ID: 20250420-fix-trace-probe-log-race-cc89d8e5fb15
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 Paul Cacheux <paulcacheux@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745346813; l=65097;
 i=paulcacheux@gmail.com; s=20250422; h=from:subject:message-id;
 bh=ZxlkmC/MMKZHlglxRiW100ETEQg5jrB6k9qzOrmAuIs=;
 b=q2Mxf70VFXk6jJCcsqa5VbZ1JHuJmyp9eTuWNWoFqAiId0GYmOanFRPYCkCbq4bqfdkIMAp5o
 psx3pyz1rMZBikwnLrUsw/Y9TzUIQOcuTwhkoOB6NsoWiaAIGgFWl3P
X-Developer-Key: i=paulcacheux@gmail.com; a=ed25519;
 pk=8UguSecyECHKHp0YLS7hTEDob0ctFMr3ygBTeAmrFHs=
X-Endpoint-Received: by B4 Relay for paulcacheux@gmail.com/20250422 with auth_id=386
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When creating a trace probe a global variable is modified and this
data used when an error is raised and the error message generated.

Modification of this global variable is done without any lock and
multiple trace operations will race, causing some potential issues
when generating the error.

This commit moves away from the global variable and passes the
error context as a regular function argument.

Fixes: ab105a4fb894 ("tracing: Use tracing error_log with probe events")

Signed-off-by: Paul Cacheux <paulcacheux@gmail.com>
---
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
trace_probe_log on the stack. The mutex can cause performance
issues, and require high confidence in the correctness of the
current trace_probe_log_clear calls. This patch implements
the stack solution instead and passes a pointer to using
functions.

[1] https://lore.kernel.org/all/20221121081103.3070449-1-zhengyejian1@huawei.com/T/
---
 kernel/trace/trace_eprobe.c |  40 ++++---
 kernel/trace/trace_fprobe.c |  84 +++++++-------
 kernel/trace/trace_kprobe.c |  75 ++++++------
 kernel/trace/trace_probe.c  | 274 +++++++++++++++++++++++---------------------
 kernel/trace/trace_probe.h  |  21 ++--
 kernel/trace/trace_uprobe.c |  58 +++++-----
 6 files changed, 287 insertions(+), 265 deletions(-)

diff --git a/kernel/trace/trace_eprobe.c b/kernel/trace/trace_eprobe.c
index c08355c3ef32b4124ac944d7e3a03efb66492269..5dc5e722d3d2f53a963c3fe7536bc8adc177c867 100644
--- a/kernel/trace/trace_eprobe.c
+++ b/kernel/trace/trace_eprobe.c
@@ -795,7 +795,8 @@ find_and_get_event(const char *system, const char *event_name)
 	return NULL;
 }
 
-static int trace_eprobe_tp_update_arg(struct trace_eprobe *ep, const char *argv[], int i)
+static int trace_eprobe_tp_update_arg(struct trace_eprobe *ep, const char *argv[], int i,
+			struct trace_probe_log *tpl)
 {
 	struct traceprobe_parse_context ctx = {
 		.event = ep->event,
@@ -803,7 +804,7 @@ static int trace_eprobe_tp_update_arg(struct trace_eprobe *ep, const char *argv[
 	};
 	int ret;
 
-	ret = traceprobe_parse_probe_arg(&ep->tp, i, argv[i], &ctx);
+	ret = traceprobe_parse_probe_arg(&ep->tp, i, argv[i], &ctx, tpl);
 	/* Handle symbols "@" */
 	if (!ret)
 		ret = traceprobe_update_arg(&ep->tp.args[i]);
@@ -812,14 +813,17 @@ static int trace_eprobe_tp_update_arg(struct trace_eprobe *ep, const char *argv[
 	return ret;
 }
 
-static int trace_eprobe_parse_filter(struct trace_eprobe *ep, int argc, const char *argv[])
+static int trace_eprobe_parse_filter(struct trace_eprobe *ep,
+			struct trace_probe_log *tpl,
+			int argc,
+			const char *argv[])
 {
 	struct event_filter *dummy = NULL;
 	int i, ret, len = 0;
 	char *p;
 
 	if (argc == 0) {
-		trace_probe_log_err(0, NO_EP_FILTER);
+		trace_probe_log_err(tpl, 0, NO_EP_FILTER);
 		return -EINVAL;
 	}
 
@@ -879,22 +883,22 @@ static int __trace_eprobe_create(int argc, const char *argv[])
 	if (argc < 2 || argv[0][0] != 'e')
 		return -ECANCELED;
 
-	trace_probe_log_init("event_probe", argc, argv);
+	struct trace_probe_log tpl = trace_probe_log_create("event_probe", argc, argv);
 
 	event = strchr(&argv[0][1], ':');
 	if (event) {
 		event++;
 		ret = traceprobe_parse_event_name(&event, &group, gbuf,
-						  event - argv[0]);
+						  event - argv[0], &tpl);
 		if (ret)
 			goto parse_error;
 	}
 
-	trace_probe_log_set_index(1);
+	trace_probe_log_set_index(&tpl, 1);
 	sys_event = argv[1];
-	ret = traceprobe_parse_event_name(&sys_event, &sys_name, buf2, 0);
+	ret = traceprobe_parse_event_name(&sys_event, &sys_name, buf2, 0, &tpl);
 	if (ret || !sys_event || !sys_name) {
-		trace_probe_log_err(0, NO_EVENT_INFO);
+		trace_probe_log_err(&tpl, 0, NO_EVENT_INFO);
 		goto parse_error;
 	}
 
@@ -913,8 +917,8 @@ static int __trace_eprobe_create(int argc, const char *argv[])
 	}
 
 	if (argc - 2 > MAX_TRACE_ARGS) {
-		trace_probe_log_set_index(2);
-		trace_probe_log_err(0, TOO_MANY_ARGS);
+		trace_probe_log_set_index(&tpl, 2);
+		trace_probe_log_err(&tpl, 0, TOO_MANY_ARGS);
 		ret = -E2BIG;
 		goto error;
 	}
@@ -927,7 +931,7 @@ static int __trace_eprobe_create(int argc, const char *argv[])
 	if (IS_ERR(ep)) {
 		ret = PTR_ERR(ep);
 		if (ret == -ENODEV)
-			trace_probe_log_err(0, BAD_ATTACH_EVENT);
+			trace_probe_log_err(&tpl, 0, BAD_ATTACH_EVENT);
 		/* This must return -ENOMEM or missing event, else there is a bug */
 		WARN_ON_ONCE(ret != -ENOMEM && ret != -ENODEV);
 		ep = NULL;
@@ -935,8 +939,8 @@ static int __trace_eprobe_create(int argc, const char *argv[])
 	}
 
 	if (filter_idx) {
-		trace_probe_log_set_index(filter_idx);
-		ret = trace_eprobe_parse_filter(ep, filter_cnt, argv + filter_idx);
+		trace_probe_log_set_index(&tpl, filter_idx);
+		ret = trace_eprobe_parse_filter(ep, &tpl, filter_cnt, argv + filter_idx);
 		if (ret)
 			goto parse_error;
 	} else
@@ -945,8 +949,8 @@ static int __trace_eprobe_create(int argc, const char *argv[])
 	argc -= 2; argv += 2;
 	/* parse arguments */
 	for (i = 0; i < argc; i++) {
-		trace_probe_log_set_index(i + 2);
-		ret = trace_eprobe_tp_update_arg(ep, argv, i);
+		trace_probe_log_set_index(&tpl, i + 2);
+		ret = trace_eprobe_tp_update_arg(ep, argv, i, &tpl);
 		if (ret)
 			goto error;
 	}
@@ -958,8 +962,8 @@ static int __trace_eprobe_create(int argc, const char *argv[])
 		ret = trace_probe_register_event_call(&ep->tp);
 		if (ret) {
 			if (ret == -EEXIST) {
-				trace_probe_log_set_index(0);
-				trace_probe_log_err(0, EVENT_EXIST);
+				trace_probe_log_set_index(&tpl, 0);
+				trace_probe_log_err(&tpl, 0, EVENT_EXIST);
 			}
 			goto error;
 		}
diff --git a/kernel/trace/trace_fprobe.c b/kernel/trace/trace_fprobe.c
index b40fa59159ac521ef17aa3318db35de5ef491576..00905ac8f212511ca0d8d71c81c9a2a28087fd5d 100644
--- a/kernel/trace/trace_fprobe.c
+++ b/kernel/trace/trace_fprobe.c
@@ -837,26 +837,27 @@ static bool trace_fprobe_has_same_fprobe(struct trace_fprobe *orig,
 	return false;
 }
 
-static int append_trace_fprobe(struct trace_fprobe *tf, struct trace_fprobe *to)
+static int append_trace_fprobe(struct trace_fprobe *tf, struct trace_fprobe *to,
+			struct trace_probe_log *tpl)
 {
 	int ret;
 
 	if (trace_fprobe_is_return(tf) != trace_fprobe_is_return(to) ||
 	    trace_fprobe_is_tracepoint(tf) != trace_fprobe_is_tracepoint(to)) {
-		trace_probe_log_set_index(0);
-		trace_probe_log_err(0, DIFF_PROBE_TYPE);
+		trace_probe_log_set_index(tpl, 0);
+		trace_probe_log_err(tpl, 0, DIFF_PROBE_TYPE);
 		return -EEXIST;
 	}
 	ret = trace_probe_compare_arg_type(&tf->tp, &to->tp);
 	if (ret) {
 		/* Note that argument starts index = 2 */
-		trace_probe_log_set_index(ret + 1);
-		trace_probe_log_err(0, DIFF_ARG_TYPE);
+		trace_probe_log_set_index(tpl, ret + 1);
+		trace_probe_log_err(tpl, 0, DIFF_ARG_TYPE);
 		return -EEXIST;
 	}
 	if (trace_fprobe_has_same_fprobe(to, tf)) {
-		trace_probe_log_set_index(0);
-		trace_probe_log_err(0, SAME_PROBE);
+		trace_probe_log_set_index(tpl, 0);
+		trace_probe_log_err(tpl, 0, SAME_PROBE);
 		return -EEXIST;
 	}
 
@@ -875,7 +876,7 @@ static int append_trace_fprobe(struct trace_fprobe *tf, struct trace_fprobe *to)
 }
 
 /* Register a trace_probe and probe_event */
-static int register_trace_fprobe(struct trace_fprobe *tf)
+static int register_trace_fprobe(struct trace_fprobe *tf, struct trace_probe_log *tpl)
 {
 	struct trace_fprobe *old_tf;
 	int ret;
@@ -885,14 +886,14 @@ static int register_trace_fprobe(struct trace_fprobe *tf)
 	old_tf = find_trace_fprobe(trace_probe_name(&tf->tp),
 				   trace_probe_group_name(&tf->tp));
 	if (old_tf)
-		return append_trace_fprobe(tf, old_tf);
+		return append_trace_fprobe(tf, old_tf, tpl);
 
 	/* Register new event */
 	ret = register_fprobe_event(tf);
 	if (ret) {
 		if (ret == -EEXIST) {
-			trace_probe_log_set_index(0);
-			trace_probe_log_err(0, EVENT_EXIST);
+			trace_probe_log_set_index(tpl, 0);
+			trace_probe_log_err(tpl, 0, EVENT_EXIST);
 		} else
 			pr_warn("Failed to register probe event(%d)\n", ret);
 		return ret;
@@ -1030,7 +1031,7 @@ static struct notifier_block tracepoint_module_nb = {
 };
 #endif /* CONFIG_MODULES */
 
-static int parse_symbol_and_return(int argc, const char *argv[],
+static int parse_symbol_and_return(struct trace_probe_log *tpl, int argc, const char *argv[],
 				   char **symbol, bool *is_return,
 				   bool is_tracepoint)
 {
@@ -1043,7 +1044,7 @@ static int parse_symbol_and_return(int argc, const char *argv[],
 		if (!is_tracepoint && !strcmp(tmp, "%return")) {
 			*is_return = true;
 		} else {
-			trace_probe_log_err(len, BAD_ADDR_SUFFIX);
+			trace_probe_log_err(tpl, len, BAD_ADDR_SUFFIX);
 			return -EINVAL;
 		}
 		*symbol = kmemdup_nul(argv[1], len, GFP_KERNEL);
@@ -1061,7 +1062,7 @@ static int parse_symbol_and_return(int argc, const char *argv[],
 			tmp++;
 		if (*tmp) {
 			/* find a wrong character. */
-			trace_probe_log_err(tmp - *symbol, BAD_TP_NAME);
+			trace_probe_log_err(tpl, tmp - *symbol, BAD_TP_NAME);
 			kfree(*symbol);
 			*symbol = NULL;
 			return -EINVAL;
@@ -1073,8 +1074,8 @@ static int parse_symbol_and_return(int argc, const char *argv[],
 		tmp = strstr(argv[i], "$retval");
 		if (tmp && !isalnum(tmp[7]) && tmp[7] != '_') {
 			if (is_tracepoint) {
-				trace_probe_log_set_index(i);
-				trace_probe_log_err(tmp - argv[i], RETVAL_ON_PROBE);
+				trace_probe_log_set_index(tpl, i);
+				trace_probe_log_err(tpl, tmp - argv[i], RETVAL_ON_PROBE);
 				kfree(*symbol);
 				*symbol = NULL;
 				return -EINVAL;
@@ -1089,7 +1090,8 @@ static int parse_symbol_and_return(int argc, const char *argv[],
 DEFINE_FREE(module_put, struct module *, if (_T) module_put(_T))
 
 static int trace_fprobe_create_internal(int argc, const char *argv[],
-					struct traceprobe_parse_context *ctx)
+					struct traceprobe_parse_context *ctx,
+					struct trace_probe_log *tpl)
 {
 	/*
 	 * Argument syntax:
@@ -1140,24 +1142,24 @@ static int trace_fprobe_create_internal(int argc, const char *argv[],
 
 	if (argv[0][1] != '\0') {
 		if (argv[0][1] != ':') {
-			trace_probe_log_set_index(0);
-			trace_probe_log_err(1, BAD_MAXACT);
+			trace_probe_log_set_index(tpl, 0);
+			trace_probe_log_err(tpl, 1, BAD_MAXACT);
 			return -EINVAL;
 		}
 		event = &argv[0][2];
 	}
 
-	trace_probe_log_set_index(1);
+	trace_probe_log_set_index(tpl, 1);
 
 	/* a symbol(or tracepoint) must be specified */
-	ret = parse_symbol_and_return(argc, argv, &symbol, &is_return, is_tracepoint);
+	ret = parse_symbol_and_return(tpl, argc, argv, &symbol, &is_return, is_tracepoint);
 	if (ret < 0)
 		return -EINVAL;
 
-	trace_probe_log_set_index(0);
+	trace_probe_log_set_index(tpl, 0);
 	if (event) {
 		ret = traceprobe_parse_event_name(&event, &group, gbuf,
-						  event - argv[0]);
+						  event - argv[0], tpl);
 		if (ret)
 			return -EINVAL;
 	}
@@ -1191,8 +1193,8 @@ static int trace_fprobe_create_internal(int argc, const char *argv[],
 				tpoint = TRACEPOINT_STUB;
 				ctx->funcname = symbol;
 		} else {
-			trace_probe_log_set_index(1);
-			trace_probe_log_err(0, NO_TRACEPOINT);
+			trace_probe_log_set_index(tpl, 1);
+			trace_probe_log_err(tpl, 0, NO_TRACEPOINT);
 			return -EINVAL;
 		}
 	} else
@@ -1200,7 +1202,7 @@ static int trace_fprobe_create_internal(int argc, const char *argv[],
 
 	argc -= 2; argv += 2;
 	new_argv = traceprobe_expand_meta_args(argc, argv, &new_argc,
-					       abuf, MAX_BTF_ARGS_LEN, ctx);
+					       abuf, MAX_BTF_ARGS_LEN, ctx, tpl);
 	if (IS_ERR(new_argv))
 		return PTR_ERR(new_argv);
 	if (new_argv) {
@@ -1208,8 +1210,8 @@ static int trace_fprobe_create_internal(int argc, const char *argv[],
 		argv = new_argv;
 	}
 	if (argc > MAX_TRACE_ARGS) {
-		trace_probe_log_set_index(2);
-		trace_probe_log_err(0, TOO_MANY_ARGS);
+		trace_probe_log_set_index(tpl, 2);
+		trace_probe_log_err(tpl, 0, TOO_MANY_ARGS);
 		return -E2BIG;
 	}
 
@@ -1229,9 +1231,9 @@ static int trace_fprobe_create_internal(int argc, const char *argv[],
 
 	/* parse arguments */
 	for (i = 0; i < argc; i++) {
-		trace_probe_log_set_index(i + 2);
+		trace_probe_log_set_index(tpl, i + 2);
 		ctx->offset = 0;
-		ret = traceprobe_parse_probe_arg(&tf->tp, i, argv[i], ctx);
+		ret = traceprobe_parse_probe_arg(&tf->tp, i, argv[i], ctx, tpl);
 		if (ret)
 			return ret;	/* This can be -ENOMEM */
 	}
@@ -1240,8 +1242,8 @@ static int trace_fprobe_create_internal(int argc, const char *argv[],
 		tf->fp.entry_handler = trace_fprobe_entry_handler;
 		tf->fp.entry_data_size = traceprobe_get_entry_data_size(&tf->tp);
 		if (ALIGN(tf->fp.entry_data_size, sizeof(long)) > MAX_FPROBE_DATA_SIZE) {
-			trace_probe_log_set_index(2);
-			trace_probe_log_err(0, TOO_MANY_EARGS);
+			trace_probe_log_set_index(tpl, 2);
+			trace_probe_log_err(tpl, 0, TOO_MANY_EARGS);
 			return -E2BIG;
 		}
 	}
@@ -1251,15 +1253,15 @@ static int trace_fprobe_create_internal(int argc, const char *argv[],
 	if (ret < 0)
 		return ret;
 
-	ret = register_trace_fprobe(tf);
+	ret = register_trace_fprobe(tf, tpl);
 	if (ret) {
-		trace_probe_log_set_index(1);
+		trace_probe_log_set_index(tpl, 1);
 		if (ret == -EILSEQ)
-			trace_probe_log_err(0, BAD_INSN_BNDRY);
+			trace_probe_log_err(tpl, 0, BAD_INSN_BNDRY);
 		else if (ret == -ENOENT)
-			trace_probe_log_err(0, BAD_PROBE_ADDR);
+			trace_probe_log_err(tpl, 0, BAD_PROBE_ADDR);
 		else if (ret != -ENOMEM && ret != -EEXIST)
-			trace_probe_log_err(0, FAIL_REG_PROBE);
+			trace_probe_log_err(tpl, 0, FAIL_REG_PROBE);
 		return -EINVAL;
 	}
 
@@ -1276,10 +1278,12 @@ static int trace_fprobe_create_cb(int argc, const char *argv[])
 	};
 	int ret;
 
-	trace_probe_log_init("trace_fprobe", argc, argv);
-	ret = trace_fprobe_create_internal(argc, argv, &ctx);
+	struct trace_probe_log tpl = trace_probe_log_create(
+		"trace_fprobe",
+		argc,
+		argv);
+	ret = trace_fprobe_create_internal(argc, argv, &ctx, &tpl);
 	traceprobe_finish_parse(&ctx);
-	trace_probe_log_clear();
 	return ret;
 }
 
diff --git a/kernel/trace/trace_kprobe.c b/kernel/trace/trace_kprobe.c
index 2703b96d8990649ebcfeefde0ae1a8b1960659a6..c5ec7ff03d62f480fa7981937adb505f0358a61f 100644
--- a/kernel/trace/trace_kprobe.c
+++ b/kernel/trace/trace_kprobe.c
@@ -591,20 +591,21 @@ static bool trace_kprobe_has_same_kprobe(struct trace_kprobe *orig,
 	return false;
 }
 
-static int append_trace_kprobe(struct trace_kprobe *tk, struct trace_kprobe *to)
+static int append_trace_kprobe(struct trace_kprobe *tk, struct trace_kprobe *to,
+				struct trace_probe_log *tpl)
 {
 	int ret;
 
 	ret = trace_probe_compare_arg_type(&tk->tp, &to->tp);
 	if (ret) {
 		/* Note that argument starts index = 2 */
-		trace_probe_log_set_index(ret + 1);
-		trace_probe_log_err(0, DIFF_ARG_TYPE);
+		trace_probe_log_set_index(tpl, ret + 1);
+		trace_probe_log_err(tpl, 0, DIFF_ARG_TYPE);
 		return -EEXIST;
 	}
 	if (trace_kprobe_has_same_kprobe(to, tk)) {
-		trace_probe_log_set_index(0);
-		trace_probe_log_err(0, SAME_PROBE);
+		trace_probe_log_set_index(tpl, 0);
+		trace_probe_log_err(tpl, 0, SAME_PROBE);
 		return -EEXIST;
 	}
 
@@ -629,7 +630,7 @@ static int append_trace_kprobe(struct trace_kprobe *tk, struct trace_kprobe *to)
 }
 
 /* Register a trace_probe and probe_event */
-static int register_trace_kprobe(struct trace_kprobe *tk)
+static int register_trace_kprobe(struct trace_kprobe *tk, struct trace_probe_log *tpl)
 {
 	struct trace_kprobe *old_tk;
 	int ret;
@@ -640,19 +641,19 @@ static int register_trace_kprobe(struct trace_kprobe *tk)
 				   trace_probe_group_name(&tk->tp));
 	if (old_tk) {
 		if (trace_kprobe_is_return(tk) != trace_kprobe_is_return(old_tk)) {
-			trace_probe_log_set_index(0);
-			trace_probe_log_err(0, DIFF_PROBE_TYPE);
+			trace_probe_log_set_index(tpl, 0);
+			trace_probe_log_err(tpl, 0, DIFF_PROBE_TYPE);
 			return -EEXIST;
 		}
-		return append_trace_kprobe(tk, old_tk);
+		return append_trace_kprobe(tk, old_tk, tpl);
 	}
 
 	/* Register new event */
 	ret = register_kprobe_event(tk);
 	if (ret) {
 		if (ret == -EEXIST) {
-			trace_probe_log_set_index(0);
-			trace_probe_log_err(0, EVENT_EXIST);
+			trace_probe_log_set_index(tpl, 0);
+			trace_probe_log_err(tpl, 0, EVENT_EXIST);
 		} else
 			pr_warn("Failed to register probe event(%d)\n", ret);
 		return ret;
@@ -834,7 +835,8 @@ static int trace_kprobe_entry_handler(struct kretprobe_instance *ri,
 				      struct pt_regs *regs);
 
 static int trace_kprobe_create_internal(int argc, const char *argv[],
-					struct traceprobe_parse_context *ctx)
+					struct traceprobe_parse_context *ctx,
+				    struct trace_probe_log *tpl)
 {
 	/*
 	 * Argument syntax:
@@ -894,7 +896,7 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 
 	if (isdigit(argv[0][1])) {
 		if (!is_return) {
-			trace_probe_log_err(1, BAD_MAXACT_TYPE);
+			trace_probe_log_err(tpl, 1, BAD_MAXACT_TYPE);
 			return -EINVAL;
 		}
 		if (event)
@@ -902,21 +904,21 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 		else
 			len = strlen(&argv[0][1]);
 		if (len > MAX_EVENT_NAME_LEN - 1) {
-			trace_probe_log_err(1, BAD_MAXACT);
+			trace_probe_log_err(tpl, 1, BAD_MAXACT);
 			return -EINVAL;
 		}
 		memcpy(buf, &argv[0][1], len);
 		buf[len] = '\0';
 		ret = kstrtouint(buf, 0, &maxactive);
 		if (ret || !maxactive) {
-			trace_probe_log_err(1, BAD_MAXACT);
+			trace_probe_log_err(tpl, 1, BAD_MAXACT);
 			return -EINVAL;
 		}
 		/* kretprobes instances are iterated over via a list. The
 		 * maximum should stay reasonable.
 		 */
 		if (maxactive > KRETPROBE_MAXACTIVE_MAX) {
-			trace_probe_log_err(1, MAXACT_TOO_BIG);
+			trace_probe_log_err(tpl, 1, MAXACT_TOO_BIG);
 			return -EINVAL;
 		}
 	}
@@ -924,7 +926,7 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 	/* try to parse an address. if that fails, try to read the
 	 * input as a symbol. */
 	if (kstrtoul(argv[1], 0, (unsigned long *)&addr)) {
-		trace_probe_log_set_index(1);
+		trace_probe_log_set_index(tpl, 1);
 		/* Check whether uprobe event specified */
 		if (strchr(argv[1], '/') && strchr(argv[1], ':'))
 			return -ECANCELED;
@@ -940,7 +942,7 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 				*tmp = '\0';
 				is_return = true;
 			} else {
-				trace_probe_log_err(tmp - symbol, BAD_ADDR_SUFFIX);
+				trace_probe_log_err(tpl, tmp - symbol, BAD_ADDR_SUFFIX);
 				return -EINVAL;
 			}
 		}
@@ -948,15 +950,15 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 		/* TODO: support .init module functions */
 		ret = traceprobe_split_symbol_offset(symbol, &offset);
 		if (ret || offset < 0 || offset > UINT_MAX) {
-			trace_probe_log_err(0, BAD_PROBE_ADDR);
+			trace_probe_log_err(tpl, 0, BAD_PROBE_ADDR);
 			return -EINVAL;
 		}
 		ret = validate_probe_symbol(symbol);
 		if (ret) {
 			if (ret == -EADDRNOTAVAIL)
-				trace_probe_log_err(0, NON_UNIQ_SYMBOL);
+				trace_probe_log_err(tpl, 0, NON_UNIQ_SYMBOL);
 			else
-				trace_probe_log_err(0, BAD_PROBE_ADDR);
+				trace_probe_log_err(tpl, 0, BAD_PROBE_ADDR);
 			return -EINVAL;
 		}
 		if (is_return)
@@ -966,15 +968,15 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 			ctx->flags |= TPARG_FL_FENTRY;
 		/* Defer the ENOENT case until register kprobe */
 		if (ret == -EINVAL && is_return) {
-			trace_probe_log_err(0, BAD_RETPROBE);
+			trace_probe_log_err(tpl, 0, BAD_RETPROBE);
 			return -EINVAL;
 		}
 	}
 
-	trace_probe_log_set_index(0);
+	trace_probe_log_set_index(tpl, 0);
 	if (event) {
 		ret = traceprobe_parse_event_name(&event, &group, gbuf,
-						  event - argv[0]);
+						  event - argv[0], tpl);
 		if (ret)
 			return ret;
 	}
@@ -994,7 +996,7 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 	argc -= 2; argv += 2;
 	ctx->funcname = symbol;
 	new_argv = traceprobe_expand_meta_args(argc, argv, &new_argc,
-					       abuf, MAX_BTF_ARGS_LEN, ctx);
+					       abuf, MAX_BTF_ARGS_LEN, ctx, tpl);
 	if (IS_ERR(new_argv)) {
 		ret = PTR_ERR(new_argv);
 		new_argv = NULL;
@@ -1005,8 +1007,8 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 		argv = new_argv;
 	}
 	if (argc > MAX_TRACE_ARGS) {
-		trace_probe_log_set_index(2);
-		trace_probe_log_err(0, TOO_MANY_ARGS);
+		trace_probe_log_set_index(tpl, 2);
+		trace_probe_log_err(tpl, 0, TOO_MANY_ARGS);
 		return -E2BIG;
 	}
 
@@ -1026,9 +1028,9 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 
 	/* parse arguments */
 	for (i = 0; i < argc; i++) {
-		trace_probe_log_set_index(i + 2);
+		trace_probe_log_set_index(tpl, i + 2);
 		ctx->offset = 0;
-		ret = traceprobe_parse_probe_arg(&tk->tp, i, argv[i], ctx);
+		ret = traceprobe_parse_probe_arg(&tk->tp, i, argv[i], ctx, tpl);
 		if (ret)
 			return ret;	/* This can be -ENOMEM */
 	}
@@ -1043,15 +1045,15 @@ static int trace_kprobe_create_internal(int argc, const char *argv[],
 	if (ret < 0)
 		return ret;
 
-	ret = register_trace_kprobe(tk);
+	ret = register_trace_kprobe(tk, tpl);
 	if (ret) {
-		trace_probe_log_set_index(1);
+		trace_probe_log_set_index(tpl, 1);
 		if (ret == -EILSEQ)
-			trace_probe_log_err(0, BAD_INSN_BNDRY);
+			trace_probe_log_err(tpl, 0, BAD_INSN_BNDRY);
 		else if (ret == -ENOENT)
-			trace_probe_log_err(0, BAD_PROBE_ADDR);
+			trace_probe_log_err(tpl, 0, BAD_PROBE_ADDR);
 		else if (ret != -ENOMEM && ret != -EEXIST)
-			trace_probe_log_err(0, FAIL_REG_PROBE);
+			trace_probe_log_err(tpl, 0, FAIL_REG_PROBE);
 		return ret;
 	}
 	/*
@@ -1068,12 +1070,11 @@ static int trace_kprobe_create_cb(int argc, const char *argv[])
 	struct traceprobe_parse_context ctx = { .flags = TPARG_FL_KERNEL };
 	int ret;
 
-	trace_probe_log_init("trace_kprobe", argc, argv);
+	struct trace_probe_log tpl = trace_probe_log_create("trace_kprobe", argc, argv);
 
-	ret = trace_kprobe_create_internal(argc, argv, &ctx);
+	ret = trace_kprobe_create_internal(argc, argv, &ctx, &tpl);
 
 	traceprobe_finish_parse(&ctx);
-	trace_probe_log_clear();
 	return ret;
 }
 
diff --git a/kernel/trace/trace_probe.c b/kernel/trace/trace_probe.c
index 2eeecb6c95eea55502b83af6775b7b6f0cc5ab94..e16de6a8688d7e6ded5a340e39aaf220e9b2e483 100644
--- a/kernel/trace/trace_probe.c
+++ b/kernel/trace/trace_probe.c
@@ -153,45 +153,41 @@ static const struct fetch_type *find_fetch_type(const char *type, unsigned long
 	return NULL;
 }
 
-static struct trace_probe_log trace_probe_log;
-
-void trace_probe_log_init(const char *subsystem, int argc, const char **argv)
-{
-	trace_probe_log.subsystem = subsystem;
-	trace_probe_log.argc = argc;
-	trace_probe_log.argv = argv;
-	trace_probe_log.index = 0;
-}
-
-void trace_probe_log_clear(void)
+struct trace_probe_log trace_probe_log_create(const char *subsystem, int argc, const char **argv)
 {
-	memset(&trace_probe_log, 0, sizeof(trace_probe_log));
+	struct trace_probe_log tpl = {
+		.subsystem = subsystem,
+		.argc = argc,
+		.argv = argv,
+		.index = 0,
+	};
+	return tpl;
 }
 
-void trace_probe_log_set_index(int index)
+void trace_probe_log_set_index(struct trace_probe_log *tpl, int index)
 {
-	trace_probe_log.index = index;
+	tpl->index = index;
 }
 
-void __trace_probe_log_err(int offset, int err_type)
+void __trace_probe_log_err(struct trace_probe_log *tpl, int offset, int err_type)
 {
 	char *command, *p;
 	int i, len = 0, pos = 0;
 
-	if (!trace_probe_log.argv)
+	if (!tpl->argv)
 		return;
 
 	/* Recalculate the length and allocate buffer */
-	for (i = 0; i < trace_probe_log.argc; i++) {
-		if (i == trace_probe_log.index)
+	for (i = 0; i < tpl->argc; i++) {
+		if (i == tpl->index)
 			pos = len;
-		len += strlen(trace_probe_log.argv[i]) + 1;
+		len += strlen(tpl->argv[i]) + 1;
 	}
 	command = kzalloc(len, GFP_KERNEL);
 	if (!command)
 		return;
 
-	if (trace_probe_log.index >= trace_probe_log.argc) {
+	if (tpl->index >= tpl->argc) {
 		/**
 		 * Set the error position is next to the last arg + space.
 		 * Note that len includes the terminal null and the cursor
@@ -203,15 +199,15 @@ void __trace_probe_log_err(int offset, int err_type)
 
 	/* And make a command string from argv array */
 	p = command;
-	for (i = 0; i < trace_probe_log.argc; i++) {
-		len = strlen(trace_probe_log.argv[i]);
-		strcpy(p, trace_probe_log.argv[i]);
+	for (i = 0; i < tpl->argc; i++) {
+		len = strlen(tpl->argv[i]);
+		strcpy(p, tpl->argv[i]);
 		p[len] = ' ';
 		p += len + 1;
 	}
 	*(p - 1) = '\0';
 
-	tracing_log_err(NULL, trace_probe_log.subsystem, command,
+	tracing_log_err(NULL, tpl->subsystem, command,
 			trace_probe_err_text, err_type, pos + offset);
 
 	kfree(command);
@@ -240,7 +236,7 @@ int traceprobe_split_symbol_offset(char *symbol, long *offset)
 
 /* @buf must has MAX_EVENT_NAME_LEN size */
 int traceprobe_parse_event_name(const char **pevent, const char **pgroup,
-				char *buf, int offset)
+				char *buf, int offset, struct trace_probe_log *tpl)
 {
 	const char *slash, *event = *pevent;
 	int len;
@@ -251,16 +247,16 @@ int traceprobe_parse_event_name(const char **pevent, const char **pgroup,
 
 	if (slash) {
 		if (slash == event) {
-			trace_probe_log_err(offset, NO_GROUP_NAME);
+			trace_probe_log_err(tpl, offset, NO_GROUP_NAME);
 			return -EINVAL;
 		}
 		if (slash - event + 1 > MAX_EVENT_NAME_LEN) {
-			trace_probe_log_err(offset, GROUP_TOO_LONG);
+			trace_probe_log_err(tpl, offset, GROUP_TOO_LONG);
 			return -EINVAL;
 		}
 		strscpy(buf, event, slash - event + 1);
 		if (!is_good_system_name(buf)) {
-			trace_probe_log_err(offset, BAD_GROUP_NAME);
+			trace_probe_log_err(tpl, offset, BAD_GROUP_NAME);
 			return -EINVAL;
 		}
 		*pgroup = buf;
@@ -274,14 +270,14 @@ int traceprobe_parse_event_name(const char **pevent, const char **pgroup,
 			*pevent = NULL;
 			return 0;
 		}
-		trace_probe_log_err(offset, NO_EVENT_NAME);
+		trace_probe_log_err(tpl, offset, NO_EVENT_NAME);
 		return -EINVAL;
 	} else if (len >= MAX_EVENT_NAME_LEN) {
-		trace_probe_log_err(offset, EVENT_TOO_LONG);
+		trace_probe_log_err(tpl, offset, EVENT_TOO_LONG);
 		return -EINVAL;
 	}
 	if (!is_good_name(event)) {
-		trace_probe_log_err(offset, BAD_EVENT_NAME);
+		trace_probe_log_err(tpl, offset, BAD_EVENT_NAME);
 		return -EINVAL;
 	}
 	return 0;
@@ -350,7 +346,8 @@ static bool btf_type_is_char_array(struct btf *btf, const struct btf_type *type)
 
 static int check_prepare_btf_string_fetch(char *typename,
 				struct fetch_insn **pcode,
-				struct traceprobe_parse_context *ctx)
+				struct traceprobe_parse_context *ctx,
+				struct trace_probe_log *tpl)
 {
 	struct btf *btf = ctx->btf;
 
@@ -366,7 +363,7 @@ static int check_prepare_btf_string_fetch(char *typename,
 		struct fetch_insn *code = *pcode + 1;
 
 		if (code->op == FETCH_OP_END) {
-			trace_probe_log_err(ctx->offset, TOO_MANY_OPS);
+			trace_probe_log_err(tpl, ctx->offset, TOO_MANY_OPS);
 			return -E2BIG;
 		}
 		if (typename[0] == 'u')
@@ -378,7 +375,7 @@ static int check_prepare_btf_string_fetch(char *typename,
 		return 0;
 	}
 	/* Other types are not available for string */
-	trace_probe_log_err(ctx->offset, BAD_TYPE4STR);
+	trace_probe_log_err(tpl, ctx->offset, BAD_TYPE4STR);
 	return -EINVAL;
 }
 
@@ -491,7 +488,8 @@ static void clear_btf_context(struct traceprobe_parse_context *ctx)
 
 /* Return 1 if the field separater is arrow operator ('->') */
 static int split_next_field(char *varname, char **next_field,
-			    struct traceprobe_parse_context *ctx)
+			    struct traceprobe_parse_context *ctx,
+				struct trace_probe_log *tpl)
 {
 	char *field;
 	int ret = 0;
@@ -506,7 +504,7 @@ static int split_next_field(char *varname, char **next_field,
 			field[0] = '\0';
 			field += 1;
 		} else {
-			trace_probe_log_err(ctx->offset + field - varname, BAD_HYPHEN);
+			trace_probe_log_err(tpl, ctx->offset + field - varname, BAD_HYPHEN);
 			return -EINVAL;
 		}
 		*next_field = field;
@@ -521,7 +519,8 @@ static int split_next_field(char *varname, char **next_field,
  */
 static int parse_btf_field(char *fieldname, const struct btf_type *type,
 			   struct fetch_insn **pcode, struct fetch_insn *end,
-			   struct traceprobe_parse_context *ctx)
+			   struct traceprobe_parse_context *ctx,
+			   struct trace_probe_log *tpl)
 {
 	struct fetch_insn *code = *pcode;
 	const struct btf_member *field;
@@ -533,13 +532,13 @@ static int parse_btf_field(char *fieldname, const struct btf_type *type,
 	do {
 		/* Outer loop for solving arrow operator ('->') */
 		if (BTF_INFO_KIND(type->info) != BTF_KIND_PTR) {
-			trace_probe_log_err(ctx->offset, NO_PTR_STRCT);
+			trace_probe_log_err(tpl, ctx->offset, NO_PTR_STRCT);
 			return -EINVAL;
 		}
 		/* Convert a struct pointer type to a struct type */
 		type = btf_type_skip_modifiers(ctx->btf, type->type, &tid);
 		if (!type) {
-			trace_probe_log_err(ctx->offset, BAD_BTF_TID);
+			trace_probe_log_err(tpl, ctx->offset, BAD_BTF_TID);
 			return -EINVAL;
 		}
 
@@ -547,7 +546,7 @@ static int parse_btf_field(char *fieldname, const struct btf_type *type,
 		do {
 			/* Inner loop for solving dot operator ('.') */
 			next = NULL;
-			is_ptr = split_next_field(fieldname, &next, ctx);
+			is_ptr = split_next_field(fieldname, &next, ctx, tpl);
 			if (is_ptr < 0)
 				return is_ptr;
 
@@ -555,11 +554,11 @@ static int parse_btf_field(char *fieldname, const struct btf_type *type,
 			field = btf_find_struct_member(ctx->btf, type, fieldname,
 						       &anon_offs);
 			if (IS_ERR(field)) {
-				trace_probe_log_err(ctx->offset, BAD_BTF_TID);
+				trace_probe_log_err(tpl, ctx->offset, BAD_BTF_TID);
 				return PTR_ERR(field);
 			}
 			if (!field) {
-				trace_probe_log_err(ctx->offset, NO_BTF_FIELD);
+				trace_probe_log_err(tpl, ctx->offset, NO_BTF_FIELD);
 				return -ENOENT;
 			}
 			/* Add anonymous structure/union offset */
@@ -576,7 +575,7 @@ static int parse_btf_field(char *fieldname, const struct btf_type *type,
 
 			type = btf_type_skip_modifiers(ctx->btf, field->type, &tid);
 			if (!type) {
-				trace_probe_log_err(ctx->offset, BAD_BTF_TID);
+				trace_probe_log_err(tpl, ctx->offset, BAD_BTF_TID);
 				return -EINVAL;
 			}
 
@@ -585,7 +584,7 @@ static int parse_btf_field(char *fieldname, const struct btf_type *type,
 		} while (!is_ptr && fieldname);
 
 		if (++code == end) {
-			trace_probe_log_err(ctx->offset, TOO_MANY_OPS);
+			trace_probe_log_err(tpl, ctx->offset, TOO_MANY_OPS);
 			return -EINVAL;
 		}
 		code->op = FETCH_OP_DEREF;	/* TODO: user deref support */
@@ -603,7 +602,8 @@ static int __store_entry_arg(struct trace_probe *tp, int argnum);
 
 static int parse_btf_arg(char *varname,
 			 struct fetch_insn **pcode, struct fetch_insn *end,
-			 struct traceprobe_parse_context *ctx)
+			 struct traceprobe_parse_context *ctx,
+			 struct trace_probe_log *tpl)
 {
 	struct fetch_insn *code = *pcode;
 	const struct btf_param *params;
@@ -615,12 +615,12 @@ static int parse_btf_arg(char *varname,
 	if (WARN_ON_ONCE(!ctx->funcname))
 		return -EINVAL;
 
-	is_ptr = split_next_field(varname, &field, ctx);
+	is_ptr = split_next_field(varname, &field, ctx, tpl);
 	if (is_ptr < 0)
 		return is_ptr;
 	if (!is_ptr && field) {
 		/* dot-connected field on an argument is not supported. */
-		trace_probe_log_err(ctx->offset + field - varname,
+		trace_probe_log_err(tpl, ctx->offset + field - varname,
 				    NOSUP_DAT_ARG);
 		return -EOPNOTSUPP;
 	}
@@ -630,14 +630,14 @@ static int parse_btf_arg(char *varname,
 		/* Check whether the function return type is not void */
 		if (query_btf_context(ctx) == 0) {
 			if (ctx->proto->type == 0) {
-				trace_probe_log_err(ctx->offset, NO_RETVAL);
+				trace_probe_log_err(tpl, ctx->offset, NO_RETVAL);
 				return -ENOENT;
 			}
 			tid = ctx->proto->type;
 			goto found;
 		}
 		if (field) {
-			trace_probe_log_err(ctx->offset + field - varname,
+			trace_probe_log_err(tpl, ctx->offset + field - varname,
 					    NO_BTF_ENTRY);
 			return -ENOENT;
 		}
@@ -647,7 +647,7 @@ static int parse_btf_arg(char *varname,
 	if (!ctx->btf) {
 		ret = query_btf_context(ctx);
 		if (ret < 0 || ctx->nr_params == 0) {
-			trace_probe_log_err(ctx->offset, NO_BTF_ENTRY);
+			trace_probe_log_err(tpl, ctx->offset, NO_BTF_ENTRY);
 			return PTR_ERR(params);
 		}
 	}
@@ -676,13 +676,13 @@ static int parse_btf_arg(char *varname,
 			goto found;
 		}
 	}
-	trace_probe_log_err(ctx->offset, NO_BTFARG);
+	trace_probe_log_err(tpl, ctx->offset, NO_BTFARG);
 	return -ENOENT;
 
 found:
 	type = btf_type_skip_modifiers(ctx->btf, tid, &tid);
 	if (!type) {
-		trace_probe_log_err(ctx->offset, BAD_BTF_TID);
+		trace_probe_log_err(tpl, ctx->offset, BAD_BTF_TID);
 		return -EINVAL;
 	}
 	/* Initialize the last type information */
@@ -691,7 +691,7 @@ static int parse_btf_arg(char *varname,
 	ctx->last_bitsize = 0;
 	if (field) {
 		ctx->offset += field - varname;
-		return parse_btf_field(field, type, pcode, end, ctx);
+		return parse_btf_field(field, type, pcode, end, ctx, tpl);
 	}
 	return 0;
 }
@@ -709,7 +709,8 @@ static const struct fetch_type *find_fetch_type_from_btf_type(
 }
 
 static int parse_btf_bitfield(struct fetch_insn **pcode,
-			      struct traceprobe_parse_context *ctx)
+			      struct traceprobe_parse_context *ctx,
+				  struct trace_probe_log *tpl)
 {
 	struct fetch_insn *code = *pcode;
 
@@ -718,7 +719,7 @@ static int parse_btf_bitfield(struct fetch_insn **pcode,
 
 	code++;
 	if (code->op != FETCH_OP_NOP) {
-		trace_probe_log_err(ctx->offset, TOO_MANY_OPS);
+		trace_probe_log_err(tpl, ctx->offset, TOO_MANY_OPS);
 		return -EINVAL;
 	}
 	*pcode = code;
@@ -743,16 +744,18 @@ static int query_btf_context(struct traceprobe_parse_context *ctx)
 
 static int parse_btf_arg(char *varname,
 			 struct fetch_insn **pcode, struct fetch_insn *end,
-			 struct traceprobe_parse_context *ctx)
+			 struct traceprobe_parse_context *ctx,
+			 struct trace_probe_log *tpl)
 {
-	trace_probe_log_err(ctx->offset, NOSUP_BTFARG);
+	trace_probe_log_err(tpl, ctx->offset, NOSUP_BTFARG);
 	return -EOPNOTSUPP;
 }
 
 static int parse_btf_bitfield(struct fetch_insn **pcode,
-			      struct traceprobe_parse_context *ctx)
+			      struct traceprobe_parse_context *ctx,
+				  struct trace_probe_log *tpl)
 {
-	trace_probe_log_err(ctx->offset, NOSUP_BTFARG);
+	trace_probe_log_err(tpl, ctx->offset, NOSUP_BTFARG);
 	return -EOPNOTSUPP;
 }
 
@@ -761,7 +764,8 @@ static int parse_btf_bitfield(struct fetch_insn **pcode,
 
 static int check_prepare_btf_string_fetch(char *typename,
 				struct fetch_insn **pcode,
-				struct traceprobe_parse_context *ctx)
+				struct traceprobe_parse_context *ctx,
+				struct trace_probe_log *tpl)
 {
 	return 0;
 }
@@ -906,7 +910,8 @@ NOKPROBE_SYMBOL(store_trace_entry_data)
 static int parse_probe_vars(char *orig_arg, const struct fetch_type *t,
 			    struct fetch_insn **pcode,
 			    struct fetch_insn *end,
-			    struct traceprobe_parse_context *ctx)
+			    struct traceprobe_parse_context *ctx,
+			    struct trace_probe_log *tpl)
 {
 	struct fetch_insn *code = *pcode;
 	int err = TP_ERR_BAD_VAR;
@@ -940,7 +945,7 @@ static int parse_probe_vars(char *orig_arg, const struct fetch_type *t,
 			code->op = FETCH_OP_RETVAL;
 			return 0;
 		}
-		return parse_btf_arg(orig_arg, pcode, end, ctx);
+		return parse_btf_arg(orig_arg, pcode, end, ctx, tpl);
 	}
 
 	len = str_has_prefix(arg, "stack");
@@ -1012,7 +1017,7 @@ static int parse_probe_vars(char *orig_arg, const struct fetch_type *t,
 #endif
 
 inval:
-	__trace_probe_log_err(ctx->offset, err);
+	__trace_probe_log_err(tpl, ctx->offset, err);
 	return -EINVAL;
 }
 
@@ -1027,12 +1032,12 @@ static int str_to_immediate(char *str, unsigned long *imm)
 	return -EINVAL;
 }
 
-static int __parse_imm_string(char *str, char **pbuf, int offs)
+static int __parse_imm_string(char *str, char **pbuf, int offs, struct trace_probe_log *tpl)
 {
 	size_t len = strlen(str);
 
 	if (str[len - 1] != '"') {
-		trace_probe_log_err(offs + len, IMMSTR_NO_CLOSE);
+		trace_probe_log_err(tpl, offs + len, IMMSTR_NO_CLOSE);
 		return -EINVAL;
 	}
 	*pbuf = kstrndup(str, len - 1, GFP_KERNEL);
@@ -1045,7 +1050,8 @@ static int __parse_imm_string(char *str, char **pbuf, int offs)
 static int
 parse_probe_arg(char *arg, const struct fetch_type *type,
 		struct fetch_insn **pcode, struct fetch_insn *end,
-		struct traceprobe_parse_context *ctx)
+		struct traceprobe_parse_context *ctx,
+		struct trace_probe_log *tpl)
 {
 	struct fetch_insn *code = *pcode;
 	unsigned long param;
@@ -1056,13 +1062,13 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 
 	switch (arg[0]) {
 	case '$':
-		ret = parse_probe_vars(arg, type, pcode, end, ctx);
+		ret = parse_probe_vars(arg, type, pcode, end, ctx, tpl);
 		break;
 
 	case '%':	/* named register */
 		if (ctx->flags & (TPARG_FL_TEVENT | TPARG_FL_FPROBE)) {
 			/* eprobe and fprobe do not handle registers */
-			trace_probe_log_err(ctx->offset, BAD_VAR);
+			trace_probe_log_err(tpl, ctx->offset, BAD_VAR);
 			break;
 		}
 		ret = regs_query_register_offset(arg + 1);
@@ -1071,14 +1077,14 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 			code->param = (unsigned int)ret;
 			ret = 0;
 		} else
-			trace_probe_log_err(ctx->offset, BAD_REG_NAME);
+			trace_probe_log_err(tpl, ctx->offset, BAD_REG_NAME);
 		break;
 
 	case '@':	/* memory, file-offset or symbol */
 		if (isdigit(arg[1])) {
 			ret = kstrtoul(arg + 1, 0, &param);
 			if (ret) {
-				trace_probe_log_err(ctx->offset, BAD_MEM_ADDR);
+				trace_probe_log_err(tpl, ctx->offset, BAD_MEM_ADDR);
 				break;
 			}
 			/* load address */
@@ -1087,12 +1093,12 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 		} else if (arg[1] == '+') {
 			/* kprobes don't support file offsets */
 			if (ctx->flags & TPARG_FL_KERNEL) {
-				trace_probe_log_err(ctx->offset, FILE_ON_KPROBE);
+				trace_probe_log_err(tpl, ctx->offset, FILE_ON_KPROBE);
 				return -EINVAL;
 			}
 			ret = kstrtol(arg + 2, 0, &offset);
 			if (ret) {
-				trace_probe_log_err(ctx->offset, BAD_FILE_OFFS);
+				trace_probe_log_err(tpl, ctx->offset, BAD_FILE_OFFS);
 				break;
 			}
 
@@ -1101,7 +1107,7 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 		} else {
 			/* uprobes don't support symbols */
 			if (!(ctx->flags & TPARG_FL_KERNEL)) {
-				trace_probe_log_err(ctx->offset, SYM_ON_UPROBE);
+				trace_probe_log_err(tpl, ctx->offset, SYM_ON_UPROBE);
 				return -EINVAL;
 			}
 			/* Preserve symbol for updating */
@@ -1110,7 +1116,7 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 			if (!code->data)
 				return -ENOMEM;
 			if (++code == end) {
-				trace_probe_log_err(ctx->offset, TOO_MANY_OPS);
+				trace_probe_log_err(tpl, ctx->offset, TOO_MANY_OPS);
 				return -EINVAL;
 			}
 			code->op = FETCH_OP_IMM;
@@ -1118,7 +1124,7 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 		}
 		/* These are fetching from memory */
 		if (++code == end) {
-			trace_probe_log_err(ctx->offset, TOO_MANY_OPS);
+			trace_probe_log_err(tpl, ctx->offset, TOO_MANY_OPS);
 			return -EINVAL;
 		}
 		*pcode = code;
@@ -1137,20 +1143,20 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 			arg++;	/* Skip '+', because kstrtol() rejects it. */
 		tmp = strchr(arg, '(');
 		if (!tmp) {
-			trace_probe_log_err(ctx->offset, DEREF_NEED_BRACE);
+			trace_probe_log_err(tpl, ctx->offset, DEREF_NEED_BRACE);
 			return -EINVAL;
 		}
 		*tmp = '\0';
 		ret = kstrtol(arg, 0, &offset);
 		if (ret) {
-			trace_probe_log_err(ctx->offset, BAD_DEREF_OFFS);
+			trace_probe_log_err(tpl, ctx->offset, BAD_DEREF_OFFS);
 			break;
 		}
 		ctx->offset += (tmp + 1 - arg) + (arg[0] != '-' ? 1 : 0);
 		arg = tmp + 1;
 		tmp = strrchr(arg, ')');
 		if (!tmp) {
-			trace_probe_log_err(ctx->offset + strlen(arg),
+			trace_probe_log_err(tpl, ctx->offset + strlen(arg),
 					    DEREF_OPEN_BRACE);
 			return -EINVAL;
 		} else {
@@ -1158,17 +1164,17 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 			int cur_offs = ctx->offset;
 
 			*tmp = '\0';
-			ret = parse_probe_arg(arg, t2, &code, end, ctx);
+			ret = parse_probe_arg(arg, t2, &code, end, ctx, tpl);
 			if (ret)
 				break;
 			ctx->offset = cur_offs;
 			if (code->op == FETCH_OP_COMM ||
 			    code->op == FETCH_OP_DATA) {
-				trace_probe_log_err(ctx->offset, COMM_CANT_DEREF);
+				trace_probe_log_err(tpl, ctx->offset, COMM_CANT_DEREF);
 				return -EINVAL;
 			}
 			if (++code == end) {
-				trace_probe_log_err(ctx->offset, TOO_MANY_OPS);
+				trace_probe_log_err(tpl, ctx->offset, TOO_MANY_OPS);
 				return -EINVAL;
 			}
 			*pcode = code;
@@ -1181,7 +1187,7 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 		break;
 	case '\\':	/* Immediate value */
 		if (arg[1] == '"') {	/* Immediate string */
-			ret = __parse_imm_string(arg + 2, &tmp, ctx->offset + 2);
+			ret = __parse_imm_string(arg + 2, &tmp, ctx->offset + 2, tpl);
 			if (ret)
 				break;
 			code->op = FETCH_OP_DATA;
@@ -1189,7 +1195,7 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 		} else {
 			ret = str_to_immediate(arg + 1, &code->immediate);
 			if (ret)
-				trace_probe_log_err(ctx->offset + 1, BAD_IMM);
+				trace_probe_log_err(tpl, ctx->offset + 1, BAD_IMM);
 			else
 				code->op = FETCH_OP_IMM;
 		}
@@ -1198,16 +1204,16 @@ parse_probe_arg(char *arg, const struct fetch_type *type,
 		if (isalpha(arg[0]) || arg[0] == '_') {	/* BTF variable */
 			if (!tparg_is_function_entry(ctx->flags) &&
 			    !tparg_is_function_return(ctx->flags)) {
-				trace_probe_log_err(ctx->offset, NOSUP_BTFARG);
+				trace_probe_log_err(tpl, ctx->offset, NOSUP_BTFARG);
 				return -EINVAL;
 			}
-			ret = parse_btf_arg(arg, pcode, end, ctx);
+			ret = parse_btf_arg(arg, pcode, end, ctx, tpl);
 			break;
 		}
 	}
 	if (!ret && code->op == FETCH_OP_NOP) {
 		/* Parsed, but do not find fetch method */
-		trace_probe_log_err(ctx->offset, BAD_FETCH_ARG);
+		trace_probe_log_err(tpl, ctx->offset, BAD_FETCH_ARG);
 		ret = -EINVAL;
 	}
 	return ret;
@@ -1250,7 +1256,8 @@ static int __parse_bitfield_probe_arg(const char *bf,
 
 /* Split type part from @arg and return it. */
 static char *parse_probe_arg_type(char *arg, struct probe_arg *parg,
-				  struct traceprobe_parse_context *ctx)
+				  struct traceprobe_parse_context *ctx,
+				  struct trace_probe_log *tpl)
 {
 	char *t = NULL, *t2, *t3;
 	int offs;
@@ -1265,22 +1272,22 @@ static char *parse_probe_arg_type(char *arg, struct probe_arg *parg,
 			if (!t3) {
 				offs = t2 + strlen(t2) - arg;
 
-				trace_probe_log_err(ctx->offset + offs,
+				trace_probe_log_err(tpl, ctx->offset + offs,
 						    ARRAY_NO_CLOSE);
 				return ERR_PTR(-EINVAL);
 			} else if (t3[1] != '\0') {
-				trace_probe_log_err(ctx->offset + t3 + 1 - arg,
+				trace_probe_log_err(tpl, ctx->offset + t3 + 1 - arg,
 						    BAD_ARRAY_SUFFIX);
 				return ERR_PTR(-EINVAL);
 			}
 			*t3 = '\0';
 			if (kstrtouint(t2, 0, &parg->count) || !parg->count) {
-				trace_probe_log_err(ctx->offset + t2 - arg,
+				trace_probe_log_err(tpl, ctx->offset + t2 - arg,
 						    BAD_ARRAY_NUM);
 				return ERR_PTR(-EINVAL);
 			}
 			if (parg->count > MAX_ARRAY_LEN) {
-				trace_probe_log_err(ctx->offset + t2 - arg,
+				trace_probe_log_err(tpl, ctx->offset + t2 - arg,
 						    ARRAY_TOO_BIG);
 				return ERR_PTR(-EINVAL);
 			}
@@ -1297,7 +1304,7 @@ static char *parse_probe_arg_type(char *arg, struct probe_arg *parg,
 	     strncmp(arg, "\\\"", 2) == 0)) {
 		/* The type of $comm must be "string", and not an array type. */
 		if (parg->count || (t && strcmp(t, "string"))) {
-			trace_probe_log_err(ctx->offset + offs, NEED_STRING_TYPE);
+			trace_probe_log_err(tpl, ctx->offset + offs, NEED_STRING_TYPE);
 			return ERR_PTR(-EINVAL);
 		}
 		parg->type = find_fetch_type("string", ctx->flags);
@@ -1305,7 +1312,7 @@ static char *parse_probe_arg_type(char *arg, struct probe_arg *parg,
 		parg->type = find_fetch_type(t, ctx->flags);
 
 	if (!parg->type) {
-		trace_probe_log_err(ctx->offset + offs, BAD_TYPE);
+		trace_probe_log_err(tpl, ctx->offset + offs, BAD_TYPE);
 		return ERR_PTR(-EINVAL);
 	}
 
@@ -1317,7 +1324,8 @@ static int finalize_fetch_insn(struct fetch_insn *code,
 			       struct probe_arg *parg,
 			       char *type,
 			       int type_offset,
-			       struct traceprobe_parse_context *ctx)
+			       struct traceprobe_parse_context *ctx,
+				   struct trace_probe_log *tpl)
 {
 	struct fetch_insn *scode;
 	int ret;
@@ -1329,7 +1337,7 @@ static int finalize_fetch_insn(struct fetch_insn *code,
 			if (code->op != FETCH_OP_REG && code->op != FETCH_OP_STACK &&
 			    code->op != FETCH_OP_RETVAL && code->op != FETCH_OP_ARG &&
 			    code->op != FETCH_OP_DEREF && code->op != FETCH_OP_TP_ARG) {
-				trace_probe_log_err(ctx->offset + type_offset,
+				trace_probe_log_err(tpl, ctx->offset + type_offset,
 						    BAD_SYMSTRING);
 				return -EINVAL;
 			}
@@ -1337,7 +1345,7 @@ static int finalize_fetch_insn(struct fetch_insn *code,
 			if (code->op != FETCH_OP_DEREF && code->op != FETCH_OP_UDEREF &&
 			    code->op != FETCH_OP_IMM && code->op != FETCH_OP_COMM &&
 			    code->op != FETCH_OP_DATA && code->op != FETCH_OP_TP_ARG) {
-				trace_probe_log_err(ctx->offset + type_offset,
+				trace_probe_log_err(tpl, ctx->offset + type_offset,
 						    BAD_STRING);
 				return -EINVAL;
 			}
@@ -1357,7 +1365,7 @@ static int finalize_fetch_insn(struct fetch_insn *code,
 			 */
 			code++;
 			if (code->op != FETCH_OP_NOP) {
-				trace_probe_log_err(ctx->offset, TOO_MANY_OPS);
+				trace_probe_log_err(tpl, ctx->offset, TOO_MANY_OPS);
 				return -EINVAL;
 			}
 		}
@@ -1381,7 +1389,7 @@ static int finalize_fetch_insn(struct fetch_insn *code,
 	} else {
 		code++;
 		if (code->op != FETCH_OP_NOP) {
-			trace_probe_log_err(ctx->offset, TOO_MANY_OPS);
+			trace_probe_log_err(tpl, ctx->offset, TOO_MANY_OPS);
 			return -E2BIG;
 		}
 		code->op = FETCH_OP_ST_RAW;
@@ -1396,13 +1404,13 @@ static int finalize_fetch_insn(struct fetch_insn *code,
 		/* Bitfield needs a special fetch_insn. */
 		ret = __parse_bitfield_probe_arg(type, parg->type, &code);
 		if (ret) {
-			trace_probe_log_err(ctx->offset + type_offset, BAD_BITFIELD);
+			trace_probe_log_err(tpl, ctx->offset + type_offset, BAD_BITFIELD);
 			return ret;
 		}
 	} else if (IS_ENABLED(CONFIG_PROBE_EVENTS_BTF_ARGS) &&
 		   ctx->last_type) {
 		/* If user not specified the type, try parsing BTF bitfield. */
-		ret = parse_btf_bitfield(&code, ctx);
+		ret = parse_btf_bitfield(&code, ctx, tpl);
 		if (ret)
 			return ret;
 	}
@@ -1412,12 +1420,12 @@ static int finalize_fetch_insn(struct fetch_insn *code,
 		if (scode->op != FETCH_OP_ST_MEM &&
 		    scode->op != FETCH_OP_ST_STRING &&
 		    scode->op != FETCH_OP_ST_USTRING) {
-			trace_probe_log_err(ctx->offset + type_offset, BAD_STRING);
+			trace_probe_log_err(tpl, ctx->offset + type_offset, BAD_STRING);
 			return -EINVAL;
 		}
 		code++;
 		if (code->op != FETCH_OP_NOP) {
-			trace_probe_log_err(ctx->offset, TOO_MANY_OPS);
+			trace_probe_log_err(tpl, ctx->offset, TOO_MANY_OPS);
 			return -E2BIG;
 		}
 		code->op = FETCH_OP_LP_ARRAY;
@@ -1434,7 +1442,8 @@ static int finalize_fetch_insn(struct fetch_insn *code,
 /* String length checking wrapper */
 static int traceprobe_parse_probe_arg_body(const char *argv, ssize_t *size,
 					   struct probe_arg *parg,
-					   struct traceprobe_parse_context *ctx)
+					   struct traceprobe_parse_context *ctx,
+					   struct trace_probe_log *tpl)
 {
 	struct fetch_insn *code, *tmp = NULL;
 	char *type, *arg __free(kfree) = NULL;
@@ -1442,10 +1451,10 @@ static int traceprobe_parse_probe_arg_body(const char *argv, ssize_t *size,
 
 	len = strlen(argv);
 	if (len > MAX_ARGSTR_LEN) {
-		trace_probe_log_err(ctx->offset, ARG_TOO_LONG);
+		trace_probe_log_err(tpl, ctx->offset, ARG_TOO_LONG);
 		return -E2BIG;
 	} else if (len == 0) {
-		trace_probe_log_err(ctx->offset, NO_ARG_BODY);
+		trace_probe_log_err(tpl, ctx->offset, NO_ARG_BODY);
 		return -EINVAL;
 	}
 
@@ -1457,7 +1466,7 @@ static int traceprobe_parse_probe_arg_body(const char *argv, ssize_t *size,
 	if (!parg->comm)
 		return -ENOMEM;
 
-	type = parse_probe_arg_type(arg, parg, ctx);
+	type = parse_probe_arg_type(arg, parg, ctx, tpl);
 	if (IS_ERR(type))
 		return PTR_ERR(type);
 
@@ -1468,7 +1477,7 @@ static int traceprobe_parse_probe_arg_body(const char *argv, ssize_t *size,
 
 	ctx->last_type = NULL;
 	ret = parse_probe_arg(arg, parg->type, &code, &code[FETCH_INSN_MAX - 1],
-			      ctx);
+			      ctx, tpl);
 	if (ret < 0)
 		goto fail;
 
@@ -1478,7 +1487,7 @@ static int traceprobe_parse_probe_arg_body(const char *argv, ssize_t *size,
 		if (!type) {
 			parg->type = find_fetch_type_from_btf_type(ctx);
 		} else if (strstr(type, "string")) {
-			ret = check_prepare_btf_string_fetch(type, &code, ctx);
+			ret = check_prepare_btf_string_fetch(type, &code, ctx, tpl);
 			if (ret)
 				goto fail;
 		}
@@ -1497,7 +1506,7 @@ static int traceprobe_parse_probe_arg_body(const char *argv, ssize_t *size,
 			 parg->count);
 	}
 
-	ret = finalize_fetch_insn(code, parg, type, type ? type - arg : 0, ctx);
+	ret = finalize_fetch_insn(code, parg, type, type ? type - arg : 0, ctx, tpl);
 	if (ret < 0)
 		goto fail;
 
@@ -1568,7 +1577,8 @@ static char *generate_probe_arg_name(const char *arg, int idx)
 }
 
 int traceprobe_parse_probe_arg(struct trace_probe *tp, int i, const char *arg,
-			       struct traceprobe_parse_context *ctx)
+			       struct traceprobe_parse_context *ctx,
+				   struct trace_probe_log *tpl)
 {
 	struct probe_arg *parg = &tp->args[i];
 	const char *body;
@@ -1577,10 +1587,10 @@ int traceprobe_parse_probe_arg(struct trace_probe *tp, int i, const char *arg,
 	body = strchr(arg, '=');
 	if (body) {
 		if (body - arg > MAX_ARG_NAME_LEN) {
-			trace_probe_log_err(0, ARG_NAME_TOO_LONG);
+			trace_probe_log_err(tpl, 0, ARG_NAME_TOO_LONG);
 			return -EINVAL;
 		} else if (body == arg) {
-			trace_probe_log_err(0, NO_ARG_NAME);
+			trace_probe_log_err(tpl, 0, NO_ARG_NAME);
 			return -EINVAL;
 		}
 		parg->name = kmemdup_nul(arg, body - arg, GFP_KERNEL);
@@ -1593,16 +1603,16 @@ int traceprobe_parse_probe_arg(struct trace_probe *tp, int i, const char *arg,
 		return -ENOMEM;
 
 	if (!is_good_name(parg->name)) {
-		trace_probe_log_err(0, BAD_ARG_NAME);
+		trace_probe_log_err(tpl, 0, BAD_ARG_NAME);
 		return -EINVAL;
 	}
 	if (traceprobe_conflict_field_name(parg->name, tp->args, i)) {
-		trace_probe_log_err(0, USED_ARG_NAME);
+		trace_probe_log_err(tpl, 0, USED_ARG_NAME);
 		return -EINVAL;
 	}
 	ctx->offset = body - arg;
 	/* Parse fetch argument */
-	return traceprobe_parse_probe_arg_body(body, &tp->size, parg, ctx);
+	return traceprobe_parse_probe_arg_body(body, &tp->size, parg, ctx, tpl);
 }
 
 void traceprobe_free_probe_arg(struct probe_arg *arg)
@@ -1622,17 +1632,17 @@ void traceprobe_free_probe_arg(struct probe_arg *arg)
 }
 
 static int argv_has_var_arg(int argc, const char *argv[], int *args_idx,
-			    struct traceprobe_parse_context *ctx)
+			    struct traceprobe_parse_context *ctx, struct trace_probe_log *tpl)
 {
 	int i, found = 0;
 
 	for (i = 0; i < argc; i++)
 		if (str_has_prefix(argv[i], "$arg")) {
-			trace_probe_log_set_index(i + 2);
+			trace_probe_log_set_index(tpl, i + 2);
 
 			if (!tparg_is_function_entry(ctx->flags) &&
 			    !tparg_is_function_return(ctx->flags)) {
-				trace_probe_log_err(0, NOFENTRY_ARGS);
+				trace_probe_log_err(tpl, 0, NOFENTRY_ARGS);
 				return -EINVAL;
 			}
 
@@ -1642,12 +1652,12 @@ static int argv_has_var_arg(int argc, const char *argv[], int *args_idx,
 			}
 
 			if (argv[i][4] != '*') {
-				trace_probe_log_err(0, BAD_VAR);
+				trace_probe_log_err(tpl, 0, BAD_VAR);
 				return -EINVAL;
 			}
 
 			if (*args_idx >= 0 && *args_idx < argc) {
-				trace_probe_log_err(0, DOUBLE_ARGS);
+				trace_probe_log_err(tpl, 0, DOUBLE_ARGS);
 				return -EINVAL;
 			}
 			found = 1;
@@ -1659,23 +1669,24 @@ static int argv_has_var_arg(int argc, const char *argv[], int *args_idx,
 
 static int sprint_nth_btf_arg(int idx, const char *type,
 			      char *buf, int bufsize,
-			      struct traceprobe_parse_context *ctx)
+			      struct traceprobe_parse_context *ctx,
+				  struct trace_probe_log *tpl)
 {
 	const char *name;
 	int ret;
 
 	if (idx >= ctx->nr_params) {
-		trace_probe_log_err(0, NO_BTFARG);
+		trace_probe_log_err(tpl, 0, NO_BTFARG);
 		return -ENOENT;
 	}
 	name = btf_name_by_offset(ctx->btf, ctx->params[idx].name_off);
 	if (!name) {
-		trace_probe_log_err(0, NO_BTF_ENTRY);
+		trace_probe_log_err(tpl, 0, NO_BTF_ENTRY);
 		return -ENOENT;
 	}
 	ret = snprintf(buf, bufsize, "%s%s", name, type);
 	if (ret >= bufsize) {
-		trace_probe_log_err(0, ARGS_2LONG);
+		trace_probe_log_err(tpl, 0, ARGS_2LONG);
 		return -E2BIG;
 	}
 	return ret;
@@ -1684,13 +1695,14 @@ static int sprint_nth_btf_arg(int idx, const char *type,
 /* Return new_argv which must be freed after use */
 const char **traceprobe_expand_meta_args(int argc, const char *argv[],
 					 int *new_argc, char *buf, int bufsize,
-					 struct traceprobe_parse_context *ctx)
+					 struct traceprobe_parse_context *ctx,
+					 struct trace_probe_log *tpl)
 {
 	const struct btf_param *params = NULL;
 	int i, j, n, used, ret, args_idx = -1;
 	const char **new_argv __free(kfree) = NULL;
 
-	ret = argv_has_var_arg(argc, argv, &args_idx, ctx);
+	ret = argv_has_var_arg(argc, argv, &args_idx, ctx, tpl);
 	if (ret < 0)
 		return ERR_PTR(ret);
 
@@ -1703,7 +1715,7 @@ const char **traceprobe_expand_meta_args(int argc, const char *argv[],
 	if (ret < 0 || ctx->nr_params == 0) {
 		if (args_idx != -1) {
 			/* $arg* requires BTF info */
-			trace_probe_log_err(0, NOSUP_BTFARG);
+			trace_probe_log_err(tpl, 0, NOSUP_BTFARG);
 			return (const char **)params;
 		}
 		*new_argc = argc;
@@ -1721,11 +1733,11 @@ const char **traceprobe_expand_meta_args(int argc, const char *argv[],
 
 	used = 0;
 	for (i = 0, j = 0; i < argc; i++) {
-		trace_probe_log_set_index(i + 2);
+		trace_probe_log_set_index(tpl, i + 2);
 		if (i == args_idx) {
 			for (n = 0; n < ctx->nr_params; n++) {
 				ret = sprint_nth_btf_arg(n, "", buf + used,
-							 bufsize - used, ctx);
+							 bufsize - used, ctx, tpl);
 				if (ret < 0)
 					return ERR_PTR(ret);
 
@@ -1740,12 +1752,12 @@ const char **traceprobe_expand_meta_args(int argc, const char *argv[],
 
 			n = simple_strtoul(argv[i] + 4, &type, 10);
 			if (type && !(*type == ':' || *type == '\0')) {
-				trace_probe_log_err(0, BAD_VAR);
+				trace_probe_log_err(tpl, 0, BAD_VAR);
 				return ERR_PTR(-ENOENT);
 			}
 			/* Note: $argN starts from $arg1 */
 			ret = sprint_nth_btf_arg(n - 1, type, buf + used,
-						 bufsize - used, ctx);
+						 bufsize - used, ctx, tpl);
 			if (ret < 0)
 				return ERR_PTR(ret);
 			new_argv[j++] = buf + used;
diff --git a/kernel/trace/trace_probe.h b/kernel/trace/trace_probe.h
index 854e5668f5ee5ab4e489ca6c88f4260516dc1cbe..158ce3a436aaf5a4da5f81320e69bf321d72f4c3 100644
--- a/kernel/trace/trace_probe.h
+++ b/kernel/trace/trace_probe.h
@@ -422,12 +422,16 @@ struct traceprobe_parse_context {
 	int offset;
 };
 
+struct trace_probe_log;
+
 extern int traceprobe_parse_probe_arg(struct trace_probe *tp, int i,
 				      const char *argv,
-				      struct traceprobe_parse_context *ctx);
+				      struct traceprobe_parse_context *ctx,
+					  struct trace_probe_log *tpl);
 const char **traceprobe_expand_meta_args(int argc, const char *argv[],
 					 int *new_argc, char *buf, int bufsize,
-					 struct traceprobe_parse_context *ctx);
+					 struct traceprobe_parse_context *ctx,
+					 struct trace_probe_log *tpl);
 extern int traceprobe_expand_dentry_args(int argc, const char *argv[], char **buf);
 
 extern int traceprobe_update_arg(struct probe_arg *arg);
@@ -441,7 +445,7 @@ void traceprobe_finish_parse(struct traceprobe_parse_context *ctx);
 
 extern int traceprobe_split_symbol_offset(char *symbol, long *offset);
 int traceprobe_parse_event_name(const char **pevent, const char **pgroup,
-				char *buf, int offset);
+				char *buf, int offset, struct trace_probe_log *tpl);
 
 enum probe_print_type {
 	PROBE_PRINT_NORMAL,
@@ -563,13 +567,12 @@ struct trace_probe_log {
 	int		index;
 };
 
-void trace_probe_log_init(const char *subsystem, int argc, const char **argv);
-void trace_probe_log_set_index(int index);
-void trace_probe_log_clear(void);
-void __trace_probe_log_err(int offset, int err);
+struct trace_probe_log trace_probe_log_create(const char *subsystem, int argc, const char **argv);
+void trace_probe_log_set_index(struct trace_probe_log *tpl, int index);
+void __trace_probe_log_err(struct trace_probe_log *tpl, int offset, int err);
 
-#define trace_probe_log_err(offs, err)	\
-	__trace_probe_log_err(offs, TP_ERR_##err)
+#define trace_probe_log_err(tpl, offs, err)	\
+	__trace_probe_log_err(tpl, offs, TP_ERR_##err)
 
 struct uprobe_dispatch_data {
 	struct trace_uprobe	*tu;
diff --git a/kernel/trace/trace_uprobe.c b/kernel/trace/trace_uprobe.c
index 3386439ec9f674392aeaaca632b0e13ba15248ef..d00b16256f29e820c4ba21fb101b843a99624c6b 100644
--- a/kernel/trace/trace_uprobe.c
+++ b/kernel/trace/trace_uprobe.c
@@ -441,20 +441,21 @@ static bool trace_uprobe_has_same_uprobe(struct trace_uprobe *orig,
 	return false;
 }
 
-static int append_trace_uprobe(struct trace_uprobe *tu, struct trace_uprobe *to)
+static int append_trace_uprobe(struct trace_probe_log *tpl, struct trace_uprobe *tu,
+				struct trace_uprobe *to)
 {
 	int ret;
 
 	ret = trace_probe_compare_arg_type(&tu->tp, &to->tp);
 	if (ret) {
 		/* Note that argument starts index = 2 */
-		trace_probe_log_set_index(ret + 1);
-		trace_probe_log_err(0, DIFF_ARG_TYPE);
+		trace_probe_log_set_index(tpl, ret + 1);
+		trace_probe_log_err(tpl, 0, DIFF_ARG_TYPE);
 		return -EEXIST;
 	}
 	if (trace_uprobe_has_same_uprobe(to, tu)) {
-		trace_probe_log_set_index(0);
-		trace_probe_log_err(0, SAME_PROBE);
+		trace_probe_log_set_index(tpl, 0);
+		trace_probe_log_err(tpl, 0, SAME_PROBE);
 		return -EEXIST;
 	}
 
@@ -493,7 +494,7 @@ static int validate_ref_ctr_offset(struct trace_uprobe *new)
 }
 
 /* Register a trace_uprobe and probe_event */
-static int register_trace_uprobe(struct trace_uprobe *tu)
+static int register_trace_uprobe(struct trace_probe_log *tpl, struct trace_uprobe *tu)
 {
 	struct trace_uprobe *old_tu;
 	int ret;
@@ -509,18 +510,18 @@ static int register_trace_uprobe(struct trace_uprobe *tu)
 				  trace_probe_group_name(&tu->tp));
 	if (old_tu) {
 		if (is_ret_probe(tu) != is_ret_probe(old_tu)) {
-			trace_probe_log_set_index(0);
-			trace_probe_log_err(0, DIFF_PROBE_TYPE);
+			trace_probe_log_set_index(tpl, 0);
+			trace_probe_log_err(tpl, 0, DIFF_PROBE_TYPE);
 			return -EEXIST;
 		}
-		return append_trace_uprobe(tu, old_tu);
+		return append_trace_uprobe(tpl, tu, old_tu);
 	}
 
 	ret = register_uprobe_event(tu);
 	if (ret) {
 		if (ret == -EEXIST) {
-			trace_probe_log_set_index(0);
-			trace_probe_log_err(0, EVENT_EXIST);
+			trace_probe_log_set_index(tpl, 0);
+			trace_probe_log_err(tpl, 0, EVENT_EXIST);
 		} else
 			pr_warn("Failed to register probe event(%d)\n", ret);
 		return ret;
@@ -563,11 +564,11 @@ static int __trace_uprobe_create(int argc, const char **argv)
 	if (argc < 2)
 		return -ECANCELED;
 
-	trace_probe_log_init("trace_uprobe", argc, argv);
+	struct trace_probe_log tpl = trace_probe_log_create("trace_uprobe", argc, argv);
 
 	if (argc - 2 > MAX_TRACE_ARGS) {
-		trace_probe_log_set_index(2);
-		trace_probe_log_err(0, TOO_MANY_ARGS);
+		trace_probe_log_set_index(&tpl, 2);
+		trace_probe_log_err(&tpl, 0, TOO_MANY_ARGS);
 		return -E2BIG;
 	}
 
@@ -588,18 +589,17 @@ static int __trace_uprobe_create(int argc, const char **argv)
 		return -ECANCELED;
 	}
 
-	trace_probe_log_set_index(1);	/* filename is the 2nd argument */
+	trace_probe_log_set_index(&tpl, 1);	/* filename is the 2nd argument */
 
 	*arg++ = '\0';
 	ret = kern_path(filename, LOOKUP_FOLLOW, &path);
 	if (ret) {
-		trace_probe_log_err(0, FILE_NOT_FOUND);
+		trace_probe_log_err(&tpl, 0, FILE_NOT_FOUND);
 		kfree(filename);
-		trace_probe_log_clear();
 		return ret;
 	}
 	if (!d_is_reg(path.dentry)) {
-		trace_probe_log_err(0, NO_REGULAR_FILE);
+		trace_probe_log_err(&tpl, 0, NO_REGULAR_FILE);
 		ret = -EINVAL;
 		goto fail_address_parse;
 	}
@@ -611,12 +611,12 @@ static int __trace_uprobe_create(int argc, const char **argv)
 		if (!rctr_end) {
 			ret = -EINVAL;
 			rctr_end = rctr + strlen(rctr);
-			trace_probe_log_err(rctr_end - filename,
+			trace_probe_log_err(&tpl, rctr_end - filename,
 					    REFCNT_OPEN_BRACE);
 			goto fail_address_parse;
 		} else if (rctr_end[1] != '\0') {
 			ret = -EINVAL;
-			trace_probe_log_err(rctr_end + 1 - filename,
+			trace_probe_log_err(&tpl, rctr_end + 1 - filename,
 					    BAD_REFCNT_SUFFIX);
 			goto fail_address_parse;
 		}
@@ -625,7 +625,7 @@ static int __trace_uprobe_create(int argc, const char **argv)
 		*rctr_end = '\0';
 		ret = kstrtoul(rctr, 0, &ref_ctr_offset);
 		if (ret) {
-			trace_probe_log_err(rctr - filename, BAD_REFCNT);
+			trace_probe_log_err(&tpl, rctr - filename, BAD_REFCNT);
 			goto fail_address_parse;
 		}
 	}
@@ -637,7 +637,7 @@ static int __trace_uprobe_create(int argc, const char **argv)
 			*tmp = '\0';
 			is_return = true;
 		} else {
-			trace_probe_log_err(tmp - filename, BAD_ADDR_SUFFIX);
+			trace_probe_log_err(&tpl, tmp - filename, BAD_ADDR_SUFFIX);
 			ret = -EINVAL;
 			goto fail_address_parse;
 		}
@@ -646,15 +646,15 @@ static int __trace_uprobe_create(int argc, const char **argv)
 	/* Parse uprobe offset. */
 	ret = kstrtoul(arg, 0, &offset);
 	if (ret) {
-		trace_probe_log_err(arg - filename, BAD_UPROBE_OFFS);
+		trace_probe_log_err(&tpl, arg - filename, BAD_UPROBE_OFFS);
 		goto fail_address_parse;
 	}
 
 	/* setup a probe */
-	trace_probe_log_set_index(0);
+	trace_probe_log_set_index(&tpl, 0);
 	if (event) {
 		ret = traceprobe_parse_event_name(&event, &group, gbuf,
-						  event - argv[0]);
+						  event - argv[0], &tpl);
 		if (ret)
 			goto fail_address_parse;
 	}
@@ -699,8 +699,8 @@ static int __trace_uprobe_create(int argc, const char **argv)
 			.flags = (is_return ? TPARG_FL_RETURN : 0) | TPARG_FL_USER,
 		};
 
-		trace_probe_log_set_index(i + 2);
-		ret = traceprobe_parse_probe_arg(&tu->tp, i, argv[i], &ctx);
+		trace_probe_log_set_index(&tpl, i + 2);
+		ret = traceprobe_parse_probe_arg(&tu->tp, i, argv[i], &ctx, &tpl);
 		traceprobe_finish_parse(&ctx);
 		if (ret)
 			goto error;
@@ -711,18 +711,16 @@ static int __trace_uprobe_create(int argc, const char **argv)
 	if (ret < 0)
 		goto error;
 
-	ret = register_trace_uprobe(tu);
+	ret = register_trace_uprobe(&tpl, tu);
 	if (!ret)
 		goto out;
 
 error:
 	free_trace_uprobe(tu);
 out:
-	trace_probe_log_clear();
 	return ret;
 
 fail_address_parse:
-	trace_probe_log_clear();
 	path_put(&path);
 	kfree(filename);
 

---
base-commit: a33b5a08cbbdd7aadff95f40cbb45ab86841679e
change-id: 20250420-fix-trace-probe-log-race-cc89d8e5fb15

Best regards,
-- 
Paul Cacheux <paulcacheux@gmail.com>

