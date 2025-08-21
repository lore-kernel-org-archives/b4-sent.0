From: Simon Schuster <schuster.simon@siemens-energy.com>
Subject: [PATCH 0/2] nios2: Add architecture support for clone3
Date: Thu, 21 Aug 2025 13:27:36 +0200
Message-Id: <20250821-nios2-implement-clone3-v1-0-1bb24017376a@siemens-energy.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKgCp2gC/x3MwQpAQBCA4VfRnE2tETavIgfWYIpZ7UpK3t3m+
 B3+/4HIQThCmz0Q+JIoXhOKPAO3DrowypQMZKgytrCo4iOh7MfGO+uJbvPKJTYzVeTI2NqMkOI
 j8Cz3P+769/0A89WUVmgAAAA=
X-Change-ID: 20250818-nios2-implement-clone3-7f252c20860b
To: Dinh Nguyen <dinguyen@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@redhat.com>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Vlastimil Babka <vbabka@suse.cz>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 Kees Cook <kees@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Simon Schuster <schuster.simon@siemens-energy.com>
X-Mailer: b4 0.14.3-dev-2ce6c
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755775663; l=1662;
 i=schuster.simon@siemens-energy.com; s=20250818; h=from:subject:message-id;
 bh=3jlVObemI8wNIqbrx4GvyEPDpvdLGZ3e4VpPlUqrZvQ=;
 b=EvDLXxPY5S6pbpEC5hc9qqVLOseYDpRYpX2Y6TYKHHZX+LeSi4Q1+g0YK6AAKayY4Ep67AapT
 z5MIMrak0rXAMAqA/7z5o+qoiazxY9e5SyLNyqkwcBCJL6n99MlLudo
X-Developer-Key: i=schuster.simon@siemens-energy.com; a=ed25519;
 pk=PUhOMiSp43aSeRE1H41KApxYOluamBFFiMfKlBjocvo=
X-Endpoint-Received: by B4 Relay for schuster.simon@siemens-energy.com/20250818 with auth_id=495
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the clone3 system call to the nios2
architecture. This addresses the build-time warning "warning: clone3()
entry point is missing, please fix" introduced in 505d66d1abfb9
("clone3: drop __ARCH_WANT_SYS_CLONE3 macro"). The implementation passes
the relevant clone3 tests of kselftest when applied on top of
next-20250815:

	./run_kselftest.sh
	TAP version 13
	1..4
	# selftests: clone3: clone3
	ok 1 selftests: clone3: clone3
	# selftests: clone3: clone3_clear_sighand
	ok 2 selftests: clone3: clone3_clear_sighand
	# selftests: clone3: clone3_set_tid
	ok 3 selftests: clone3: clone3_set_tid
	# selftests: clone3: clone3_cap_checkpoint_restore
	ok 4 selftests: clone3: clone3_cap_checkpoint_restore

The series also includes a small patch to kernel/fork.c that ensures
that clone_flags are passed correctly on architectures where unsigned
long is insufficient to store the u64 clone_flags.

Signed-off-by: Simon Schuster <schuster.simon@siemens-energy.com>
---
Simon Schuster (2):
      copy_process: Handle architectures where sizeof(unsigned long) < sizeof(u64)
      nios2: implement architecture-specific portion of sys_clone3

 arch/nios2/include/asm/syscalls.h |  1 +
 arch/nios2/include/asm/unistd.h   |  2 --
 arch/nios2/kernel/entry.S         |  6 ++++++
 arch/nios2/kernel/syscall_table.c |  1 +
 kernel/fork.c                     | 10 +++++-----
 5 files changed, 13 insertions(+), 7 deletions(-)
---
base-commit: 1357b2649c026b51353c84ddd32bc963e8999603
change-id: 20250818-nios2-implement-clone3-7f252c20860b

Best regards,
-- 
Simon Schuster <schuster.simon@siemens-energy.com>

