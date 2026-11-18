From: Harrison Crosse <harrison@crosse.dev>
Subject: [PATCH 0/2] mm/gup: fix mlock() and MAP_POPULATE looping on read
 errors
Date: Wed, 18 Nov 2026 16:56:40 -0500
Message-Id: <20261118-mmpop-populate-v1-0-9c561d178d11@crosse.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0ML3dzcgvwCXSAuzUksSdW1SDS2ME1NSzRPNU9TAmoqKEpNy6wAGxg
 dC+EXlyZlpSaXgExRqq0FADAipz5yAAAA
X-Change-ID: 20261118-mmpop-populate-8a385efa7e7f
To: David Hildenbrand <david@kernel.org>, Jason Gunthorpe <jgg@ziepe.ca>, 
 John Hubbard <jhubbard@nvidia.com>, Peter Xu <peterx@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Shuah Khan <shuah@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Josef Bacik <josef@toxicpanda.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Jan Kara <jack@suse.cz>, 
 Harrison Crosse <harrison@crosse.dev>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795039163; l=2455;
 i=harrison@crosse.dev; s=20261117; h=from:subject:message-id;
 bh=/PkZRnZe5tu6LV293Ifp8K0JXLUKyW2KwcahuxQz4ow=;
 b=OSles3yksDQFXG/3q0tQCEMz+u/knBGbhU4exaXmvxAgSt04CoaGw4td44kcwey09njt++Nuc
 HjqbxmMiv9fDRR9KESgxdSjanyuJaf+XCzQHDuSAX5Nsnb69pTt5ZLy
X-Developer-Key: i=harrison@crosse.dev; a=ed25519;
 pk=fwi/XME2YaW/BDBQ76FmKgF9xHZwRb+dxlVCbxuyojo=
X-Endpoint-Received: by B4 Relay for harrison@crosse.dev/20261117 with auth_id=1552
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If every read of a page in a file mapping fails, mmap(MAP_POPULATE) and
mlock() of that mapping retry the read in the kernel until the task gets
a fatal signal. A load from the page gets SIGBUS, and MADV_POPULATE_READ
fails with EFAULT.

Patch 1 makes __mm_populate() pass FOLL_TRIED when retrying the page
whose fault released the mmap_lock, as __get_user_pages_locked() does,
so that a read error ends the loop. mlock() then fails with ENOMEM, and
mmap(MAP_POPULATE) returns the mapping. Patch 2 adds populate_eio, a
selftest that serves such a file over FUSE and fails without patch 1.
The series is based on v7.4-rc3.

The bug was reproduced with the ext4 setup described in patch 1 on
v7.4-rc3 (arm64 and x86_64), Debian 6.12.116 (arm64) and 6.6.162
(x86_64). Under QEMU TCG, populate_eio passes its MADV_POPULATE_READ
check and fails its mmap(MAP_POPULATE) and mlock() checks without
patch 1 on v7.4-rc3 (arm64 and x86_64) and on 6.12.117 (x86_64), and
passes all three checks with patch 1 on v7.4-rc3 on both architectures.

To reproduce, build and run populate_eio from patch 2 as root on a
kernel with CONFIG_FUSE_FS.

The fix was tested only on v7.4-rc3, on arm64 and x86_64 with 4K pages.
On arm64, only populate_eio was run on the patched kernel. Also not
tested: populate_eio in unprivileged user namespaces or on kernels older
than 6.12, the ext4 setup on kernels older than 6.6, and populate_eio
timing out or getting SIGKILL during a call on the patched kernel, where
every call returns at once. The notes in each patch list the other cases
that were not tested.

The analysis and the patches were prepared with the help of an AI coding
assistant (Claude).

Signed-off-by: Harrison Crosse <harrison@crosse.dev>
---
Harrison Crosse (2):
      mm/gup: make mlock() and MAP_POPULATE handle VM_FAULT_RETRY properly
      selftests/mm: add a test for populating a page that cannot be read

 mm/gup.c                                  |  36 ++-
 tools/testing/selftests/mm/Makefile       |   1 +
 tools/testing/selftests/mm/config         |   1 +
 tools/testing/selftests/mm/populate_eio.c | 410 ++++++++++++++++++++++++++++++
 tools/testing/selftests/mm/run_vmtests.sh |   1 +
 5 files changed, 445 insertions(+), 4 deletions(-)
---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261118-mmpop-populate-8a385efa7e7f

Best regards,
--  
Harrison Crosse <harrison@crosse.dev>

