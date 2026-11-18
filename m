From: Matthew Salsamendi <matthewsalsamendi@gmail.com>
Date: Tue, 17 Nov 2026 16:26:17 -0800
Subject: [PATCH v2 0/2] fs/proc: fix PAGEMAP_SCAN walk_end after a buffer
 refill
To: Andrew Morton <akpm@linux-foundation.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 David Hildenbrand <david@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: Chris Down <chris@chrisdown.name>, Vlastimil Babka <vbabka@kernel.org>, 
 Muhammad Usama Anjum <usama.anjum@arm.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, matthewsalsamendi@gmail.com, 
 Jann Horn <jannh@google.com>, Pedro Falcato <pfalcato@suse.de>, 
 linux-fsdevel@vger.kernel.org, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 linux-kselftest@vger.kernel.org
Message-Id: <20261118-pagemap-walk-end-v2-0-94cd92d838b3@gmail.com>
X-Mailer: b4 0.16.0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794961577; l=815;
 i=matthewsalsamendi@gmail.com; s=b4-kernel-20261117;
 h=from:subject:message-id; bh=oowHUtsthVeLQJxBrgRcG222FtO1F1EoKnj3be3MVlU=;
 b=vOdiQvji9DzMpw5/AWv0JtWMBH9LLUYwG0GKe+mhCGAYOG5BguFAO8nhkwu3xBM9Ewb4x3hvD
 qvAWl7sQ2c9A1VbcbIQHPqoqxRFnVe+7OeJICM2ig8hE1sLI2iczHR2
X-Developer-Key: i=matthewsalsamendi@gmail.com; a=ed25519;
 pk=K4Lg4pTU46IL2CPz2Nb/u30nsnWJ38MlR2/Co4n0tto=
X-Endpoint-Received: by B4 Relay for matthewsalsamendi@gmail.com/b4-kernel-20261117 with auth_id=1555
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hey all,

Thanks for the feedback. I agree with the proposed change to the patch.
Apologies for the delayed reply.

You'll find the updated patch and the requested selftest below.

On x86-64, the refill test fails on the unpatched kernel and the
HugeTLB retry test fails on v1. All 121 tests pass on v2.

Matt

v1: https://lore.kernel.org/linux-mm/CAMPWk9NE_epOdOCbs1PGh8OQP4wjTObvjU-1Wopmu7SSNAMXhw@mail.gmail.com/

Matthew Salsamendi (2):
  fs/proc/task_mmu: reset walk_end before each pagemap walk
  selftests/mm: cover PAGEMAP_SCAN refill and HugeTLB retry

 fs/proc/task_mmu.c                         |  1 +
 tools/testing/selftests/mm/pagemap_ioctl.c | 61 +++++++++++++++++++++-
 2 files changed, 61 insertions(+), 1 deletion(-)


base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb

