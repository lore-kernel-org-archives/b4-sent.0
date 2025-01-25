From: Levi Zim <rsworktech@outlook.com>
Subject: [PATCH 0/7] bpf: Add probe_read_{kernel,user}_dynptr and
 copy_from_user_dynptr
Date: Sat, 25 Jan 2025 16:23:35 +0800
Message-Id: <20250125-bpf_dynptr_probe-v1-0-c3cb121f6951@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIeflGcC/x3MQQqAIBBA0avErBPUFKKrRITWWLNRGSOK6O5Jy
 7f4/4GCTFhgaB5gPKlQihWqbWDZXdxQ0FoNWmorlTbC5zCvd8wHz5mTR+G86bvFWhOUg5plxkD
 Xvxyn9/0AV9yrMmIAAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1609;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=hTYJU8HfjlKdIevLGmzWkOa6/jkRNnZ81llqBTx0oas=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnlJ+h5PE5cEOfd260Q563RihUGWI2X8YoRdatI
 ccWSV2eoLSJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZ5SfoQAKCRBvO5jUL8bJ
 2GAAEACoZmnxJGr8tDW3HqH28VzCoRGdc6e7L7N4W8PmDwpBD+wCdZuaMpTeSq3GxMSVwqyqBdM
 WPSPRj8r9dq7Azm+HWqX5PT4Mu/30JVHteVGRcNOgwoHDl1ks/+QXjffhgwMzeeBrcjVD5AIiOW
 rmAZj0bN0I0lFvz0SL+Luj/3OwG/Ubl2fErsFXqhhXfP05b3+QPeenivg7TlPovmrcQgCX3JDaW
 b0lNHKSxiOIROA0GMEV+2MVgg56nyghMLqdNg2VrSJFlt233sHfAPFxCWuDH9aVJJHFzO7RZikq
 YQEikxvAE8Iv0TqKF4Auu+pCrMf6iTiA+SSsN/Mla2V2Zi+kB6aMiKSFZP1/5eCPGaG2S30jxoj
 wfXvoLvRb8nqrJt3u7YIR8rSh6+WvCbVqQQhnuwV1oifeP1Jp88zwgT7PoI5CAH8R51jCcBOWe0
 YEUYsXGQD0ozA/zEkMwCLfQV6b2ryEQIS1Y7ATn5V3MopC2PWz8RbUs4l1A0rORAr1tXt5Ai73J
 AakLq64RhXZeUOHHEosmVtUJFVuUE6cwJo0Ah/MU6lm4GGUFkRTkRk4dTRjFZmqUvjJagWT1fD0
 cSEdYa4PvELsV2+CJQ8gmrRSs4dgBhqbhAukurJ0psCMWTAOgMprL3QNywIaHzMQ7lZUtRjwlss
 94stLfcRYkT6+Vg==
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

