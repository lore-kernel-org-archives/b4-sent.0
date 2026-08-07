From: Michalis Niarchos <michael.niarchos@gmail.com>
Subject: [PATCH 0/2] perf kvm: Fix memory leaks
Date: Fri, 07 Aug 2026 17:08:34 +0200
Message-Id: <20260807-perf-kvm-leaks-v1-0-7b5e2f97905a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCwNz3YLUojTd7LJc3ZzUxOxi3bTU5ERLAxOTROOUJCWgpoKi1LTMCrC
 B0bEQfnFpUlZqcgnIFKXaWgBd0meycgAAAA==
X-Change-ID: 20260807-perf-kvm-leaks-feca9044a3db
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michalis Niarchos <michael.niarchos@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786115324; l=8222;
 i=michael.niarchos@gmail.com; s=20260731; h=from:subject:message-id;
 bh=BHA3+Rt/h9hO4k8Qd/Pj/QaxedFkcQ4kEZKMxZwFlwo=;
 b=cs9ivVNTXKa0DsY1EuYkYWzHujm8p/LBdNLlBg8/B+vMxqIH6tUx0nBBZQ5Dxns5391+PEMr8
 w40xHkzj0icBfcA1ufQ9wMM+DaTUUhj+W8pGXyZAmdgIaSjGEYxMSaB
X-Developer-Key: i=michael.niarchos@gmail.com; a=ed25519;
 pk=/LBZRQzfuxTnSaZhgZE8EP7mHr0poyqlKeFssNqkzFE=
X-Endpoint-Received: by B4 Relay for michael.niarchos@gmail.com/20260731 with auth_id=912
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Running ./perf kvm stat report with ASan, revealed some memory leaks:

==206006==ERROR: LeakSanitizer: detected memory leaks

Direct leak of 72 byte(s) in 3 object(s) allocated from:
    #0 0x7ff86bf2bea9 in calloc (/usr/lib/libasan.so.8+0x12bea9) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f42795a0d5 in zalloc ../../lib/zalloc.c:8
    #2 0x55f42782d7f4 in per_vcpu_record /home/mike/git/linux/tools/perf/builtin-kvm.c:929
    #3 0x55f42782dab7 in handle_kvm_event /home/mike/git/linux/tools/perf/builtin-kvm.c:950
    #4 0x55f42782fa80 in process_sample_event /home/mike/git/linux/tools/perf/builtin-kvm.c:1159
    ...
    #14 0x55f42783236c in read_events /home/mike/git/linux/tools/perf/builtin-kvm.c:1591
    #15 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636

Direct leak of 8 byte(s) in 1 object(s) allocated from:
    #0 0x7ff86bf2c0c1 in malloc (/usr/lib/libasan.so.8+0x12c0c1) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f427d78fe5 in thread__get util/thread.c:137
    #2 0x55f427c4f1fc in thread__find_map util/event.c:703
    #3 0x55f427c5001e in machine__resolve util/event.c:819
    #4 0x55f42782f84a in process_sample_event /home/mike/git/linux/tools/perf/builtin-kvm.c:1145
    ...
    #14 0x55f42783236c in read_events /home/mike/git/linux/tools/perf/builtin-kvm.c:1591
    #15 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636

Indirect leak of 256 byte(s) in 1 object(s) allocated from:
    #0 0x7ff86bf2bea9 in calloc (/usr/lib/libasan.so.8+0x12bea9) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f42795a0d5 in zalloc ../../lib/zalloc.c:8
    #2 0x55f427d78857 in thread__new util/thread.c:46
    #3 0x55f427d7c083 in threads__findnew util/threads.c:116
    #4 0x55f427d2957c in __machine__findnew_thread util/machine.c:553
    #5 0x55f427d29734 in machine__findnew_thread util/machine.c:577
    #6 0x55f427d29a07 in machine__process_comm_event util/machine.c:616
    ...
    #16 0x55f42783236c in read_events /home/mike/git/linux/tools/perf/builtin-kvm.c:1591
    #17 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636

Indirect leak of 112 byte(s) in 1 object(s) allocated from:
    #0 0x7ff86bf2bea9 in calloc (/usr/lib/libasan.so.8+0x12bea9) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f42795a0d5 in zalloc ../../lib/zalloc.c:8
    #2 0x55f427d40e37 in maps__new util/maps.c:270
    #3 0x55f427d78718 in thread__init_maps util/thread.c:30
    #4 0x55f427d295d8 in __machine__findnew_thread util/machine.c:563
    #5 0x55f427d29734 in machine__findnew_thread util/machine.c:577
    #6 0x55f427d29a07 in machine__process_comm_event util/machine.c:616
    ...
    #16 0x55f42783236c in read_events /home/mike/git/linux/tools/perf/builtin-kvm.c:1591
    #17 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636

Indirect leak of 48 byte(s) in 1 object(s) allocated from:
    #0 0x7ff86bf2bea9 in calloc (/usr/lib/libasan.so.8+0x12bea9) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f42795a0d5 in zalloc ../../lib/zalloc.c:8
    #2 0x55f427d75f07 in comm__new util/comm.c:194
    #3 0x55f427d78a2f in thread__new util/thread.c:67
    #4 0x55f427d7c083 in threads__findnew util/threads.c:116
    #5 0x55f427d2957c in __machine__findnew_thread util/machine.c:553
    #6 0x55f427d29734 in machine__findnew_thread util/machine.c:577
    #7 0x55f427d29a07 in machine__process_comm_event util/machine.c:616
    ...
    #17 0x55f42783236c in read_events /home/mike/git/linux/tools/perf/builtin-kvm.c:1591
    #18 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636

