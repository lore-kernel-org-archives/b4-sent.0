From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Subject: [PATCH v2 0/2] selftests/bpf: Fix d_path check_mem_access and drop
 CHECK()
Date: Fri, 06 Nov 2026 10:37:07 +0700
Message-Id: <20261106-dpath-memfd-v2-0-1dc0799b4aa6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/03MQQqDMBBA0avIrDslSZtBu/IepYupmZhAo5KIF
 MS7N3Tl8i3+36FIjlLg0eyQZYslzlOFuTQwBJ5GweiqwShDWitCt/AaMEnyDlkstU7ZtrMearF
 k8fH7vz1f1T7PCdeQhc8Pgw5Pk02jRuoMW6L7+0auHxPHz3WYExzHDwzAaAOhAAAA
X-Change-ID: 20261106-dpath-memfd-ae568d05895f
To: Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, Shuah Khan <shuah@kernel.org>
Cc: bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793936228; l=1020;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=oHBYZOmhLKtt3g9DkPVwr2isJO0GLayzgSm6warDTzw=;
 b=QjyMQE8ho5ZRgpHMESZDc79jLl+iy65YXwkJJJNeITymJxj8scp6bNke1eolxQt1dwHL8Uau1
 7/b1HfTiWzOB9/Kn2fU3VXurUzb59ZdKo3rY+5RA5JV3YhBycer2kEO
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 replaces the deprecated CHECK() calls with ASSERT_*().

Patch 2 fixes check_mem_access, which creates a temp file in
/dev/shm that isn't mounted under vmtest.sh in local runs. This
causes mkstemp() to fail with ENOENT. mkstemp() is replaced with
memfd_create() as it gives a shmem-backed file with no mount
needed while still reaching vfs_fallocate.

Changes in v2:
- Added patch 1 converting CHECK() to ASSERT_*() (Andrii)
- Link to v1: https://lore.kernel.org/bpf/20261102-d-path-memfd-v1-1-692a5664b36d@gmail.com/

---
Jonathan Bastari Thamrin (2):
      selftests/bpf: Replace d_path CHECK() with ASSERT_*()
      selftests/bpf: Use memfd_create instead of mkstemp in d_path

 tools/testing/selftests/bpf/prog_tests/d_path.c | 74 +++++++++----------------
 1 file changed, 26 insertions(+), 48 deletions(-)
---
base-commit: 87eddc739d20b466881e4c5cdd2ddf465a5debfd
change-id: 20261106-dpath-memfd-ae568d05895f

Best regards,
-- 
Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>

