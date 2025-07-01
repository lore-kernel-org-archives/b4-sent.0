From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 01 Jul 2025 10:56:45 +0200
Subject: [PATCH 4/6] docs: Remove colon from ctltable title in vm.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250701-jag-sysctldoc-v1-4-936912553f58@kernel.org>
References: <20250701-jag-sysctldoc-v1-0-936912553f58@kernel.org>
In-Reply-To: <20250701-jag-sysctldoc-v1-0-936912553f58@kernel.org>
To: Kees Cook <kees@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1326;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=ePs3rKA84il3gm9cXFfVHZ3ucJrNb+nPVHECDo+XbZs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhjouoNu2I0ilCYWLHWWuG47LqYHwLaTWL3g
 OQqm4JJtVO3YokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoY6LqAAoJELqXzVK3
 lkFP7iMMAI3NMJR99dSUgXyOUtmWmrLaFiCA2eWJ02jhi9jyeDG8vcCXeXnRXVtb0tGHTMA6/01
 VoDeAh8fLOsUthbt3PfU7ZBmMfqEDJrF42hyug+KWNqNngAK9YKNsuQOVBluWaHhPzEdpH7DwMG
 B/qNvNttRWVTPsoVFh+tsNguiXU3J6zatmyEoi7zP5ycDkLu8nkL9AvzEaVilfn7R3R3kmGMTym
 IIv1bTqrHXE2mEomvaQ08a5PKPwQBva+ruTEnHxCxfu9TWRHqtwOkkqlsTMbFKykrny9P73idu5
 5o+VXozhMUzwUBfS9I52vZ5gVhI3ezempQe1X2em4K15yWlNdu0EcJhll7EL9XxbtdrUfvVDKq6
 6IJmwZFFGh5dE33oUaWUfw0/fdc5bjwIqKxreW4K+wPp71JHymE3zQ+9qxqA536z7fBJxOXQa7A
 6NI/7JELVvyktBH3O8bWA55sb1fL+wIsAb6cJYUZcMl8VvFCPUuRHPooslppSBftwnb57C6rLu+
 DU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Removing them solves an issue where they were incorrectly considered as
not implemented by the check-sysctl-docs script

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 Documentation/admin-guide/sysctl/vm.rst | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/Documentation/admin-guide/sysctl/vm.rst b/Documentation/admin-guide/sysctl/vm.rst
index 9bef46151d53cd3130a4a14c8a66bfdc3a5561b4..4d71211fdad8d061ccdef57477ce3dca5c78741d 100644
--- a/Documentation/admin-guide/sysctl/vm.rst
+++ b/Documentation/admin-guide/sysctl/vm.rst
@@ -465,8 +465,8 @@ The minimum value is 1 (1/1 -> 100%). The value less than 1 completely
 disables protection of the pages.
 
 
-max_map_count:
-==============
+max_map_count
+=============
 
 This file contains the maximum number of memory map areas a process
 may have. Memory map areas are used as a side-effect of calling
@@ -495,8 +495,8 @@ memory allocations.
 The default value depends on CONFIG_MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT.
 
 
-memory_failure_early_kill:
-==========================
+memory_failure_early_kill
+=========================
 
 Control how to kill processes when uncorrected memory error (typically
 a 2bit error in a memory module) is detected in the background by hardware

-- 
2.47.2

