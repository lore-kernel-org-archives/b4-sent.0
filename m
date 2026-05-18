From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH RFC 0/5] Test readback from fd on hugetlbfs mount
Date: Mon, 18 May 2026 11:17:32 -0700
Message-Id: <20260518-port-hugetlb-selftests-v1-0-d64ba3a785fe@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALxXC2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDUwNj3YL8ohLdjNL01JKcJN3i1Jy0ktTikmJdy6RkM+OklFRTQ0MzJaD
 mgqLUtMwKsMHRSkFuzkqxtbUAtv9QKW0AAAA=
X-Change-ID: 20260503-port-hugetlb-selftests-9bc63bde5116
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Shuah Khan <shuah@kernel.org>, 
 muchun.song@linux.dev, osalvador@suse.de
Cc: linux-mm@kvack.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779128265; l=1923;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=aVAYRCF7fpcH4fE/r8x3fxMBl+z01QeRVwKC6iFuOtI=;
 b=+r7KYrdkoJP5CPg+cUFpdVi0hERhxpSIqRqAicUAgbGChju5O7GgStBPIRKVnYedFhDyJSaQf
 OobXVllVPbZBKb9C324yvDI5HnNpIK9pzvr/lVbJilPV18vGKGdgtlI
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

I'm thinking of consolidating the tests for libhugetlbfs as kernel
selftests, and to start that off, I picked the simplest test:
tests/readback.c

I refactored hugepage-mmap.c to use the kselftest harness, and then used
FIXTURE_VARIANT from the harness to port in testing readback from an fd on
a hugetlbfs mount.

This output shows that the original test behavior was retained for the
memfd part:

  # ./hugepage-mmap
  TAP version 13
  1..1
  # Returned address is 0x7f312f200000
  # First hex is 0
  # First hex is 3020100
  ok 1 Read same data
  # Totals: pass:1 fail:0 xfail:0 xpass:0 skip:0 error:0

  # ./hugepage-mmap
  TAP version 13
  1..1
  # Starting 1 tests from 1 test cases.
  #  RUN           hugepage_mmap.read_write ...
  # hugepage-mmap.c:41:read_write:Returned address is 0x7f19f3a00000
  # hugepage-mmap.c:54:read_write:First hex is 0
  # hugepage-mmap.c:59:read_write:First hex is 3020100
  #            OK  hugepage_mmap.read_write
  ok 1 hugepage_mmap.read_write
  # PASSED: 1 / 1 tests passed.
  # Totals: pass:1 fail:0 xfail:0 xpass:0 skip:0 error:0

Let me know what you think before I genericize the 2M hugepage size to
other sizes!

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (5):
      mm: selftests: Inline check_bytes() function into caller
      mm: selftests: Inline {read,write}_bytes functions
      mm: selftests: Refactor hugepage-mmap to use kselftest harness
      mm: selftests: Update hugepage-mmap to support hugetlbfs mount
      mm: selftests: Port readback test logic from libhugetlbfs

 tools/testing/selftests/mm/hugepage-mmap.c | 143 +++++++++++++++++++++--------
 1 file changed, 105 insertions(+), 38 deletions(-)
---
base-commit: 66edb901bf874d9e0787326ba12d3548b2da8700
change-id: 20260503-port-hugetlb-selftests-9bc63bde5116

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