Indirect leak of 32 byte(s) in 1 object(s) allocated from:
    #0 0x7ff86bf2bea9 in calloc (/usr/lib/libasan.so.8+0x12bea9) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f427d731a1 in nsinfo__alloc util/namespaces.c:146
    #2 0x55f427d73275 in nsinfo__new util/namespaces.c:160
    #3 0x55f427d78ac9 in thread__new util/thread.c:74
    #4 0x55f427d7c083 in threads__findnew util/threads.c:116
    #5 0x55f427d2957c in __machine__findnew_thread util/machine.c:553
    #6 0x55f427d29734 in machine__findnew_thread util/machine.c:577
    #7 0x55f427d29a07 in machine__process_comm_event util/machine.c:616
    ...
    #18 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636
    #19 0x55f427833d77 in kvm_events_report /home/mike/git/linux/tools/perf/builtin-kvm.c:1764

Indirect leak of 24 byte(s) in 1 object(s) allocated from:
    #0 0x7ff86bf2bea9 in calloc (/usr/lib/libasan.so.8+0x12bea9) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f42795a0d5 in zalloc ../../lib/zalloc.c:8
    #2 0x55f42782d7f4 in per_vcpu_record /home/mike/git/linux/tools/perf/builtin-kvm.c:929
    #3 0x55f42782dab7 in handle_kvm_event /home/mike/git/linux/tools/perf/builtin-kvm.c:950
    #4 0x55f42782fa80 in process_sample_event /home/mike/git/linux/tools/perf/builtin-kvm.c:1159
    ...
    #14 0x55f42783236c in read_events /home/mike/git/linux/tools/perf/builtin-kvm.c:1591
    #15 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636

Indirect leak of 8 byte(s) in 1 object(s) allocated from:
    #0 0x7ff86bf2c0c1 in malloc (/usr/lib/libasan.so.8+0x12c0c1) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f427d7540f in comm_str__get util/comm.c:58
    #2 0x55f427d75ec5 in comm_strs__findnew util/comm.c:189
    #3 0x55f427d76056 in comm__override util/comm.c:215
    #4 0x55f427d796d1 in ____thread__set_comm util/thread.c:259
    #5 0x55f427d797c2 in __thread__set_comm util/thread.c:283
    #6 0x55f427d29b7a in machine__process_comm_event util/machine.c:629
    ...
    #16 0x55f42783236c in read_events /home/mike/git/linux/tools/perf/builtin-kvm.c:1591
    #17 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636

Indirect leak of 8 byte(s) in 1 object(s) allocated from:
    #0 0x7ff86bf2c0c1 in malloc (/usr/lib/libasan.so.8+0x12c0c1) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f427d40f8d in maps__get util/maps.c:288
    #2 0x55f427d7875f in thread__init_maps util/thread.c:35
    #3 0x55f427d295d8 in __machine__findnew_thread util/machine.c:563
    #4 0x55f427d29734 in machine__findnew_thread util/machine.c:577
    #5 0x55f427d29a07 in machine__process_comm_event util/machine.c:616
    ...
    #15 0x55f42783236c in read_events /home/mike/git/linux/tools/perf/builtin-kvm.c:1591
    #16 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636

Indirect leak of 8 byte(s) in 1 object(s) allocated from:
    #0 0x7ff86bf2c0c1 in malloc (/usr/lib/libasan.so.8+0x12c0c1) (BuildId: 7f2845989b820f536270e19ec47df085ae89a675)
    #1 0x55f427d731b6 in nsinfo__alloc util/namespaces.c:147
    #2 0x55f427d73275 in nsinfo__new util/namespaces.c:160
    #3 0x55f427d78ac9 in thread__new util/thread.c:74
    #4 0x55f427d7c083 in threads__findnew util/threads.c:116
    #5 0x55f427d2957c in __machine__findnew_thread util/machine.c:553
    #6 0x55f427d29734 in machine__findnew_thread util/machine.c:577
    #7 0x55f427d29a07 in machine__process_comm_event util/machine.c:616
    ...
    #17 0x55f42783236c in read_events /home/mike/git/linux/tools/perf/builtin-kvm.c:1591
    #18 0x55f4278326f8 in kvm_events_report_vcpu /home/mike/git/linux/tools/perf/builtin-kvm.c:1636

SUMMARY: AddressSanitizer: 576 byte(s) leaked in 12 allocation(s).

Signed-off-by: Michalis Niarchos <michael.niarchos@gmail.com>
---
Michalis Niarchos (2):
      perf kvm: Fix memory leak in process_sample_event()
      perf kvm: Fix memory leak in cmd_kvm()

 tools/perf/builtin-kvm.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)
---
base-commit: 7c39d92d52c28686e7ae21eb726dc008fa1b2f0b
change-id: 20260807-perf-kvm-leaks-feca9044a3db

Best regards,
--  
Michalis Niarchos <michael.niarchos@gmail.com>

