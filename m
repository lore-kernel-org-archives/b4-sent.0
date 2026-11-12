From: Weidong Wang <weidongw@illinois.edu>
Date: Wed, 11 Nov 2026 23:30:25 -0600
Subject: [PATCH] remoteproc: elf_loader: Bound the program header table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-c3-n021-v1-1-17c9151d0245@illinois.edu>
X-B4-Tracking: v=1; b=H4sIAPBO9WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINBNNtbNMzAy1DU3MzC3NDFJNbJINFMCqi4oSk3LrACbFB0L4ReXJmW
 lJpeAtCvV1gIAFv8ZXWsAAAA=
X-Change-ID: 20261111-c3-n021-7607944e28a6
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>
Cc: linux-remoteproc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Zijie Zhao <zijie4@illinois.edu>, 
 Weidong Wang <weidongw@illinois.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794461450; l=3782;
 i=weidongw@illinois.edu; s=20261108; h=from:subject:message-id;
 bh=1+dxp4TSkvo99vpszS33ptcnuh7ZLO8mxAuiCbEJZ2s=;
 b=bVPFLFW4TgQVG01rb6iT1GKoLw3UEMEXZT1PQ1ti01+uV1i5KUnacemlHqoDQKt+eKN/EjRiQ
 AdOjFspT8u7BJPxCdT1GZ+ecwgUOIhE8YRUWHLAIt+jqJQKGZCwSdUX
X-Developer-Key: i=weidongw@illinois.edu; a=ed25519;
 pk=DR2S1xPEa5sELrWPfOpvUphJQ2VHC+MDc/wJavE/ifg=
X-Endpoint-Received: by B4 Relay for weidongw@illinois.edu/20261108 with auth_id=1449
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rproc_elf_sanity_check() checks that e_phoff lies inside the image, but
not that the e_phnum program headers after it do.
rproc_elf_load_segments() then walks all of them, so an image that
declares more program headers than it contains is read past the end of
the firmware buffer. Both fields come from the image.

Commit b32177ead5f8 ("remoteproc: elf_loader: Bound the section header
table") added the same bound for section headers. Do the same for the
program header table.

Found by an AI code review agent (an LLM-based bug-finding tool
developed by Zijie Zhao and the submitter) and confirmed on an
unmodified kernel, without error injection, on x86_64 under QEMU with
KASAN, using an out-of-tree test module that registers a remote
processor with the stock ELF helpers (rproc_elf_sanity_check,
rproc_elf_load_segments, rproc_elf_get_boot_addr) and a da_to_va backed
by a kernel buffer. Booting it with a 120-byte ELF64 image whose header
claims 64 program headers at e_phoff 64 gives

  BUG: KASAN: vmalloc-out-of-bounds in rproc_elf_load_segments+0x4e5/0x6a0
  Read of size 4 at addr ffffc90000035078 by task run/72

i.e. the first byte past the image, in the buffer allocated by
kernel_read_file(). The same image with e_phnum 1 boots cleanly.

With this patch the oversized image is rejected with "Program headers
are out of bounds", and the e_phnum 1 image still boots.

The reproducer, fix and changelog were drafted with AI assistance
(Claude), then reviewed and tested by the submitter.

Fixes: 400e64df6b23 ("remoteproc: add framework for controlling remote processors")
Cc: stable@vger.kernel.org
Cc: Zijie Zhao <zijie4@illinois.edu>
Signed-off-by: Weidong Wang <weidongw@illinois.edu>
---
Tested on v7.4-rc1 (05441d697f7f), x86_64, KASAN, QEMU/KVM, with an
out-of-tree test module that registers a remote processor using the
stock ELF helpers and a da_to_va backed by a kernel buffer. Firmware
is a 120-byte ELF64 image, program headers at e_phoff 64:

               e_phnum 64                      e_phnum 1 (control)
  unpatched    KASAN vmalloc-out-of-bounds     boots
               read in rproc_elf_load_segments,
               first byte past the image
  patched      "Program headers are out of     boots
               bounds", -EINVAL

No KASAN/UBSAN reports on the patched kernel. The code is unchanged in
mainline, linux-next (next-20261111) and rproc-next.

The reproducer is not attached (AI-found issue, see security-bugs.rst)
and can be shared on request.
---
 drivers/remoteproc/remoteproc_elf_loader.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/remoteproc/remoteproc_elf_loader.c b/drivers/remoteproc/remoteproc_elf_loader.c
index da3cddbe7..54e1fd4bd 100644
--- a/drivers/remoteproc/remoteproc_elf_loader.c
+++ b/drivers/remoteproc/remoteproc_elf_loader.c
@@ -46,7 +46,7 @@ int rproc_elf_sanity_check(struct rproc *rproc, const struct firmware *fw)
 	struct elf32_hdr *ehdr;
 	u32 elf_shdr_get_size;
 	u64 phoff, shoff;
-	size_t shend;
+	size_t shend, phend;
 	char class;
 	u16 phnum, shnum, shstrndx;
 
@@ -126,6 +126,13 @@ int rproc_elf_sanity_check(struct rproc *rproc, const struct firmware *fw)
 		return -EINVAL;
 	}
 
+	/* rproc_elf_load_segments() walks all e_phnum program headers */
+	phend = size_add(size_mul(elf_size_of_phdr(class), phnum), phoff);
+	if (phend > fw->size) {
+		dev_err(dev, "Program headers are out of bounds\n");
+		return -EINVAL;
+	}
+
 	dev_dbg(dev, "Firmware is an elf%d file\n",
 		class == ELFCLASS32 ? 32 : 64);
 

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261111-c3-n021-7607944e28a6

Best regards,
--  
Weidong Wang <weidongw@illinois.edu>

