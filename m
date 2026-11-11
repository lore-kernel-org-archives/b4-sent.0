From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Wed, 11 Nov 2026 12:17:22 +0700
Subject: [PATCH bpf-next] bpftool: Skip cgroups removed during cgroup tree
 walk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-bpftool-cgroup-tree-enoent-v1-1-f3bfcddb4f3d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MwQqDMBAFf0X23IUmtIL9ldKDxqddKJuwSUUQ/
 71L5zaHmYMqTFDp0R1k2KRKVpdw6Si9R13BMrtTvMY+ODyVpeX84bRa/hZuBjA0QxuHPs7T/Za
 GcQD5oBgW2f/zJ3nHir3R6zx/fkAo23YAAAA=
X-Change-ID: 20261111-bpftool-cgroup-tree-enoent-162db54c9a9e
To: Quentin Monnet <qmo@kernel.org>, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Roman Gushchin <roman.gushchin@linux.dev>, Jakub Kicinski <kuba@kernel.org>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794374255; l=2201;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=Y/aYjOfjUZxTK7rgxNJ6hCWIgCItIsij9g5tASMpxkM=;
 b=1kWJfLctPEBIdLmqLGPzvNudEJ/L0OIEuQm7UsqIAYo3OVHUE01hYq8YHJYsgr8swa+Ss+oE1
 hyRSYIzcE3LC5YTZZBJOJ5T0u/8lHJc1KhEUgpDTMnxGuTHDkC/c1au
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a cgroup is removed after being found by nftw(), open() or
cgroup_has_attached_progs() in do_show_tree_fn() returns ENOENT.
This is treated as a fatal error so the walk stops and the rest of
the tree isn't listed. This is common on systemd hosts as
transient scopes are created and removed all the time.

With "systemd-run --user --scope true" running in a loop, the walk
fails within a few hundred runs:

  Error: can't query bpf programs attached to /sys/fs/cgroup/user.slice/user-1000.slice/user@1000.service/app.slice/run-p126141-i75408.scope: No such file or directory

Treat ENOENT as the cgroup being gone and continue the walk. With
this patch, 2000 runs in a row complete without error.

Link: https://github.com/libbpf/bpftool/issues/159
Fixes: 2058b38371d0 ("bpftool: introduce cgroup tree command")
Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
The ENODEV originally reported in #159 was fixed by 98b303c9bf05
("bpftool: Query only cgroup-related attach types"). This fixes the
ENOENT race that still breaks cgroup tree on bpftool v7.6.0.
---
 tools/bpf/bpftool/cgroup.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/tools/bpf/bpftool/cgroup.c b/tools/bpf/bpftool/cgroup.c
index fee1a260f6d1..be1c9d5a3bd4 100644
--- a/tools/bpf/bpftool/cgroup.c
+++ b/tools/bpf/bpftool/cgroup.c
@@ -463,12 +463,19 @@ static int do_show_tree_fn(const char *fpath, const struct stat *sb,
 
 	cgroup_fd = open(fpath, O_RDONLY);
 	if (cgroup_fd < 0) {
+		/* cgroup may have been removed after nftw() found it */
+		if (errno == ENOENT)
+			return 0;
 		p_err("can't open cgroup %s: %s", fpath, strerror(errno));
 		return SHOW_TREE_FN_ERR;
 	}
 
 	has_attached_progs = cgroup_has_attached_progs(cgroup_fd);
 	if (has_attached_progs < 0) {
+		if (errno == ENOENT) {
+			close(cgroup_fd);
+			return 0;
+		}
 		p_err("can't query bpf programs attached to %s: %s",
 		      fpath, strerror(errno));
 		close(cgroup_fd);

---
base-commit: 0fb18ce8a2e9de830433923cf65838933d615359
change-id: 20261111-bpftool-cgroup-tree-enoent-162db54c9a9e

Best regards,
-- 
Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>

