From: Darren Carreras <carrerasdarren@gmail.com>
Date: Thu, 13 Aug 2026 20:43:18 -0400
Subject: [PATCH bpf-next v6] libbpf: avoid overflow in BTF.ext bounds check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-b4-libbpf-v6-send-20260813-v6-1-56be61c52758@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/z2M0QqCQBBFf0XmuQFTmbRfiR523WtNxCY7JoL47
 60FPR4O56xkSAqjc7FSwqymr5hBDgX1dxdvYA2ZqSorKdtjzb7hp3o/DjwLG2Lgv3Lh1EG6pnb
 SUh6MCYMu3/mF9iJimej6M/b2D/TT/qZt+wBSILptiAAAAA==
X-Change-ID: 20260813-b4-libbpf-v6-send-20260813-ad79e6943a68
To: bpf@vger.kernel.org
Cc: daniel@iogearbox.net, song@kernel.org, yonghong.song@linux.dev, 
 linux-kernel@vger.kernel.org, jolsa@kernel.org, andrii.nakryiko@gmail.com, 
 ast@kernel.org, eddyz87@gmail.com, emil@etsalapatis.com, andrii@kernel.org, 
 memxor@gmail.com, ihor.solodrai@linux.dev, martin.lau@linux.dev
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786668291; l=3262;
 i=carrerasdarren@gmail.com; s=libbpf-b4; h=from:subject:message-id;
 bh=05gmjAYpA6RRbM/SjSaIlc9x2GNDsLxx41K1RESmUG4=;
 b=nxZUJ38gxCIU7W2EYxDCpkEzwMxLgf8WslbqL1i1mnBOf3X04At2e9oHBC/yFhJMnmqqlYNAZ
 HMEMY45vkB+DleZ5s28GUG0YB+pNvyjhvPM3XYIVlofdFdzbhXxW68k
X-Developer-Key: i=carrerasdarren@gmail.com; a=ed25519;
 pk=B0Vb/xevRsgB+/STwMUkNczAQ7nZs/27IiRcds2ikpM=
X-Endpoint-Received: by B4 Relay for carrerasdarren@gmail.com/libbpf-b4 with auth_id=947
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A malformed BTF.ext subsection length in an ELF input can wrap the
pointer addition used by btf_ext_parse_sec_info() on 32-bit builds. The
wrapped pointer passes the bounds check and parsing then reads beyond the
copied BTF.ext data.

Ensure the header fits in the copied data, then validate the subsection
offset and length with subtraction before forming its pointer.

Fixes: ae4ab4b4117d ("btf: expose API to work with raw btf_ext data")
Closes: https://issues.oss-fuzz.com/issues/477315119
Signed-off-by: Darren Carreras <carrerasdarren@gmail.com>
---
Changes in v6:
- Post the patch inline rather than as an attachment.
- Guard hdr_len locally before subtracting it from data_size.
- Clarify that the input is a malformed BTF.ext subsection in an ELF file.

Changes in v5:
- Resend from a clean compose window because Gmail retained a stale rich-text
  copy beside the v4 attachment, producing a duplicated malformed patch body.

Changes in v4:
- Drop the selftest because the malformed length is already rejected by the
  old check on 64-bit CI; the behavioral divergence is specific to 32-bit.
- Correct the Fixes tag to the commit that introduced the pointer-based check.

Changes in v3:
- Remove the nested mbox envelope and mail headers from the Gmail attachment
  so Patchwork's generated mbox applies with git am.

Changes in v2:
- Resend as plain text because Gmail mangled the v1 diff and Patchwork
  reported "Patch is empty."
- Include the authorized DCO Signed-off-by line.
---
 tools/lib/bpf/btf.c | 14 +++++++++-----
 1 file changed, 9 insertions(+), 5 deletions(-)

diff --git a/tools/lib/bpf/btf.c b/tools/lib/bpf/btf.c
index 8417de92d..c78335997 100644
--- a/tools/lib/bpf/btf.c
+++ b/tools/lib/bpf/btf.c
@@ -3364,7 +3364,7 @@ static int btf_ext_parse_sec_info(struct btf_ext *btf_ext,
 {
 	const struct btf_ext_info_sec *sinfo;
 	struct btf_ext_info *ext_info;
-	__u32 info_left, record_size;
+	__u32 data_left, info_left, record_size;
 	size_t sec_cnt = 0;
 	void *info;
 
@@ -3377,16 +3377,20 @@ static int btf_ext_parse_sec_info(struct btf_ext *btf_ext,
 		return -EINVAL;
 	}
 
-	/* The start of the info sec (including the __u32 record_size). */
-	info = btf_ext->data + btf_ext->hdr->hdr_len + ext_sec->off;
-	info_left = ext_sec->len;
+	if (btf_ext->hdr->hdr_len > btf_ext->data_size)
+		return -EINVAL;
 
-	if (btf_ext->data + btf_ext->data_size < info + ext_sec->len) {
+	data_left = btf_ext->data_size - btf_ext->hdr->hdr_len;
+	if (ext_sec->off > data_left || ext_sec->len > data_left - ext_sec->off) {
 		pr_debug("%s section (off:%u len:%u) is beyond the end of the ELF section .BTF.ext\n",
 			 ext_sec->desc, ext_sec->off, ext_sec->len);
 		return -EINVAL;
 	}
 
+	/* The start of the info sec (including the __u32 record_size). */
+	info = btf_ext->data + btf_ext->hdr->hdr_len + ext_sec->off;
+	info_left = ext_sec->len;
+
 	/* At least a record size */
 	if (info_left < sizeof(__u32)) {
 		pr_debug(".BTF.ext %s record size not found\n", ext_sec->desc);

---
base-commit: 4d9551b39aeb5d32beb4d795ce2892e7690a3e93
change-id: 20260813-b4-libbpf-v6-send-20260813-ad79e6943a68

Best regards,
--  
Darren Carreras <carrerasdarren@gmail.com>

