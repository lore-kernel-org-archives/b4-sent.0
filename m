From: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
Subject: [PATCH 0/3] bits: Split asm and non-asm GENMASK*() and unify
 definitions
Date: Sat, 22 Mar 2025 19:39:35 +0900
Message-Id: <20250322-consolidate-genmask-v1-0-54bfd36c5643@wanadoo.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGeT3mcC/0XOQQ7CIBAF0KsQ1k5EKkq4iumClmklClTApqbp3
 aVtoqvJ/8l/mZkmjBYTVWSmEUebbPAlnA6EtnftewRrSqacccEqzqANPoWnNToj9OidTg+4tIZ
 x3WjTSU7LcojY2WlTb/WeI77eBc97+bcV2WTOJawTA/kz/OAE0py0EKKrzijVeF3xRicsXzhns
 yKNzU4Px/1AFyJ4nDKtl+ULmmqpsdoAAAA=
X-Change-ID: 20250320-consolidate-genmask-6cd02abadf82
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
 Vincent Mailhol <mailhol.vincent@wanadoo.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3685;
 i=mailhol.vincent@wanadoo.fr; h=from:subject:message-id;
 bh=Qc+4m200O/1jv4vK7vlDM7vK6mXjDW3zZ+mFfnBDgOA=;
 b=owGbwMvMwCV2McXO4Xp97WbG02pJDOn3Jl9NXKdnEdn4vPH96b4HmUwbLyhumuzT6cbicqHT9
 9cCjturOkpZGMS4GGTFFFmWlXNyK3QUeocd+msJM4eVCWQIAxenAExk4SxGhtkP9oepFfnmeph0
 b2CPf/87Z7VT1OJJ6TV5n6rl+tNjTBn+cHV8EcsTP2737cupKVah/tLnfdzNf2y/dfnn1WtOBe3
 HmQE=
X-Developer-Key: i=mailhol.vincent@wanadoo.fr; a=openpgp;
 fpr=ED8F700574E67F20E574E8E2AB5FEB886DBB99C2
X-Endpoint-Received: by B4 Relay for mailhol.vincent@wanadoo.fr/default with auth_id=291
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a subset of below series:

  bits: Fixed-type GENMASK_U*() and BIT_U*()
  Link: https://lore.kernel.org/r/20250308-fixed-type-genmasks-v6-0-f59315e73c29@wanadoo.fr

Yury suggested to split the above series in two steps:

  #1 Introduce the new fixed type GENMASK_U*()
  #2 Consolidate the existing GENMASK*()

This new series is the resulting step #2 following the split.

And thus, this series consolidate all the non-asm GENMASK*() so that
they now all depend on GENMASK_TYPE() which was introduced in step #1.

To do so, I had to split the definition of the asm and non-asm
GENMASK(). I think this is controversial. So I initially implemented a
first draft in which both the asm and non-asm version would rely on
the same helper macro, i.e. adding this:

  #define __GENMASK_TYPE(t, w, h, l)		\
  	(((t)~_ULL(0) << (l)) &			\
  	 ((t)~_ULL(0) >> (w - 1 - (h))))

to uapi/bits.h. And then, the different GENMASK()s would look like
this:

  #define __GENMASK(h, l) __GENMASK_TYPE(unsigned long, __BITS_PER_LONG, h, l)

and so on.

I implemented it, and the final result looked quite ugly. Not only do
we need to manually provide the width each time, the biggest concern
is that adding this to the uapi is asking for trouble. Who knows how
people are going to use this? And once it is in the uapi, there is
virtually no way back.

Adding to this, that macro can not even be generalized to u128
integers, whereas after the split, it can.

And so, after implementing both, the asm and non-asm split seems way
more clean and I think this is the best compromise.

Aside from the split, the asm's GENMASK() and GENMASK_ULL() are left
untouched. While there are some strong incentives to also simplify
these as pointed by David Laight in this thread:

  https://lore.kernel.org/all/20250309102312.4ff08576@pumpkin/

this series deliberately limit its scope to the non-asm variants.

Here are the bloat-o-meter stats:

  $ ./scripts/bloat-o-meter vmlinux_before.o vmlinux_after.o 
  add/remove: 0/0 grow/shrink: 4/2 up/down: 5/-4 (1)
  Function                                     old     new   delta
  intel_psr_invalidate                         666     668      +2
  mst_stream_compute_config                   1652    1653      +1
  intel_psr_flush                              977     978      +1
  intel_dp_compute_link_config                1327    1328      +1
  cfg80211_inform_bss_data                    5109    5108      -1
  intel_drrs_activate                          379     376      -3
  Total: Before=22723481, After=22723482, chg +0.00%

(done with GCC 12.4.1 on an x86_64 defconfig)

--
2.43.0

Signed-off-by: Vincent Mailhol <mailhol.vincent@wanadoo.fr>
---
Vincent Mailhol (3):
      bits: split the definition of the asm and non-asm GENMASK*()
      bits: unify the non-asm GENMASK*()
      test_bits: add tests for __GENMASK() and __GENMASK_ULL()

 include/linux/bits.h | 29 ++++++-----------------------
 lib/test_bits.c      | 19 +++++++++++++++++++
 2 files changed, 25 insertions(+), 23 deletions(-)
---
base-commit: e3f42c436d7e0cb432935fe3ae275dd8d9b60f71
change-id: 20250320-consolidate-genmask-6cd02abadf82
prerequisite-change-id: 20250228-fixed-type-genmasks-8d1a555f34e8:v7
prerequisite-patch-id: 572c05165229640db7dd8fe4d53e1a33ee5dd586
prerequisite-patch-id: c16d122a487f83e2866a9a669259db097ef46a70
prerequisite-patch-id: 35f115c0f1b327f1516cfc38b3076e07713df6cd
prerequisite-patch-id: 5fe7058f6ea73b37df75d5c39ad69a4da928058d
prerequisite-patch-id: 82fb628d052ce9f1efac7f3b61eafb2749f95847

Best regards,
-- 
Vincent Mailhol <mailhol.vincent@wanadoo.fr>

