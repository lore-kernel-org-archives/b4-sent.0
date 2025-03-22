From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Subject: [PATCH v7 0/5] bits: Fixed-type GENMASK_U*() and BIT_U*()
Date: Sat, 22 Mar 2025 18:23:11 +0900
Message-Id: <20250322-fixed-type-genmasks-v7-0-da380ff1c5b9@wanadoo.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAH+B3mcC/23Q0WrDIBTG8VcpXs9g1KNmV32PsQurx0bWxKJZt
 lLy7tONQcdy+cHxxx/vpGCOWMjz4U4yrrHENNehnw7EjXY+I42+bsIZB8a5oSF+oqfL7Yr0jPN
 ky1uhxvcWAIKQaEh9ec3Yzpr68lp3yGmiy5jR/lqScWaYlsD7DrRmWtGeXt6dLZ3HyWY3xmOcF
 7x0Lk2NHGNZUr59d66ywT9JgsFu0iopo73RwjsflObi+GFn61PqQiataYVHRO0jUJGTlAIH705
 W/UfUI7L/OauqSIBB9IBaOD78QbZt+wLVchcAhAEAAA==
X-Change-ID: 20250228-fixed-type-genmasks-8d1a555f34e8
To: Yury Norov <yury.norov@gmail.com>, 
 Lucas De Marchi <lucas.demarchi@intel.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 Jani Nikula <jani.nikula@linux.intel.com>, 
 Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Tvrtko Ursulin <tursulin@ursulin.net>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, intel-gfx@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, Andi Shyti <andi.shyti@linux.intel.com>, 
 David Laight <David.Laight@ACULAB.COM>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Jani Nikula <jani.nikula@intel.com>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4801;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=sN2Lxz4ZIQPFbPUodNuVELEY2d+P3QblePNK77Bui9s=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOn3Glc+/7895IhHkpuNq0JE1MtYNSf28sj60npLDZdpd
 at6Dip0lLIwiHExyIopsiwr5+RW6Cj0Djv01xJmDisTyBAGLk4BmMgFHkaGd2bPS6dlHbRoPSxY
 9fOwiVFZ3MPmbxI3lNP+n/7WdmhyIyPD6XkPMt3Xquy8oXZI70uIjMnvvs3W96oFd16b7hvZJWr
 BAwA=
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce some fixed width variant of the GENMASK() and the BIT()
macros in bits.h. Note that the main goal is not to get the correct
type, but rather to enforce more checks at compile time. For example:

  GENMASK_U16(16, 0)

will raise a build bug.

This series is a continuation of:

  https://lore.kernel.org/intel-xe/20240208074521.577076-1-lucas.demarchi@intel.com

from Lucas De Marchi. Above series is one year old. I really think
that this was a good idea and I do not want this series to die. So I
am volunteering to revive it.

Meanwhile, many changes occurred in bits.h. The most significant
change is that __GENMASK() was moved to the uapi headers. For this
reason, a new GENMASK_TYPE() is introduced instead and the uapi
__GENMASK() is left untouched.

Finally, I do not think it makes sense to expose the fixed width
variants to the asm. The fixed width integers type are a C concept. So
the GENMASK_U*() are only visible to the non-asm code. For asm, the
long and long long variants seems sufficient.

This series does not modify the actual GENMASK(), GENMASK_ULL() and
GENMASK_U128(). A consolidation of the existing genmasks will be
proposed later on in a separate series.

As requested, here are the bloat-o-meter stats:

  $ ./scripts/bloat-o-meter vmlinux_before.o vmlinux_after.o 
  add/remove: 0/0 grow/shrink: 0/0 up/down: 0/0 (0)
  Function                                     old     new   delta
  Total: Before=22723481, After=22723481, chg +0.00%

(done with GCC 12.4.1 on an x86_64 defconfig)

--
2.43.0

---
Changes from v6:

  - Split the series in two: this series leave any existing GENMASK*()
    unmodified. The consolidation will be done in a separate series.

  - Collect some Reviewed-by tag.

  - Address miscellaneous nitpick on the code comments and the line
    wrapping (details in each patch).

  - Link to v6: https://lore.kernel.org/r/20250308-fixed-type-genmasks-v6-0-f59315e73c29@wanadoo.fr

Changes from v5:

  - Update the cover letter message. I was still refering to
    GENMASK_t() instead of GENMASK_TYPE().

  - Add a comment in the cover letter to explain that a common
    GENMASK_TYPE() for C and asm wouldn't allow to generate the u128
    variant.

  - Restore the comment saying that BUILD_BUG_ON() is not available in
    asm code.

  - Add a FIXME message to highlight the absence of the asm GENMASK*()
    unit tests.

  - Use git's histogram diff algorithm

  - Link to v5: https://lore.kernel.org/r/20250306-fixed-type-genmasks-v5-0-b443e9dcba63@wanadoo.fr

Changes from v4:

  - Rebase on https://github.com/norov/linux/tree/bitmap-for-next

  - Rename GENMASK_t() to GENMASK_TYPE()

  - First patch of v4 (the typo fix 'init128' -> 'int128') is removed
    because it was resent separately in:
    https://lore.kernel.org/all/20250305-fix_init128_typo-v1-1-cbe5b8e54e7d@wanadoo.fr

  - Replace the (t)~ULL(0) by type_max(t). This way, GENMASK_TYPE()
    can now be used to generate GENMASK_U128().

  - Get rid of the unsigned int cast for the U8 and U16 variants.

  - Add the BIT_TYPE() helper macro.

  - Link to v4: https://lore.kernel.org/r/20250305-fixed-type-genmasks-v4-0-1873dcdf6723@wanadoo.fr

Changes from v3:

  - Rebase on v6.14-rc5

  - Fix a typo in GENMASK_U128() comment.

  - Split the asm and non-asm definition of 

  - Replace ~0ULL by ~ULL(0)

  - Since v3, __GENMASK() was moved to the uapi and people started
    using directly. Introduce GENMASK_t() instead.

  - Link to v3: https://lore.kernel.org/intel-xe/20240208074521.577076-1-lucas.demarchi@intel.com

Changes from v2:

  - Document both in commit message and code about the strict type
    checking and give examples how it´d break with invalid params.

  - Link to v2: https://lore.kernel.org/intel-xe/20240124050205.3646390-1-lucas.demarchi@intel.com

Link to v1: https://lore.kernel.org/intel-xe/20230509051403.2748545-1-lucas.demarchi@intel.com

---
Lucas De Marchi (3):
      bits: introduce fixed-type BIT_U*()
      drm/i915: Convert REG_GENMASK*() to fixed-width GENMASK_U*()
      test_bits: add tests for GENMASK_U*()

Vincent Mailhol (2):
      bits: introduce fixed-type GENMASK_U*()
      test_bits: add tests for BIT_U*()

 drivers/gpu/drm/i915/i915_reg_defs.h | 108 ++++-------------------------------
 include/linux/bitops.h               |   1 -
 include/linux/bits.h                 |  57 +++++++++++++++++-
 lib/test_bits.c                      |  30 ++++++++++
 4 files changed, 96 insertions(+), 100 deletions(-)
---
base-commit: e3f42c436d7e0cb432935fe3ae275dd8d9b60f71
change-id: 20250228-fixed-type-genmasks-8d1a555f34e8

Best regards,
-- 
Vincent Mailhol <mailhol.vincent@wanadoo.fr>

