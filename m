From: Chen Linxuan <chenlinxuan@uniontech.com>
Subject: [PATCH RFC v3 0/8] kernel-hacking: introduce CONFIG_NO_AUTO_INLINE
Date: Tue, 29 Apr 2025 12:06:04 +0800
Message-Id: <20250429-noautoinline-v3-0-4c49f28ea5b5@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACxQEGgC/22OzQ6CMBCEX4X0qiXdpQXqyQTCA3g1HhBXaaKt4
 S8YwrtbG0/G48xkvpmF9dQZ6tkuWlhHk+mNs14k24g1bW1vxM3Fa4YClZCQcuvqcXDG3o0lnpM
 +a1KJkgqZrzw7upo54I7sUBXs5M3W9IPrXmFighAlUEksc5BQlCWWYvPFAwgFEuNco0458Kalz
 9A81nY/Wn9toKaNG/cI4AkD7P+1CbnglOoaM8hUIq6/gHVd37l4dtL+AAAA
X-Change-ID: 20250416-noautoinline-8e9b9e535452
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Yishai Hadas <yishaih@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Shameer Kolothum <shameerali.kolothum.thodi@huawei.com>, 
 Kevin Tian <kevin.tian@intel.com>, 
 Alex Williamson <alex.williamson@redhat.com>, 
 Peter Huewe <peterhuewe@gmx.de>, Jarkko Sakkinen <jarkko@kernel.org>, 
 Masahiro Yamada <masahiroy@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>, 
 Nick Desaulniers <nick.desaulniers+lkml@gmail.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Vlastimil Babka <vbabka@suse.cz>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Brendan Jackman <jackmanb@google.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Zi Yan <ziy@nvidia.com>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Peter Zijlstra <peterz@infradead.org>, 
 "Paul E. McKenney" <paulmck@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Dmitry Vyukov <dvyukov@google.com>, Andrey Konovalov <andreyknvl@gmail.com>, 
 Juergen Gross <jgross@suse.com>, 
 Boris Ostrovsky <boris.ostrovsky@oracle.com>, 
 Thomas Gleixner <tglx@linutronix.de>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, kvm@vger.kernel.org, virtualization@lists.linux.dev, 
 linux-integrity@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 llvm@lists.linux.dev, Winston Wen <wentao@uniontech.com>, 
 kasan-dev@googlegroups.com, xen-devel@lists.xenproject.org, 
 Chen Linxuan <chenlinxuan@uniontech.com>, 
 Changbin Du <changbin.du@intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2639;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=V+YDfvUyGy5qM6nqWNSGKKulp2fwuDLB1gLxIkj/Hno=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoEFAt1A5qQ0LESAzipTR7awHbnQPj78n5atow0
 tiwIctZ69yJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaBBQLQAKCRB2HuYUOZmu
 ixgVD/9iV08f+Vs6eS/LbQDJ7q+zM9yfQ97NvSrbN+MQtFOdOOX/B9DDWjz07bMvwZeoSrnuWD8
 Hp2NCMdUMvn/XAg8tY/cC0FeuznQPAg5DIqOw8e+jaILOgWNROimjgixLuhTr6WiaM0KrcZDHBL
 OCFiXr8cJEoV5nmHDZpwmsRyfhwIkYxKUiqVZvxYPnX5Mq0jdE9cE129yrf++c0rJHV7tiA9m3m
 3Dgfo4EYCqhLMhujPTgQnqrtD260ZB/BDOIDT/4pmvjfuO7SVexQMqaZ6VD9Zv6g3IpgG//tHdW
 YqgmY8n2rOMhJaDXULwLGpK32HY5uEPSykT3U8ytrJs1vPonlNQ+Yl1jBUOMiJd28s6gMWhAfNF
 7DhrCdUVPQITzQ3hp7+hMavCnibw1bsO70Q1Jyoe/HbpVw+jgqinhhqNY/q95Z3kUEjgZ70wbQz
 J4+fpvQceoLTw3aPUBwT4AgmFYItGhMG/oWciNlmNPDr/PkMdez2OuxVUBnKvMvmy4yNtOyF82f
 vhAi9OSPoii6ldf1OcZLCU7qEMXlU9dM1KhX437xOQ4ZbW31J0vPnuqxW9b5BE8+hsNfWWLyt/z
 sTJSwkwcY3PBvFzx6dDyI4Q7JC83rCdQ6Bpw8f+o9IgK2kSIMrG0t4mrxG3OSfZB8NXalFg40yK
 bumZ9NWzca7x0hA==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces a new kernel configuration option NO_AUTO_INLINE,
which can be used to disable the automatic inlining of functions.

This will allow the function tracer to trace more functions
because it only traces functions that the compiler has not inlined.

Previous discussions can be found at

Link: https://lore.kernel.org/all/20181028130945.23581-3-changbin.du@gmail.com/

This patch depends on

  [PATCH] drm/i915/pxp: fix undefined reference to
          `intel_pxp_gsccs_is_ready_for_sessions'

which can be found at

  https://lore.kernel.org/all/20250415090616.2649889-1-jani.nikula@intel.com/

as well as

  [RFC PATCH 5/7] RDMA/hns: initialize db in update_srq_db()

which can be found at

  https://lore.kernel.org/all/FF922C77946229B6+20250411105459.90782-5-chenlinxuan@uniontech.com/

Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
Changes in v3:
- Fix some modpost and objtool warnings
- Try support clang as Bart Van Assche suggested.
- Remove architecture depends as Bart Van Assche suggested.
- Link to v2: https://lore.kernel.org/r/20250416-noautoinline-v2-0-e69a2717530f@uniontech.com

Changes in v2:
- Resend via b4 to correct Message-ID and recipients.
- Update commit message following suggestions from Jarkko Sakkinen 
- Link to v1: https://lore.kernel.org/r/31F42D8141CDD2D0+20250411105142.89296-1-chenlinxuan@uniontech.com

---
Chen Linxuan (4):
      rseq: add __always_inline for rseq_kernel_fields
      kcov: add __always_inline for canonicalize_ip
      x86/xen: add __init for xen_pgd_walk
      lib/Kconfig.debug: introduce CONFIG_NO_AUTO_INLINE

Winston Wen (4):
      nvme: add __always_inline for nvme_pci_npages_prp
      mm: add __always_inline for page_contains_unaccepted
      vfio/virtio: add __always_inline for virtiovf_get_device_config_size
      tpm: add __always_inline for tpm_is_hwrng_enabled

 Makefile                            | 16 ++++++++++++++++
 arch/x86/xen/mmu_pv.c               |  2 +-
 drivers/char/tpm/tpm-chip.c         |  2 +-
 drivers/nvme/host/pci.c             |  2 +-
 drivers/vfio/pci/virtio/legacy_io.c |  2 +-
 kernel/kcov.c                       |  2 +-
 kernel/rseq.c                       |  2 +-
 lib/Kconfig.debug                   | 21 +++++++++++++++++++++
 lib/Makefile                        |  3 +++
 mm/page_alloc.c                     |  2 +-
 10 files changed, 47 insertions(+), 7 deletions(-)
---
base-commit: ca91b9500108d4cf083a635c2e11c884d5dd20ea
change-id: 20250416-noautoinline-8e9b9e535452

Best regards,
-- 
Chen Linxuan <chenlinxuan@uniontech.com>

