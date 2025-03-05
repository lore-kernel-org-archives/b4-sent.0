From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Subject: [PATCH v4 0/8] bits: Fixed-type GENMASK()/BIT()
Date: Wed, 05 Mar 2025 22:00:12 +0900
Message-Id: <20250305-fixed-type-genmasks-v4-0-1873dcdf6723@wanadoo.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAN1KyGcC/zXMQQ7CIBCF4as0s3YaiiDElfcwLghM24mFNlCNp
 undpQuXX/Lev0GhzFTg2myQ6c2F51ShTg340aWBkEM1SCG1kNJizx8KuH4XwoFSdOVZ0IbOaa3
 7syIL9blkOmZH9f6o7vMccR0zuX9LCSmsMErLrtXGCHPBDqeXd6UNFF32I984rTS1fo6w7z8Wf
 enNqAAAAA==
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
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>, 
 Jani Nikula <jani.nikula@intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3745;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=DLN+KlQnmQSsQfxf/oCgQKDqI8k4yCpvXzYF3V7T1s0=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOknvD5VCdmaRe3Uid8T4GAoniDK32fFflz9jOOTopudD
 /7FuyV1lLIwiHExyIopsiwr5+RW6Cj0Djv01xJmDisTyBAGLk4BmEhjNSPDEePv8//d67Mx7Ipb
 WLRfhenU0tVHXqutn5phvPcdd19MG8N/zzVFnP4hf79tE9vzpbNgvbnwX5FHFZdOnfrX4Vx+Mj6
 bBwA=
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
change is that __GENMASK() was moved to the uapi headers.

In this v4, I introduce one big change: split the definition of the
asm and non-asm GENMASK(). I think this is controversial. Especially,
Yuri commented that he did not want such split. So I initially
implemented a first draft in which both the asm and non-asm version
would rely on the same helper macro, i.e. adding this:

  #define __GENMASK_t(t, w, h, l)			\
  	(((t)~_ULL(0) - ((t)1 << (l)) + 1) &		\
  	 ((t)~_ULL(0) >> (w - 1 - (h))))
    
to uapi/bits.h. And then, the different GENMASK()s would look like
this:

  #define __GENMASK(h, l) __GENMASK_t(unsigned long, __BITS_PER_LONG, h, l)
    
and so on.
    
I implemented it, and the final result looks quite ugly. Not only do
we need to manually provide the width each time, the biggest concern
is that adding this to the uapi is asking for trouble. Who knows how
people are going to use this? And once it is in the uapi, there is
virtually no way back.

Finally, I do not think it makes sense to expose the fixed width
variants to the asm. The fixed width integers type are a C
concept. For asm, the long and long long variants seems sufficient.

And so, after implementing both, the asm and non-asm split seems way
more clean and I think this is the best compromise. Let me know what
you think :)

Changes from v3:

        - Rebase on v6.14-rc5

        - Fix a typo in GENMASK_U128() comment.

        - Split the asm and non-asm definition of 

        - Replace ~0ULL by ~ULL(0)

        - Since v3, __GENMASK() was moved to the uapi and people
          started using directly. Introduce GENMASK_t() instead.

v3: https://lore.kernel.org/intel-xe/20240208074521.577076-1-lucas.demarchi@intel.com

Changes from v2:

	- Document both in commit message and code about the strict type
	  checking and give examples how it´d break with invalid params.

v2: https://lore.kernel.org/intel-xe/20240124050205.3646390-1-lucas.demarchi@intel.com
v1: https://lore.kernel.org/intel-xe/20230509051403.2748545-1-lucas.demarchi@intel.com
--
2.43.0

---
Lucas De Marchi (3):
      bits: introduce fixed-type BIT
      drm/i915: Convert REG_GENMASK* to fixed-width GENMASK_*
      test_bits: add tests for fixed-type genmasks

Vincent Mailhol (4):
      bits: fix typo 'unsigned __init128' -> 'unsigned __int128'
      bits: split the definition of the asm and non-asm GENMASK()
      test_bits: add tests for __GENMASK() and __GENMASK_ULL()
      test_bits: add tests for fixed-type BIT

Yury Norov (1):
      bits: introduce fixed-type genmasks

 drivers/gpu/drm/i915/i915_reg_defs.h | 108 ++++-------------------------------
 include/linux/bitops.h               |   1 -
 include/linux/bits.h                 |  65 +++++++++++++++++----
 lib/test_bits.c                      |  47 +++++++++++++++
 4 files changed, 111 insertions(+), 110 deletions(-)
---
base-commit: 7eb172143d5508b4da468ed59ee857c6e5e01da6
change-id: 20250228-fixed-type-genmasks-8d1a555f34e8

Best regards,
-- 
Vincent Mailhol <mailhol.vincent@wanadoo.fr>

