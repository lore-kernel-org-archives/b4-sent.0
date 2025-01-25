From: Levi Zim <rsworktech@outlook.com>
Subject: [PATCH bpf-next v2 0/7] bpf: Add probe_read_{kernel,user}_dynptr
 and copy_from_user_dynptr
Date: Sat, 25 Jan 2025 16:29:47 +0800
Message-Id: <20250125-bpf_dynptr_probe-v2-0-c42c87f97afe@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPuglGcC/2WNQQ7CIBREr9L8tZh+CkZdeQ/TNIWCJSqfADZtm
 t5d0rhzOXkzb1ZIJjqT4FqtEM3kkiNfAj9UoMfePwxzQ8nAay5r5IKpYLth8SHHLkRShvVKnBs
 tpbDYQ5mFaKybd+UdSpt5M2doCxldyhSX/WvCnf+08l87IauZbrRCjvZ0kXijT34RPY+a3tBu2
 /YF9/MfKbwAAAA=
X-Change-ID: 20250124-bpf_dynptr_probe-ab483c554f1a
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, 
 John Fastabend <john.fastabend@gmail.com>, KP Singh <kpsingh@kernel.org>, 
 Stanislav Fomichev <sdf@fomichev.me>, Hao Luo <haoluo@google.com>, 
 Jiri Olsa <jolsa@kernel.org>, Matt Bobrowski <mattbobrowski@google.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Mykola Lysenko <mykolal@fb.com>, Shuah Khan <shuah@kernel.org>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Andrii Nakryiko <andrii.nakryiko@gmail.com>, 
 Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1817;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=P5XuJJND0nKhLbsM46EPq1luRqpUiyBNf0HrYROsyE0=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnlKEV+2sHhhlq/K1lAjunTXgA/d6rjPlDg3JGN
 cK3kw69poiJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ5ShFQAKCRBvO5jUL8bJ
 2HMwEADXmP+76DbBZ1IBtrqom4sXAe3aKiLOE3MIMuPQWiQqfaBzvDlhcm+cP3A05rzQ0sxvd+S
 MweuoGiHO51Xsegd0Mck/++847sj46LXAJXboCymenzgCqIYA/GCGLLpBe1OBFNJQCEnwVDcKjL
 t9/sPk6m724f1fNkZepcBuqLQBoJ6+/no7GPo2+lGN4lsU9PYnX7PAmSU0N14iJORNCvjotTK1R
 P7oSHqYpNDiq2iEx7u403QwHsUkO3lyXJA8feoOSFROi9xgCu7wR7OysANs9xZ1tvYY0789vteG
 6XmxZay2c2iRUhxa2qt6PCxaVgZZxIAOCVgLxJr0nYXOKVAZ7V6k1/bUTZ73ZyAoH1ONu582X9O
 DNVgjqLBwZvgOTapoM+ifeWqzB5s2GBYfIRIZQZiz34RayCUP6SCTh5zfzx48X33MIZ7ZtA9Kcy
 1hkKXNwTgyt9NgJFUQ6++BJ38/3RnREvZACz5TgoZ94+u8KQSuubmfK8CIkIoCabslRiDoc86ts
 O8WR3uE7ov+nBf1JXr7xnfjdl6hDnGXiGCBB0YhbAHvd9cvHb1GpaBWu2o/2kA4GgAUlBXwvCla
 htZkOf35wa8+pHPDK9Ybrx9tcmLjbZ7aFzIWdKRlpRv4+8nf/i8IijlBK9FUkBmgkQWgbQ+ycVj
 n3iArCud3OgaGdQ==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduce the dynptr counterpart of the
bpf_probe_read_{kernel,user} helpers and bpf_copy_from_user helper.

These helpers are helpful for reading variable-length data from kernel
memory into dynptr without going through an intermediate buffer.

Link: https://lore.kernel.org/bpf/MEYP282MB2312CFCE5F7712FDE313215AC64D2@MEYP282MB2312.AUSP282.PROD.OUTLOOK.COM/
Suggested-by: Andrii Nakryiko <andrii.nakryiko@gmail.com>
Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
Changes in v2:
- Add missing bpf-next prefix. I forgot it in the initial series. Sorry
  about that.
- Link to v1: https://lore.kernel.org/r/20250125-bpf_dynptr_probe-v1-0-c3cb121f6951@outlook.com

---
Levi Zim (7):
      bpf: Implement bpf_probe_read_kernel_dynptr helper
      bpf: Implement bpf_probe_read_user_dynptr helper
      bpf: Implement bpf_copy_from_user_dynptr helper
      tools headers UAPI: Update tools's copy of bpf.h header
      selftests/bpf: probe_read_kernel_dynptr test
      selftests/bpf: probe_read_user_dynptr test
      selftests/bpf: copy_from_user_dynptr test

 include/linux/bpf.h                                |   3 +
 include/uapi/linux/bpf.h                           |  49 ++++++++++
 kernel/bpf/helpers.c                               |  53 ++++++++++-
 kernel/trace/bpf_trace.c                           |  72 ++++++++++++++
 tools/include/uapi/linux/bpf.h                     |  49 ++++++++++
 tools/testing/selftests/bpf/prog_tests/dynptr.c    |  45 ++++++++-
 tools/testing/selftests/bpf/progs/dynptr_success.c | 106 +++++++++++++++++++++
 7 files changed, 374 insertions(+), 3 deletions(-)
---
base-commit: d0d106a2bd21499901299160744e5fe9f4c83ddb
change-id: 20250124-bpf_dynptr_probe-ab483c554f1a

Best regards,
-- 
Levi Zim <rsworktech@outlook.com>

