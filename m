From: Sadman Fahmid <sadmanf@meta.com>
Subject: [PATCH RESEND 0/2] erofs-utils: lib: fix a short-read hang and an
 fd leak
Date: Tue, 06 Oct 2026 14:04:46 -0400
Message-Id: <20261006-round1-v1-0-f46b13e11de5@meta.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD44xWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwMz3aL80rwUQ93EVAsLC6Mko9S0ZHMloOKCotS0zAqwQdFKQa7Brn4
 uSrG1tQA60fKyYAAAAA==
To: linux-erofs@lists.ozlabs.org
Cc: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>, 
 Sadman Fahmid <sadmanf@meta.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791309888; l=798;
 i=sadmanf@meta.com; s=20261006; h=from:subject:message-id;
 bh=ihRqyFEf6J5Jhk93FINWAiO4vX00jYMrNSYBaSH8Ouo=;
 b=BhYkEGZqjmJDijwONo/ovMhRNfzS30deWzPSSlCYupf4oVBVXQvqMXDNx+v/bViezjeFRthh9
 GdvZLa2FdNiDFRaHZysnnk2WlWsIXqQ02TbtSMB74e/Pbzyv0bLRY9W
X-Developer-Key: i=sadmanf@meta.com; a=ed25519;
 pk=Pc/arXJpm1RPef8qImFuHROn1p3XNX5MWSUxjZWNTa4=
X-Endpoint-Received: by B4 Relay for sadmanf@meta.com/20261006 with auth_id=1125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 makes erofs_io_xcopy() return -EIO instead of spinning forever
when the source hits EOF early (e.g. rebuilding from a truncated
image), and keeps calling copy_file_range() for ranges over 2 GiB.

Patch 2 closes the source fd on two early error paths in
erofs_mkfs_begin_nondirectory().

---
Sadman Fahmid (2):
      erofs-utils: lib: fail instead of hanging on short reads in erofs_io_xcopy()
      erofs-utils: lib: close source fd on early errors in erofs_mkfs_begin_nondirectory()

 lib/inode.c | 14 +++++++++++---
 lib/io.c    | 29 ++++++++++++++++-------------
 2 files changed, 27 insertions(+), 16 deletions(-)
---
base-commit: 1c230a485f25837cb51d6fc79332f30758d9006c
change-id: 20261006-round1-ae8882b2efc7

Best regards,
-- 
Sadman Fahmid <sadmanf@meta.com>

