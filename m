From: Arina Kharlamova <arina.kharlamova@mbzuai.ac.ae>
Date: Tue, 24 Nov 2026 03:58:53 +0400
Subject: [PATCH] slab: fix the kernel-doc of kmalloc_flex() on counter
 overflow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-slab-doc-v1-1-9f14dfce47c8@mbzuai.ac.ae>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM3QpAQBCG4VvRHNva3TbhVuRgfwYjoR2k5N4tD
 p96v+8CxkjIUGcXRDyIaZkTVJ6BH+zco6CQDFrqQiltBE/WibB4ocrKeCtNkLKAlK8ROzq/q6b
 9zbsb0W/vHu77Aa5/koJsAAAA
X-Change-ID: 20261124-slab-doc-1894ca04d006
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Harry Yoo <harry@kernel.org>, 
 Hao Li <hao.li@linux.dev>, Christoph Lameter <cl@gentwo.org>, 
 David Rientjes <rientjes@google.com>, 
 Roman Gushchin <roman.gushchin@linux.dev>
Cc: workflows@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-mm@kvack.org, Arina Kharlamova <arina.kharlamova@mbzuai.ac.ae>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795478335; l=6300;
 i=arina.kharlamova@mbzuai.ac.ae; s=20261123; h=from:subject:message-id;
 bh=5QShQXRZX54gNTgo0Gx3CJ2jzLByJpRHbpnqHOcnA1Q=;
 b=1eSZpwSTpC+3FeEXiCh//wqMlujfe0v75aaKlaNcdfpPcrsBt+RFLknIU+B407OxXm5P23JDj
 87e/QpMtB2lBBq4wxtsV6OJt5sc0ya3E/trBJjv9gwM1F/sPOy9RgXc
X-Developer-Key: i=arina.kharlamova@mbzuai.ac.ae; a=ed25519;
 pk=DzQWwMpUtJvSDuzprqvRdbrC72n4Sq8dW6cq3NRt2Mk=
X-Endpoint-Received: by B4 Relay for arina.kharlamova@mbzuai.ac.ae/20261123 with auth_id=1625
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit fa5c82f4d2bb ("slab.h: disable completely broken overflow handling
in flex allocations") removed the overflows_flex_counter_type() check from
__alloc_flex(), but left the kernel-doc of __alloc_flex() and
kmalloc_flex(), and the text in deprecated.rst, saying that the
allocation fails when COUNT cannot be represented by the __counted_by()
counter.

The code instead allocates COUNT elements and stores COUNT into the
counter, truncated to the counter's type. With a u8 counter,
kmalloc_flex(*p, array, 256) returns a 256-element object whose counter
is 0. With compilers that lack __builtin_counted_by_ref() the counter is
not written at all.

A caller that relies on the documented check and does not bound COUNT
itself gets an object whose __counted_by() size is smaller than the
allocation. Accesses inside the allocation are then reported by
UBSAN_BOUNDS, and readers that loop up to the counter see fewer elements.

Make the documentation describe what the code does, and fix the
Returns: text of overflows_flex_counter_type(), which still describes
the inverted logic that the same commit corrected.

Returning NULL, as the old text described, is not done here. Some
callers allocate one element more than the counter can hold and then set
the counter themselves: ext4_htree_store_dirent() calls kzalloc_flex()
with ent_name->len + 1 elements for a struct whose name_len is a __u8,
so a 255-byte name would then fail with -ENOMEM.

Found while checking a summary of the kmalloc_obj() family against the
v7.0 to v7.4-rc2 text of slab.h with a battery of inputs compiled by
GCC 15.2, with the help of an AI coding assistant (Claude); I reviewed
the analysis and the patch. A KUnit case (not part of this patch) that
calls kmalloc_flex() with a u8 counter and COUNT 256 gets a non-NULL
object with the counter 0 on v7.4-rc2 (UML, GCC 15.2.0); with
UBSAN_BOUNDS, writing element 255 of that object reports "index 255 is
out of range for type 'u32 [*]'". This patch changes comments only;
scripts/kernel-doc -Wall reports the same warnings for slab.h and
overflow.h before and after it.

Fixes: fa5c82f4d2bb ("slab.h: disable completely broken overflow handling in flex allocations")
Signed-off-by: Arina Kharlamova <arina.kharlamova@mbzuai.ac.ae>
---
 Documentation/process/deprecated.rst |  8 ++++----
 include/linux/overflow.h             |  5 +++--
 include/linux/slab.h                 | 15 +++++++++------
 3 files changed, 16 insertions(+), 12 deletions(-)

diff --git a/Documentation/process/deprecated.rst b/Documentation/process/deprecated.rst
index 22a5e62c92ea..f8b7fb6f9629 100644
--- a/Documentation/process/deprecated.rst
+++ b/Documentation/process/deprecated.rst
@@ -405,7 +405,7 @@ become, respectively::
 	__auto_type ptr = kmalloc_obj(struct foo [, gfp] );
 
 The argument gfp is optional, the default value is GFP_KERNEL.
-If `ptr->flex_member` is annotated with __counted_by(), the allocation
-will automatically fail if `count` is larger than the maximum
-representable value that can be stored in the counter member associated
-with `flex_member`.
+If `ptr->flex_member` is annotated with __counted_by(), the counter
+member associated with `flex_member` is set to `count` on compilers that
+support it. `count` is not checked against the type of the counter, so
+the caller must make sure it fits.
diff --git a/include/linux/overflow.h b/include/linux/overflow.h
index d0f04436343e..6ce610dbc12e 100644
--- a/include/linux/overflow.h
+++ b/include/linux/overflow.h
@@ -566,8 +566,9 @@ static __always_inline size_t __must_check size_sub(size_t minuend, size_t subtr
  * @FAM: Member name of the FAM within @TYPE.
  * @COUNT: Value to check against the __counted_by annotated @FAM's counter.
  *
- * Returns: true if @COUNT can be represented in the @FAM's counter. When
- * @FAM is not annotated with __counted_by(), always returns true.
+ * Returns: true if @COUNT cannot be represented in the @FAM's counter.
+ * When @FAM is not annotated with __counted_by(), or the compiler cannot
+ * resolve the counter, @COUNT is checked against size_t.
  */
 #define overflows_flex_counter_type(TYPE, FAM, COUNT)		\
 	(overflows_type(COUNT, typeof_flex_counter(((TYPE *)NULL)->FAM)))
diff --git a/include/linux/slab.h b/include/linux/slab.h
index ad645967a3ee..69fa9066137f 100644
--- a/include/linux/slab.h
+++ b/include/linux/slab.h
@@ -1091,10 +1091,13 @@ void *kmalloc_nolock(size_t size, gfp_t gfp_flags, int node);
  * @FAM: The name of the flexible array member of @TYPE structure.
  * @COUNT: how many @FAM elements to allocate space for.
  *
+ * If @FAM is annotated with __counted_by() and the compiler supports
+ * __builtin_counted_by_ref(), the counter member is set to @COUNT. @COUNT
+ * is not checked against the type of that member: a value it cannot
+ * represent is stored truncated, so the caller must bound @COUNT.
+ *
  * Returns: Newly allocated pointer to @TYPE with @COUNT-many trailing
- * @FAM elements, or NULL on failure or if @COUNT cannot be represented
- * by the member of @TYPE that counts the @FAM elements (annotated via
- * __counted_by()).
+ * @FAM elements, or NULL on failure.
  */
 #define __alloc_flex(KMALLOC, GFP, TYPE, FAM, COUNT)			\
 ({									\
@@ -1137,9 +1140,9 @@ void *kmalloc_nolock(size_t size, gfp_t gfp_flags, int node);
  * @...: optional GFP flags for the allocation (GFP_KERNEL when not specified).
  *
  * Returns: newly allocated pointer to @VAR_OR_TYPE on success, NULL on
- * failure. If @FAM has been annotated with __counted_by(), the allocation
- * will immediately fail if @COUNT is larger than what the type of the
- * struct's counter variable can represent.
+ * failure. If @FAM has been annotated with __counted_by(), the struct's
+ * counter variable is set to @COUNT when the compiler supports it. @COUNT
+ * must fit in the type of that variable; it is not checked.
  */
 #define kmalloc_flex(VAR_OR_TYPE, FAM, COUNT, ...) \
 	__alloc_flex(kmalloc, default_gfp(__VA_ARGS__), typeof(VAR_OR_TYPE), FAM, COUNT)

---
base-commit: 9b95c9eeec894e969d590f45f9b760e88ba92876
change-id: 20261124-slab-doc-1894ca04d006

Best regards,
--  
Arina Kharlamova <arina.kharlamova@mbzuai.ac.ae>

